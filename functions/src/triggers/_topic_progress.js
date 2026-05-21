const {getFirestore, FieldValue} = require("firebase-admin/firestore");

/**
 * Helper untuk badge The Flash (per-topic completion).
 *
 * Maintain cache di `users/{uid}/topic_progress/{cid}_{tid}` dengan struktur:
 *   {
 *     classId, topicId,
 *     materialsCompleted: [mid, ...],
 *     quizzesPassed: [qid, ...],
 *     firstCompletedAt: Timestamp | null,
 *     updatedAt: Timestamp
 *   }
 *
 * Dipanggil dari:
 *  - on_quiz_attempt trigger (kalau attempt.passed === true)
 *  - material completion endpoint (Phase C)
 *
 * Return:
 *  {
 *    completed: bool,           // topik sudah complete oleh user ini
 *    alreadyClaimed: bool,      // user sudah pernah complete sebelumnya
 *    isFirstCompleter: bool     // user adalah yg pertama di antara semua student
 *  }
 */
async function recordTopicProgress(uid, cid, tid, type, itemId) {
  if (type !== "material" && type !== "quiz") {
    throw new Error(`invalid topic-progress type: ${type}`);
  }

  const db = getFirestore();
  const progressKey = `${cid}_${tid}`;
  const progressRef = db.doc(`users/${uid}/topic_progress/${progressKey}`);
  const field = type === "material" ? "materialsCompleted" : "quizzesPassed";

  // Step 1: arrayUnion update (idempotent — duplicate itemId akan diabaikan).
  await progressRef.set({
    classId: cid,
    topicId: tid,
    [field]: FieldValue.arrayUnion(itemId),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  // Step 2: read back current progress + count totals.
  const [progressSnap, materialsCountAgg, quizzesCountAgg] = await Promise.all([
    progressRef.get(),
    db.collection(`classes/${cid}/materials`)
        .where("topicId", "==", tid).count().get(),
    db.collection(`classes/${cid}/quizzes`)
        .where("topicId", "==", tid).count().get(),
  ]);

  const data = progressSnap.data() || {};
  const matsDone = (data.materialsCompleted || []).length;
  const quizDone = (data.quizzesPassed || []).length;
  const totalMaterials = materialsCountAgg.data().count;
  const totalQuizzes = quizzesCountAgg.data().count;

  // Topic tanpa material & quiz dianggap belum complete (edge case).
  if (totalMaterials === 0 && totalQuizzes === 0) {
    return {completed: false, alreadyClaimed: false, isFirstCompleter: false};
  }
  if (matsDone < totalMaterials || quizDone < totalQuizzes) {
    return {completed: false, alreadyClaimed: false, isFirstCompleter: false};
  }

  // Already complete sebelumnya?
  if (data.firstCompletedAt) {
    return {completed: true, alreadyClaimed: true, isFirstCompleter: false};
  }

  // Mark progress completed.
  await progressRef.update({
    firstCompletedAt: FieldValue.serverTimestamp(),
  });

  // Race-safe claim first-completer di topic doc.
  const topicRef = db.doc(`classes/${cid}/topics/${tid}`);
  const isFirstCompleter = await db.runTransaction(async (tx) => {
    const topicSnap = await tx.get(topicRef);
    if (!topicSnap.exists) return false;
    if (topicSnap.data().firstCompleterUid) return false;
    tx.update(topicRef, {
      firstCompleterUid: uid,
      firstCompletedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });

  return {completed: true, alreadyClaimed: false, isFirstCompleter};
}

module.exports = {recordTopicProgress};
