const {Router} = require("express");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");

// Mount:
//   app.use("/memberships", joinRouter)
//     POST /memberships/join   — student join by class code
//
//   app.use("/classes", memberRouter)
//     GET    /classes/:cid/members            — list members
//     DELETE /classes/:cid/members/me         — leave (self)
//     POST   /classes/:cid/members/remove     — teacher bulk-remove students

const joinRouter = Router();
const memberRouter = Router();

function mapMember(doc) {
  const d = doc.data();
  return {
    uid: doc.id,
    role: d.role ?? "student",
    displayName: d.displayName ?? "",
    email: d.email ?? "",
    joinedAt: d.joinedAt?.toDate?.().toISOString?.() ?? null,
  };
}

joinRouter.post("/join", async (req, res, next) => {
  try {
    const code = (req.body?.classCode || "").trim().toUpperCase();
    if (!code) return next({status: 400, message: "classCode is required"});

    const db = getFirestore();
    const codeSnap = await db.doc(`class_codes/${code}`).get();
    if (!codeSnap.exists) {
      return next({status: 404, message: "Class code not found"});
    }

    const classId = codeSnap.data().classId;
    const classRef = db.doc(`classes/${classId}`);
    const memberRef = classRef.collection("members").doc(req.user.uid);
    const memberSnap = await memberRef.get();
    if (memberSnap.exists) {
      return next({
        status: 409,
        message: "You are already a member of this class",
      });
    }

    // Ambil displayName terbaru dari Auth.
    let displayName = "";
    try {
      const authUser = await getAuth().getUser(req.user.uid);
      displayName = authUser.displayName || "";
    } catch (_) {
      displayName = req.user.name || req.user.email || "";
    }

    const batch = db.batch();
    batch.set(memberRef, {
      role: "student",
      displayName,
      email: req.user.email || "",
      joinedAt: FieldValue.serverTimestamp(),
    });
    batch.update(classRef, {
      studentCount: FieldValue.increment(1),
      memberIds: FieldValue.arrayUnion(req.user.uid),
    });
    await batch.commit();

    res.status(201).json({classId, joined: true});
  } catch (err) {
    next(err);
  }
});

memberRouter.get("/:cid/members", async (req, res, next) => {
  try {
    const {cid} = req.params;
    const snap = await getFirestore()
        .collection(`classes/${cid}/members`)
        .get();
    res.json({members: snap.docs.map(mapMember)});
  } catch (err) {
    next(err);
  }
});

memberRouter.delete("/:cid/members/me", async (req, res, next) => {
  try {
    const {cid} = req.params;
    const db = getFirestore();
    const classRef = db.doc(`classes/${cid}`);
    const classSnap = await classRef.get();
    if (!classSnap.exists) {
      return next({status: 404, message: "Class not found"});
    }
    if (classSnap.data().teacherId === req.user.uid) {
      return next({
        status: 400,
        message: "Teacher cannot leave own class. Delete the class instead.",
      });
    }

    const memberRef = classRef.collection("members").doc(req.user.uid);
    const memberSnap = await memberRef.get();
    if (!memberSnap.exists) {
      return next({status: 404, message: "Not a member of this class"});
    }

    const batch = db.batch();
    batch.delete(memberRef);
    batch.update(classRef, {
      studentCount: FieldValue.increment(-1),
      memberIds: FieldValue.arrayRemove(req.user.uid),
    });
    await batch.commit();

    res.json({left: true});
  } catch (err) {
    next(err);
  }
});

memberRouter.post("/:cid/members/remove", async (req, res, next) => {
  try {
    const {cid} = req.params;
    const uids = Array.isArray(req.body?.uids) ? req.body.uids : null;
    if (!uids || uids.length === 0) {
      return next({status: 400, message: "uids array is required"});
    }

    const db = getFirestore();
    const classRef = db.doc(`classes/${cid}`);
    const classSnap = await classRef.get();
    if (!classSnap.exists) {
      return next({status: 404, message: "Class not found"});
    }
    if (classSnap.data().teacherId !== req.user.uid) {
      return next({status: 403, message: "Only the teacher can remove members"});
    }
    if (uids.includes(req.user.uid)) {
      return next({
        status: 400,
        message: "Teacher cannot remove self via this endpoint",
      });
    }

    const batch = db.batch();
    for (const uid of uids) {
      batch.delete(classRef.collection("members").doc(uid));
    }
    batch.update(classRef, {
      studentCount: FieldValue.increment(-uids.length),
      memberIds: FieldValue.arrayRemove(...uids),
    });
    await batch.commit();

    res.json({removed: uids.length});
  } catch (err) {
    next(err);
  }
});

module.exports = {joinRouter, memberRouter};
