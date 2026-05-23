const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {quizScoreReward, BADGE_THRESHOLDS} =
    require("../shared/point_rules");
const {awardBadge} = require("../shared/badge_award");
const {recordTopicProgress} = require("../shared/topic_progress");

/**
 * Firestore Trigger: classes/{cid}/quizzes/{qid}/attempts/{aid}
 *
 * Fires saat submitQuizAttempt Callable selesai menulis attempt doc.
 *
 * Tugas:
 *  1. Race-safe set firstSubmitterUid pada quiz doc.
 *  2. Award point quiz (idempotent via points_log doc id).
 *  3. Update quiz streak cache + cek Straight-A Crusader.
 *  4. Cek Comeback Kid (compare current vs previous attempt).
 *  5. Update topic_progress + cek Flash (kalau attempt.passed).
 *
 * Idempotency: dedup via `users/{uid}/points_log/quiz_attempt:{aid}`. Kalau
 * doc itu sudah exist → seluruh handler skip (cold-start retry safe).
 */
exports.onQuizAttemptCreated = onDocumentCreated(
    {
      document: "classes/{cid}/quizzes/{qid}/attempts/{aid}",
      region: "asia-southeast2",
    },
    async (event) => {
      const db = getFirestore();
      const {cid, qid, aid} = event.params;
      const attempt = event.data && event.data.data();
      if (!attempt) return;

      const studentId = attempt.studentId;
      const score = typeof attempt.score === "number" ? attempt.score : null;
      const passed = Boolean(attempt.passed);
      const attemptNumber = attempt.attemptNumber || 1;
      if (!studentId || score === null) {
        console.warn(`[on_quiz_attempt] skip ${aid}: missing studentId/score`);
        return;
      }

      // Idempotency check.
      const logRef =
          db.doc(`users/${studentId}/points_log/quiz_attempt:${aid}`);
      const logSnap = await logRef.get();
      if (logSnap.exists) {
        console.info(`[on_quiz_attempt] ${aid} already processed, skip`);
        return;
      }

      // (1) Race-safe firstSubmitterUid.
      const quizRef = db.doc(`classes/${cid}/quizzes/${qid}`);
      let quizData = null;
      let isFirstSubmitter = false;
      try {
        const result = await db.runTransaction(async (tx) => {
          const snap = await tx.get(quizRef);
          if (!snap.exists) return {data: null, wonRace: false};
          const cur = snap.data();
          if (cur.firstSubmitterUid) {
            return {
              data: cur,
              wonRace: cur.firstSubmitterUid === studentId,
            };
          }
          tx.update(quizRef, {
            firstSubmitterUid: studentId,
            firstSubmittedAt:
                attempt.completedAt || FieldValue.serverTimestamp(),
          });
          return {
            data: {...cur, firstSubmitterUid: studentId},
            wonRace: true,
          };
        });
        quizData = result.data;
        isFirstSubmitter = result.wonRace;
      } catch (err) {
        console.error(
            `[on_quiz_attempt] firstSubmitter txn failed: ${err.message}`,
        );
        const fallbackSnap = await quizRef.get();
        quizData = fallbackSnap.exists ? fallbackSnap.data() : null;
      }
      if (!quizData) return;

      // (2) Award point.
      const delta = quizScoreReward(score, isFirstSubmitter);
      const userRef = db.doc(`users/${studentId}`);

      const batch = db.batch();
      batch.set(logRef, {
        delta,
        reason: deriveQuizReason(score, isFirstSubmitter),
        refType: "quiz_attempt",
        refId: aid,
        meta: {classId: cid, quizId: qid, score, isFirstSubmitter},
        createdAt: FieldValue.serverTimestamp(),
      });
      if (delta > 0) {
        batch.set(
            userRef,
            {point: FieldValue.increment(delta)},
            {merge: true},
        );
      }
      await batch.commit();

      // (3) Straight-A Crusader.
      try {
        await checkStraightA(
            db, studentId, cid, qid, aid, score, attempt.completedAt,
        );
      } catch (err) {
        console.error(`[on_quiz_attempt] straight_a failed: ${err.message}`);
      }

      // (4) Comeback Kid.
      try {
        await checkComebackKid(
            db, studentId, cid, qid, score, attemptNumber, quizData,
        );
      } catch (err) {
        console.error(`[on_quiz_attempt] comeback_kid failed: ${err.message}`);
      }

      // (5) Flash (only if passed).
      if (passed && quizData.topicId) {
        try {
          const result = await recordTopicProgress(
              studentId, cid, quizData.topicId, "quiz", qid,
          );
          if (result.completed &&
              !result.alreadyClaimed &&
              result.isFirstCompleter) {
            await awardBadge(studentId, "flash", {
              context: {classId: cid, topicId: quizData.topicId},
              dedupKey: `topic:${cid}:${quizData.topicId}`,
            });
          }
        } catch (err) {
          console.error(`[on_quiz_attempt] flash check failed: ${err.message}`);
        }
      }
    },
);

