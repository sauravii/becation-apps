const {Router} = require("express");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {
  POINT_MATERIAL_COMPLETE,
  BADGE_THRESHOLDS,
  dateKeyJakarta,
  hourLocalJakarta,
} = require("../../shared/point_rules");
const {awardBadge} = require("../../shared/badge_award");
const {recordTopicProgress} = require("../../shared/topic_progress");
const {assertMemberOfClass} = require("../helpers/authorize");

const router = Router();

// Mount: app.use("/classes", materialProgressRouter)
//   POST /classes/:cid/materials/:mid/attachments/:aid/access
//
// Body: (none)
// Flow:
//  1. Verify member of class
//  2. Append aid ke users/{uid}/material_completion/{mid}.attachmentsClicked
//  3. Append log entry ke users/{uid}/material_access (untuk Studyaholic)
//  4. Cek apakah semua attachment di material sudah clicked → material complete
//  5. Kalau just-completed (transition not-complete → complete):
//      a. Award POINT_MATERIAL_COMPLETE (idempotent)
//      b. recordTopicProgress(material) → cek Flash
//  6. Cek Studyaholic (count akses jam >= 22)
//  7. Return progression summary

router.post(
    "/:cid/materials/:mid/attachments/:aid/access",
    async (req, res, next) => {
      try {
        const {cid, mid, aid} = req.params;
        const uid = req.user.uid;
        await assertMemberOfClass(uid, cid);

        const db = getFirestore();
        const now = new Date();

        const [attachSnap, materialSnap] = await Promise.all([
          db.doc(`classes/${cid}/materials/${mid}/attachments/${aid}`).get(),
          db.doc(`classes/${cid}/materials/${mid}`).get(),
        ]);
        if (!attachSnap.exists) {
          return next({status: 404, message: "Attachment not found"});
        }
        if (!materialSnap.exists) {
          return next({status: 404, message: "Material not found"});
        }
        const topicId = materialSnap.data().topicId || null;

        // (2) Update material_completion arrayUnion(aid).
        const completionRef =
            db.doc(`users/${uid}/material_completion/${mid}`);
        await completionRef.set({
          classId: cid,
          materialId: mid,
          topicId,
          attachmentsClicked: FieldValue.arrayUnion(aid),
          lastAccessAt: FieldValue.serverTimestamp(),
        }, {merge: true});

        // (3) Log akses material — untuk Studyaholic count.
        await db.collection(`users/${uid}/material_access`).add({
          materialId: mid,
          classId: cid,
          topicId,
          attachmentId: aid,
          accessedAt: now,
          hourLocal: hourLocalJakarta(now),
          dateKey: dateKeyJakarta(now),
        });

        // (4) Cek apakah material complete sekarang.
        const [completionSnapAfter, attachCountAgg] = await Promise.all([
          completionRef.get(),
          db.collection(`classes/${cid}/materials/${mid}/attachments`)
              .count().get(),
        ]);
        const completionData = completionSnapAfter.data() || {};
        const clicked = new Set(completionData.attachmentsClicked || []);
        const totalAttachments = attachCountAgg.data().count;
        const materialCompleted =
            totalAttachments > 0 && clicked.size >= totalAttachments;

        let pointAwarded = 0;
        const badgesEarned = [];
        const justCompleted =
            materialCompleted && !completionData.completedAt;

        // (5) Kalau baru selesai sekarang:
        if (justCompleted) {
          await completionRef.update({
            completedAt: FieldValue.serverTimestamp(),
          });

          // (5a) Award point (idempotent via points_log id).
          const logRef = db.doc(
              `users/${uid}/points_log/material:${cid}:${mid}`,
          );
          const logSnap = await logRef.get();
          if (!logSnap.exists) {
            const userRef = db.doc(`users/${uid}`);
            const batch = db.batch();
            batch.set(logRef, {
              delta: POINT_MATERIAL_COMPLETE,
              reason: "material_complete",
              refType: "material",
              refId: mid,
              meta: {classId: cid, topicId},
              createdAt: FieldValue.serverTimestamp(),
            });
            batch.set(
                userRef,
                {point: FieldValue.increment(POINT_MATERIAL_COMPLETE)},
                {merge: true},
            );
            await batch.commit();
            pointAwarded += POINT_MATERIAL_COMPLETE;
          }

          // (5b) Topic progress → cek Flash.
          if (topicId) {
            try {
              const tp = await recordTopicProgress(
                  uid, cid, topicId, "material", mid,
              );
              if (tp.completed && !tp.alreadyClaimed && tp.isFirstCompleter) {
                const r = await awardBadge(uid, "flash", {
                  context: {classId: cid, topicId},
                  dedupKey: `topic:${cid}:${topicId}`,
                });
                if (r.awarded) {
                  pointAwarded += r.pointAwarded;
                  badgesEarned.push({
                    badgeId: "flash",
                    count: r.count,
                    pointBonus: r.pointAwarded,
                  });
                }
              }
            } catch (err) {
              console.error(
                  `[material_progress] flash check failed: ${err.message}`,
              );
            }
          }
        }

        // (6) Cek Studyaholic (one-time badge, counts late-night accesses).
        try {
          const sa = await checkStudyaholic(db, uid);
          if (sa.awarded) {
            pointAwarded += sa.pointAwarded;
            badgesEarned.push({
              badgeId: "studyaholic",
              count: sa.count,
              pointBonus: sa.pointAwarded,
            });
          }
        } catch (err) {
          console.error(
              `[material_progress] studyaholic check failed: ${err.message}`,
          );
        }

        res.json({
          materialId: mid,
          attachmentClickedCount: clicked.size,
          totalAttachments,
          materialCompleted,
          justCompleted,
          pointAwarded,
          badgesEarned,
        });
      } catch (err) {
        next(err);
      }
    },
);

/**
 * Studyaholic: 5x akses material dengan hourLocal >= 22.
 * One-time badge. Skip kalau sudah punya (awardBadge handle idempotency).
 */
async function checkStudyaholic(db, uid) {
  const threshold = BADGE_THRESHOLDS.studyaholic;
  const countAgg = await db.collection(`users/${uid}/material_access`)
      .where("hourLocal", ">=", threshold.lateNightHourMin)
      .count()
      .get();
  const total = countAgg.data().count;
  if (total < threshold.requiredCount) {
    return {awarded: false, pointAwarded: 0, count: 0};
  }
  return awardBadge(uid, "studyaholic", {
    context: {lateNightAccessCount: total},
  });
}

module.exports = router;
