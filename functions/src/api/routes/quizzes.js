const {Router} = require("express");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {assertTeacherOfClass} = require("../helpers/authorize");

const router = Router();

// Mount: app.use("/classes", quizzesRouter)
//   POST   /classes/:cid/quizzes                                — create
//   GET    /classes/:cid/quizzes/:qid                           — detail
//   PATCH  /classes/:cid/quizzes/:qid                           — full update (atomic batch)
//   DELETE /classes/:cid/quizzes/:qid                           — cascade
//   GET    /classes/:cid/quizzes/:qid/questions                 — list questions
//   GET    /classes/:cid/quizzes/:qid/answer-keys               — teacher-only
//   GET    /classes/:cid/quizzes/:qid/my-attempts/count         — student-self
//   GET    /classes/:cid/quizzes/:qid/my-attempts/latest        — student-self

function mapQuiz(doc) {
  const d = doc.data();
  return {
    id: doc.id,
    title: d.title ?? "",
    topicId: d.topicId ?? "",
    topicTitle: d.topicTitle ?? "",
    timeLimit: d.timeLimit ?? 0,
    passingGrade: d.passingGrade ?? 0,
    attemptLimit: d.attemptLimit ?? 1,
    showAnswer: d.showAnswer ?? true,
    questionCount: d.questionCount ?? 0,
    createdAt: d.createdAt?.toDate?.().toISOString?.() ?? null,
    createdBy: d.createdBy ?? "",
  };
}

function mapQuestion(doc) {
  const d = doc.data();
  return {
    id: doc.id,
    type: d.type ?? "multiple_choice",
    question: d.question ?? "",
    options: (d.options ?? []).map((o) => ({
      text: typeof o === "string" ? o : (o?.text ?? ""),
    })),
    order: d.order ?? 0,
    createdAt: d.createdAt?.toDate?.().toISOString?.() ?? null,
  };
}

function normalizeOptions(options) {
  if (!Array.isArray(options)) return [];
  return options.map((o) => ({
    text: String(o?.text ?? ""),
    isCorrect: Boolean(o?.isCorrect),
  }));
}