function deriveQuizReason(score, isFirstSubmitter) {
  if (score === 100 && isFirstSubmitter) return "quiz_perfect_first";
  if (score === 100) return "quiz_perfect";
  if (score >= 90) return "quiz_near_perfect";
  return "quiz_score";
}

/**
 * Maintain users/{uid}/quiz_streaks/{cid} dengan last N distinct-quiz attempts,
 * lalu cek Straight-A Crusader (N attempts berurutan, semua score >= minScore).
 *
 * Badge repeatable — setelah award, reset recent[] supaya cycle berikutnya
 * butuh 3 quiz BARU yg ≥90. dedupKey pakai attempt aid (unique per trigger
 * invocation) supaya cold-start retry safe.
 */
async function checkStraightA(db, uid, cid, qid, aid, score, completedAt) {
  const threshold = BADGE_THRESHOLDS.straight_a;
  const streakRef = db.doc(`users/${uid}/quiz_streaks/${cid}`);

  const shouldAward = await db.runTransaction(async (tx) => {
    const snap = await tx.get(streakRef);
    const prev = snap.exists ? (snap.data().recent || []) : [];

    // Insert at front, dedup by qid, keep latest N entries.
    const filtered = prev.filter((r) => r.qid !== qid);
    const next = [
      {qid, score, at: completedAt || null},
      ...filtered,
    ].slice(0, threshold.consecutiveCount);

    tx.set(streakRef, {
      recent: next,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    if (next.length < threshold.consecutiveCount) return false;
    return next.every((r) => (r.score || 0) >= threshold.minScore);
  });

  if (!shouldAward) return;

  const result = await awardBadge(uid, "straight_a", {
    context: {classId: cid, triggerAid: aid},
    dedupKey: `aid:${aid}`,
  });
  // Reset streak supaya next 3 quiz harus fresh.
  if (result.awarded) {
    await streakRef.set({
      recent: [],
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
}

/**
 * Comeback Kid: previous attempt of same quiz score < passingGrade,
 * current attempt >= passingGrade.
 *
 * Repeatable, tapi dedup per (class, quiz) — gak bisa double-earn untuk
 * quiz yg sama walau attempt limit > 2.
 */
async function checkComebackKid(
    db, uid, cid, qid, score, currentAttemptNumber, quizData) {
  if (currentAttemptNumber < 2) return;
  const passing = quizData.passingGrade ?? 0;
  if (score < passing) return;

  const prevSnap = await db
      .collection(`classes/${cid}/quizzes/${qid}/attempts`)
      .where("studentId", "==", uid)
      .where("attemptNumber", "==", currentAttemptNumber - 1)
      .limit(1)
      .get();
  if (prevSnap.empty) return;

  const prev = prevSnap.docs[0].data();
  if ((prev.score || 0) < passing) {
    await awardBadge(uid, "comeback_kid", {
      context: {classId: cid, quizId: qid},
      dedupKey: `quiz:${cid}:${qid}`,
    });
  }
}
