const {Router} = require("express");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {assertTeacherOfClass} = require("../helpers/authorize");

const router = Router();

// Mount: app.use("/classes", topicsRouter)
//   GET    /classes/:cid/topics
//   POST   /classes/:cid/topics
//   PATCH  /classes/:cid/topics/:tid
//   DELETE /classes/:cid/topics/:tid

function mapTopic(doc) {
  const d = doc.data();
  return {
    id: doc.id,
    title: d.title ?? "",
    order: d.order ?? 0,
    createdAt: d.createdAt?.toDate?.().toISOString?.() ?? null,
    createdBy: d.createdBy ?? "",
  };
}

/**
 * GET /api/classes/:cid/topics — list topic.
 * Akses: semua user yang login (siswa juga butuh baca daftar topic).
 */
router.get("/:cid/topics", async (req, res, next) => {
  try {
    const {cid} = req.params;
    const snap = await getFirestore()
        .collection(`classes/${cid}/topics`)
        .orderBy("order")
        .get();
    res.json({topics: snap.docs.map(mapTopic)});
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/classes/:cid/topics — create topic.
 * Server hitung `order` otomatis = jumlah topic existing.
 * Body: { title: string }.
 */
router.post("/:cid/topics", async (req, res, next) => {
  try {
    const {cid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const title = (req.body?.title || "").trim();
    if (!title) {
      return next({status: 400, message: "title is required"});
    }

    const db = getFirestore();
    const topicsRef = db.collection(`classes/${cid}/topics`);
    const countSnap = await topicsRef.count().get();
    const order = countSnap.data().count;

    const doc = await topicsRef.add({
      title,
      order,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.user.uid,
    });
    const created = await doc.get();
    res.status(201).json(mapTopic(created));
  } catch (err) {
    next(err);
  }
});

/**
 * PATCH /api/classes/:cid/topics/:tid — update topic title.
 * Body: { title: string }.
 */
router.patch("/:cid/topics/:tid", async (req, res, next) => {
  try {
    const {cid, tid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const title = (req.body?.title || "").trim();
    if (!title) {
      return next({status: 400, message: "title is required"});
    }

    const ref = getFirestore().doc(`classes/${cid}/topics/${tid}`);
    const snap = await ref.get();
    if (!snap.exists) {
      return next({status: 404, message: "Topic not found"});
    }

    await ref.update({title});
    const updated = await ref.get();
    res.json(mapTopic(updated));
  } catch (err) {
    next(err);
  }
});

/**
 * DELETE /api/classes/:cid/topics/:tid — hapus topic + cascade.
 * Cascade: semua material dengan topicId, semua quiz dengan topicId, dan
 * subcollection quiz (questions, answer_keys, attempts).
 *
 * Catatan skala: Firestore batch limit 500 ops. Kalau topic punya banyak
 * quiz + banyak attempts, perlu chunked batch (TODO kalau perlu).
 */
router.delete("/:cid/topics/:tid", async (req, res, next) => {
  try {
    const {cid, tid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const db = getFirestore();
    const classRef = db.doc(`classes/${cid}`);

    const [materialsSnap, quizzesSnap] = await Promise.all([
      classRef.collection("materials").where("topicId", "==", tid).get(),
      classRef.collection("quizzes").where("topicId", "==", tid).get(),
    ]);

    const batch = db.batch();
    materialsSnap.docs.forEach((d) => batch.delete(d.ref));

    let totalQuestions = 0;
    let totalKeys = 0;
    let totalAttempts = 0;
    for (const quizDoc of quizzesSnap.docs) {
      const quizRef = quizDoc.ref;
      const [qs, ks, ats] = await Promise.all([
        quizRef.collection("questions").get(),
        quizRef.collection("answer_keys").get(),
        quizRef.collection("attempts").get(),
      ]);
      qs.docs.forEach((d) => batch.delete(d.ref));
      ks.docs.forEach((d) => batch.delete(d.ref));
      ats.docs.forEach((d) => batch.delete(d.ref));
      batch.delete(quizRef);
      totalQuestions += qs.size;
      totalKeys += ks.size;
      totalAttempts += ats.size;
    }

    batch.delete(db.doc(`classes/${cid}/topics/${tid}`));
    await batch.commit();

    res.json({
      deleted: true,
      materials: materialsSnap.size,
      quizzes: quizzesSnap.size,
      questions: totalQuestions,
      answerKeys: totalKeys,
      attempts: totalAttempts,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