router.post("/:cid/quizzes", async (req, res, next) => {
  try {
    const {cid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const b = req.body || {};
    const title = (b.title || "").trim();
    const topicId = (b.topicId || "").trim();
    if (!title) return next({status: 400, message: "title is required"});
    if (!topicId) return next({status: 400, message: "topicId is required"});
    const questions = Array.isArray(b.questions) ? b.questions : [];
    if (questions.length === 0) {
      return next({status: 400, message: "questions cannot be empty"});
    }

    const db = getFirestore();
    const quizRef = db.collection(`classes/${cid}/quizzes`).doc();

    const batch = db.batch();
    batch.set(quizRef, {
      title,
      topicId,
      topicTitle: b.topicTitle || "",
      timeLimit: Number(b.timeLimit) || 0,
      passingGrade: Number(b.passingGrade) || 0,
      attemptLimit: Number(b.attemptLimit) || 1,
      showAnswer: b.showAnswer !== false,
      questionCount: questions.length,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.user.uid,
    });

    for (let i = 0; i < questions.length; i++) {
      const q = questions[i] || {};
      const opts = normalizeOptions(q.options);
      const qRef = quizRef.collection("questions").doc();
      batch.set(qRef, {
        type: q.type || "multiple_choice",
        question: q.question || "",
        options: opts.map((o) => ({text: o.text})),
        order: i,
        createdAt: FieldValue.serverTimestamp(),
      });
      const correctIndices = [];
      opts.forEach((o, j) => {
        if (o.isCorrect) correctIndices.push(j);
      });
      batch.set(quizRef.collection("answer_keys").doc(qRef.id), {
        correctIndices,
      });
    }

    await batch.commit();
    const created = await quizRef.get();
    res.status(201).json(mapQuiz(created));
  } catch (err) {
    next(err);
  }
});

router.get("/:cid/quizzes/:qid", async (req, res, next) => {
  try {
    const {cid, qid} = req.params;
    const snap =
        await getFirestore().doc(`classes/${cid}/quizzes/${qid}`).get();
    if (!snap.exists) {
      return next({status: 404, message: "Quiz not found"});
    }
    res.json(mapQuiz(snap));
  } catch (err) {
    next(err);
  }
});

router.get("/:cid/quizzes/:qid/questions", async (req, res, next) => {
  try {
    const {cid, qid} = req.params;
    const snap = await getFirestore()
        .collection(`classes/${cid}/quizzes/${qid}/questions`)
        .orderBy("order")
        .get();
    res.json({questions: snap.docs.map(mapQuestion)});
  } catch (err) {
    next(err);
  }
});

router.get("/:cid/quizzes/:qid/answer-keys", async (req, res, next) => {
  try {
    const {cid, qid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const snap = await getFirestore()
        .collection(`classes/${cid}/quizzes/${qid}/answer_keys`)
        .get();
    const keys = {};
    snap.docs.forEach((d) => {
      keys[d.id] = (d.data().correctIndices ?? []).map(Number);
    });
    res.json({answerKeys: keys});
  } catch (err) {
    next(err);
  }
});

router.get(
    "/:cid/quizzes/:qid/my-attempts/count",
    async (req, res, next) => {
      try {
        const {cid, qid} = req.params;
        const snap = await getFirestore()
            .collection(`classes/${cid}/quizzes/${qid}/attempts`)
            .where("studentId", "==", req.user.uid)
            .count()
            .get();
        res.json({count: snap.data().count || 0});
      } catch (err) {
        next(err);
      }
    },
);

router.get(
    "/:cid/quizzes/:qid/my-attempts/latest",
    async (req, res, next) => {
      try {
        const {cid, qid} = req.params;
        const snap = await getFirestore()
            .collection(`classes/${cid}/quizzes/${qid}/attempts`)
            .where("studentId", "==", req.user.uid)
            .get();
        if (snap.empty) return res.json({attempt: null});

        const docs = snap.docs.slice().sort((a, b) => {
          const tA = a.data().submittedAt?.toMillis?.() ?? 0;
          const tB = b.data().submittedAt?.toMillis?.() ?? 0;
          return tB - tA;
        });
        const latest = docs[0].data();
        // Serialize Timestamp fields.
        const out = {...latest};
        if (out.submittedAt?.toDate) {
          out.submittedAt = out.submittedAt.toDate().toISOString();
        }
        if (out.completedAt?.toDate) {
          out.completedAt = out.completedAt.toDate().toISOString();
        }
        res.json({attempt: out});
      } catch (err) {
        next(err);
      }
    },
);

router.patch("/:cid/quizzes/:qid", async (req, res, next) => {
  try {
    const {cid, qid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const b = req.body || {};
    const keptOrdered = Array.isArray(b.keptOrdered) ? b.keptOrdered : [];
    const removedQuestionIds = Array.isArray(b.removedQuestionIds) ?
        b.removedQuestionIds :
        [];
    const newQuestions = Array.isArray(b.newQuestions) ? b.newQuestions : [];

    const db = getFirestore();
    const quizRef = db.doc(`classes/${cid}/quizzes/${qid}`);
    const snap = await quizRef.get();
    if (!snap.exists) {
      return next({status: 404, message: "Quiz not found"});
    }

    const totalCount = keptOrdered.length + newQuestions.length;
    const batch = db.batch();

    batch.update(quizRef, {
      title: b.title || snap.data().title || "",
      topicId: b.topicId || snap.data().topicId || "",
      topicTitle: b.topicTitle ?? snap.data().topicTitle ?? "",
      timeLimit: Number(b.timeLimit) || 0,
      passingGrade: Number(b.passingGrade) || 0,
      attemptLimit: Number(b.attemptLimit) || 1,
      showAnswer: b.showAnswer !== false,
      questionCount: totalCount,
    });

    keptOrdered.forEach((kept, i) => {
      const qRef = quizRef.collection("questions").doc(kept.id);
      if (!kept.edited) {
        batch.update(qRef, {order: i});
        return;
      }
      const opts = normalizeOptions(kept.edited.options);
      batch.update(qRef, {
        type: kept.edited.type || "multiple_choice",
        question: kept.edited.question || "",
        options: opts.map((o) => ({text: o.text})),
        order: i,
      });
      const correctIndices = [];
      opts.forEach((o, j) => {
        if (o.isCorrect) correctIndices.push(j);
      });
      batch.set(quizRef.collection("answer_keys").doc(kept.id), {
        correctIndices,
      });
    });

    removedQuestionIds.forEach((id) => {
      batch.delete(quizRef.collection("questions").doc(id));
      batch.delete(quizRef.collection("answer_keys").doc(id));
    });

    newQuestions.forEach((q, i) => {
      const opts = normalizeOptions(q.options);
      const qRef = quizRef.collection("questions").doc();
      batch.set(qRef, {
        type: q.type || "multiple_choice",
        question: q.question || "",
        options: opts.map((o) => ({text: o.text})),
        order: keptOrdered.length + i,
        createdAt: FieldValue.serverTimestamp(),
      });
      const correctIndices = [];
      opts.forEach((o, j) => {
        if (o.isCorrect) correctIndices.push(j);
      });
      batch.set(quizRef.collection("answer_keys").doc(qRef.id), {
        correctIndices,
      });
    });

    await batch.commit();
    res.json({
      updated: true,
      kept: keptOrdered.length,
      removed: removedQuestionIds.length,
      added: newQuestions.length,
    });
  } catch (err) {
    next(err);
  }
});

router.delete("/:cid/quizzes/:qid", async (req, res, next) => {
  try {
    const {cid, qid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const db = getFirestore();
    const quizRef = db.doc(`classes/${cid}/quizzes/${qid}`);
    const snap = await quizRef.get();
    if (!snap.exists) {
      return next({status: 404, message: "Quiz not found"});
    }

    const [qs, ks, ats] = await Promise.all([
      quizRef.collection("questions").get(),
      quizRef.collection("answer_keys").get(),
      quizRef.collection("attempts").get(),
    ]);

    const batch = db.batch();
    qs.docs.forEach((d) => batch.delete(d.ref));
    ks.docs.forEach((d) => batch.delete(d.ref));
    ats.docs.forEach((d) => batch.delete(d.ref));
    batch.delete(quizRef);
    await batch.commit();

    res.json({
      deleted: true,
      questions: qs.size,
      answerKeys: ks.size,
      attempts: ats.size,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
