const {Router} = require("express");
const {getFirestore} = require("firebase-admin/firestore");

const {assertTeacherOfClass} = require("../helpers/authorize");

const router = Router();

// Semua route di sini di-mount under `/classes` di index.js. Mount point lengkap:
//   GET /classes/:classId/quizzes/:quizId/analytics
//   GET /classes/:classId/quizzes/:quizId/analytics/per-question
//   GET /classes/:classId/quizzes/:quizId/attempts

/**
 * Summary statistik attempt: total, avg/min/max score, passRate, distribusi skor.
 */
router.get("/:classId/quizzes/:quizId/analytics", async (req, res, next) => {
  try {
    const {classId, quizId} = req.params;
    await assertTeacherOfClass(req.user.uid, classId);

    const db = getFirestore();
    const quizRef = db.doc(`classes/${classId}/quizzes/${quizId}`);
    const quizSnap = await quizRef.get();
    if (!quizSnap.exists) {
      return next({status: 404, message: "Quiz not found"});
    }
    const passingGrade = quizSnap.data().passingGrade ?? 0;

    const attemptsSnap = await quizRef.collection("attempts").get();
    const total = attemptsSnap.size;

    const emptyBuckets = [
      {bucket: "0-20", count: 0},
      {bucket: "21-40", count: 0},
      {bucket: "41-60", count: 0},
      {bucket: "61-80", count: 0},
      {bucket: "81-100", count: 0},
    ];

    if (total === 0) {
      return res.json({
        totalAttempts: 0,
        avgScore: 0,
        minScore: 0,
        maxScore: 0,
        passRate: 0,
        scoreDistribution: emptyBuckets,
      });
    }

    let sum = 0;
    let min = Infinity;
    let max = -Infinity;
    let passed = 0;
    const buckets = [0, 0, 0, 0, 0];

    attemptsSnap.docs.forEach((doc) => {
      const score = doc.data().score ?? 0;
      sum += score;
      if (score < min) min = score;
      if (score > max) max = score;
      if (score >= passingGrade) passed++;

      if (score <= 20) buckets[0]++;
      else if (score <= 40) buckets[1]++;
      else if (score <= 60) buckets[2]++;
      else if (score <= 80) buckets[3]++;
      else buckets[4]++;
    });

    res.json({
      totalAttempts: total,
      avgScore: Math.round(sum / total),
      minScore: min,
      maxScore: max,
      passRate: passed / total,
      scoreDistribution: emptyBuckets.map((b, i) => ({
        bucket: b.bucket,
        count: buckets[i],
      })),
    });
  } catch (err) {
    next(err);
  }
});

/**
 * Per-question breakdown: correctRate + distribusi pemilihan tiap opsi.
 */
router.get(
    "/:classId/quizzes/:quizId/analytics/per-question",
    async (req, res, next) => {
      try {
        const {classId, quizId} = req.params;
        await assertTeacherOfClass(req.user.uid, classId);

        const db = getFirestore();
        const quizRef = db.doc(`classes/${classId}/quizzes/${quizId}`);

        const [questionsSnap, keysSnap, attemptsSnap] = await Promise.all([
          quizRef.collection("questions").orderBy("order").get(),
          quizRef.collection("answer_keys").get(),
          quizRef.collection("attempts").get(),
        ]);

        if (questionsSnap.empty) {
          return next({status: 404, message: "Quiz has no questions"});
        }

        const keys = {};
        keysSnap.docs.forEach((doc) => {
          keys[doc.id] = doc.data().correctIndices ?? [];
        });

        const totalAttempts = attemptsSnap.size;
        const result = questionsSnap.docs.map((qDoc) => {
          const q = qDoc.data();
          const options = (q.options ?? []).map((o, i) => ({
            index: i,
            text: typeof o === "string" ? o : (o?.text ?? ""),
            count: 0,
            percentage: 0,
          }));
          const correctSet = new Set(keys[qDoc.id] ?? []);
          let correctCount = 0;

          attemptsSnap.docs.forEach((aDoc) => {
            const answer = aDoc.data().answers?.[qDoc.id];
            if (typeof answer === "number" && options[answer]) {
              options[answer].count++;
              if (correctSet.has(answer)) correctCount++;
            }
          });

          options.forEach((o) => {
            o.percentage = totalAttempts > 0 ? o.count / totalAttempts : 0;
          });

          return {
            questionId: qDoc.id,
            question: q.question ?? "",
            correctRate: totalAttempts > 0 ? correctCount / totalAttempts : 0,
            optionDistribution: options,
          };
        });

        res.json({questions: result});
      } catch (err) {
        next(err);
      }
    },
);

/**
 * Paginated attempt list. Query: page (default 1), limit (default 20, max 100),
 * sort ("submittedAt" | "score", default "submittedAt", always desc).
 */
router.get("/:classId/quizzes/:quizId/attempts", async (req, res, next) => {
  try {
    const {classId, quizId} = req.params;
    await assertTeacherOfClass(req.user.uid, classId);

    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(
        100,
        Math.max(1, parseInt(req.query.limit, 10) || 20),
    );
    const sortField = req.query.sort === "score" ? "score" : "completedAt";

    const db = getFirestore();
    const attemptsRef = db
        .collection(`classes/${classId}/quizzes/${quizId}/attempts`);

    const totalSnap = await attemptsRef.count().get();
    const total = totalSnap.data().count;

    const offset = (page - 1) * limit;
    const pageSnap = await attemptsRef
        .orderBy(sortField, "desc")
        .offset(offset)
        .limit(limit)
        .get();

    const items = pageSnap.docs.map((doc) => {
      const d = doc.data();
      return {
        attemptId: doc.id,
        studentId: d.studentId ?? "",
        studentName: d.studentName ?? "",
        score: d.score ?? 0,
        submittedAt: d.completedAt?.toDate?.().toISOString?.() ?? null,
      };
    });

    res.json({
      items,
      hasMore: offset + items.length < total,
      total,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
