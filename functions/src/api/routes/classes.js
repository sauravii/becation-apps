const {Router} = require("express");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");

const router = Router();

// Mount: app.use("/classes", classesRouter)
//   GET    /classes/teaching          — class yang current user jadi teacher
//   GET    /classes/enrolled          — class yang current user jadi student
//   GET    /classes/:cid              — detail kelas
//   POST   /classes                   — create kelas baru
//   PATCH  /classes/:cid              — update (title/subject/description)
//   DELETE /classes/:cid              — cascade delete kelas + isinya

const CODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

function mapClass(doc) {
  const d = doc.data();
  return {
    id: doc.id,
    title: d.title ?? "",
    subject: d.subject ?? "",
    description: d.description ?? "",
    colorValue: d.colorValue ?? 0xFF6F5AAA,
    classCode: d.classCode ?? "",
    teacherId: d.teacherId ?? "",
    teacherName: d.teacherName ?? "",
    studentCount: d.studentCount ?? 0,
    createdAt: d.createdAt?.toDate?.().toISOString?.() ?? null,
    updatedAt: d.updatedAt?.toDate?.().toISOString?.() ?? null,
  };
}

async function generateUniqueCode(db) {
  while (true) {
    let code = "";
    for (let i = 0; i < 6; i++) {
      code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
    }
    const snap = await db.doc(`class_codes/${code}`).get();
    if (!snap.exists) return code;
  }
}

router.get("/teaching", async (req, res, next) => {
  try {
    const snap = await getFirestore()
        .collection("classes")
        .where("teacherId", "==", req.user.uid)
        .get();
    res.json({classes: snap.docs.map(mapClass)});
  } catch (err) {
    next(err);
  }
});

router.get("/enrolled", async (req, res, next) => {
  try {
    const snap = await getFirestore()
        .collection("classes")
        .where("memberIds", "array-contains", req.user.uid)
        .get();
    const classes = snap.docs
        .filter((d) => d.data().teacherId !== req.user.uid)
        .map(mapClass);
    res.json({classes});
  } catch (err) {
    next(err);
  }
});

router.get("/:cid", async (req, res, next) => {
  try {
    const {cid} = req.params;
    const snap = await getFirestore().doc(`classes/${cid}`).get();
    if (!snap.exists) {
      return next({status: 404, message: "Class not found"});
    }
    res.json(mapClass(snap));
  } catch (err) {
    next(err);
  }
});

router.post("/", async (req, res, next) => {
  try {
    const title = (req.body?.title || "").trim();
    const subject = (req.body?.subject || "").trim();
    const description = (req.body?.description || "").trim();
    const colorValue = Number(req.body?.colorValue ?? 0xFF6F5AAA);

    if (!title) return next({status: 400, message: "title is required"});
    if (!subject) return next({status: 400, message: "subject is required"});

    const db = getFirestore();
    const classCode = await generateUniqueCode(db);

    // Ambil displayName terbaru dari Firebase Auth (lebih reliable daripada
    // body, dan match dengan ensureUserDocument).
    let teacherName = "";
    try {
      const authUser = await getAuth().getUser(req.user.uid);
      teacherName = authUser.displayName || "";
    } catch (_) {
      teacherName = req.user.name || req.user.email || "";
    }

    const classRef = db.collection("classes").doc();
    const classId = classRef.id;
    const memberRef = classRef.collection("members").doc(req.user.uid);
    const codeRef = db.doc(`class_codes/${classCode}`);

    const batch = db.batch();
    batch.set(classRef, {
      title,
      subject,
      description,
      colorValue,
      classCode,
      teacherId: req.user.uid,
      teacherName,
      studentCount: 0,
      memberIds: [req.user.uid],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    batch.set(memberRef, {
      role: "teacher",
      displayName: teacherName,
      email: req.user.email || "",
      joinedAt: FieldValue.serverTimestamp(),
    });
    batch.set(codeRef, {classId});
    await batch.commit();

    const created = await classRef.get();
    res.status(201).json(mapClass(created));
  } catch (err) {
    next(err);
  }
});

router.patch("/:cid", async (req, res, next) => {
  try {
    const {cid} = req.params;
    const ref = getFirestore().doc(`classes/${cid}`);
    const snap = await ref.get();
    if (!snap.exists) {
      return next({status: 404, message: "Class not found"});
    }
    if (snap.data().teacherId !== req.user.uid) {
      return next({status: 403, message: "Only the teacher can update"});
    }

    const updates = {updatedAt: FieldValue.serverTimestamp()};
    if (typeof req.body?.title === "string") {
      const t = req.body.title.trim();
      if (!t) return next({status: 400, message: "title cannot be blank"});
      updates.title = t;
    }
    if (typeof req.body?.subject === "string") {
      updates.subject = req.body.subject.trim();
    }
    if (typeof req.body?.description === "string") {
      updates.description = req.body.description.trim();
    }

    await ref.update(updates);
    const updated = await ref.get();
    res.json(mapClass(updated));
  } catch (err) {
    next(err);
  }
});

router.delete("/:cid", async (req, res, next) => {
  try {
    const {cid} = req.params;
    const db = getFirestore();
    const classRef = db.doc(`classes/${cid}`);
    const snap = await classRef.get();
    if (!snap.exists) {
      return next({status: 404, message: "Class not found"});
    }
    if (snap.data().teacherId !== req.user.uid) {
      return next({status: 403, message: "Only the teacher can delete"});
    }

    const classCode = snap.data().classCode;
    const [members, materials, topics, quizzes] = await Promise.all([
      classRef.collection("members").get(),
      classRef.collection("materials").get(),
      classRef.collection("topics").get(),
      classRef.collection("quizzes").get(),
    ]);

    const batch = db.batch();

    members.docs.forEach((d) => batch.delete(d.ref));
    topics.docs.forEach((d) => batch.delete(d.ref));

    for (const matDoc of materials.docs) {
      const attachments = await matDoc.ref.collection("attachments").get();
      attachments.docs.forEach((a) => batch.delete(a.ref));
      batch.delete(matDoc.ref);
    }

    let totalQuestions = 0;
    let totalKeys = 0;
    let totalAttempts = 0;
    for (const quizDoc of quizzes.docs) {
      const [qs, ks, ats] = await Promise.all([
        quizDoc.ref.collection("questions").get(),
        quizDoc.ref.collection("answer_keys").get(),
        quizDoc.ref.collection("attempts").get(),
      ]);
      qs.docs.forEach((d) => batch.delete(d.ref));
      ks.docs.forEach((d) => batch.delete(d.ref));
      ats.docs.forEach((d) => batch.delete(d.ref));
      batch.delete(quizDoc.ref);
      totalQuestions += qs.size;
      totalKeys += ks.size;
      totalAttempts += ats.size;
    }

    if (classCode) {
      batch.delete(db.doc(`class_codes/${classCode}`));
    }
    batch.delete(classRef);
    await batch.commit();

    res.json({
      deleted: true,
      members: members.size,
      topics: topics.size,
      materials: materials.size,
      quizzes: quizzes.size,
      questions: totalQuestions,
      answerKeys: totalKeys,
      attempts: totalAttempts,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
