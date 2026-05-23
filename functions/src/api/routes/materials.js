const {Router} = require("express");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {assertTeacherOfClass} = require("../helpers/authorize");

const router = Router();

// Mount: app.use("/classes", materialsRouter)
//   GET    /classes/:cid/materials?topicId=<tid>
//   GET    /classes/:cid/materials/:mid
//   POST   /classes/:cid/materials
//   PATCH  /classes/:cid/materials/:mid
//   DELETE /classes/:cid/materials/:mid

function mapMaterial(doc) {
  const d = doc.data();
  return {
    id: doc.id,
    title: d.title ?? "",
    description: d.description ?? "",
    topicId: d.topicId ?? "",
    topicTitle: d.topicTitle ?? "",
    createdAt: d.createdAt?.toDate?.().toISOString?.() ?? null,
    createdBy: d.createdBy ?? "",
  };
}

router.get("/:cid/materials", async (req, res, next) => {
  try {
    const {cid} = req.params;
    const {topicId} = req.query;
    let query = getFirestore().collection(`classes/${cid}/materials`);
    if (topicId) {
      query = query.where("topicId", "==", topicId);
    }
    const snap = await query.orderBy("createdAt").get();
    res.json({materials: snap.docs.map(mapMaterial)});
  } catch (err) {
    next(err);
  }
});

router.get("/:cid/materials/:mid", async (req, res, next) => {
  try {
    const {cid, mid} = req.params;
    const snap = await getFirestore()
        .doc(`classes/${cid}/materials/${mid}`)
        .get();
    if (!snap.exists) {
      return next({status: 404, message: "Material not found"});
    }
    res.json(mapMaterial(snap));
  } catch (err) {
    next(err);
  }
});

router.post("/:cid/materials", async (req, res, next) => {
  try {
    const {cid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const title = (req.body?.title || "").trim();
    const topicId = (req.body?.topicId || "").trim();
    const topicTitle = (req.body?.topicTitle || "").trim();
    const description = (req.body?.description || "").trim();

    if (!title) return next({status: 400, message: "title is required"});
    if (!topicId) return next({status: 400, message: "topicId is required"});

    const doc = await getFirestore()
        .collection(`classes/${cid}/materials`)
        .add({
          title,
          description,
          topicId,
          topicTitle,
          createdAt: FieldValue.serverTimestamp(),
          createdBy: req.user.uid,
        });
    const created = await doc.get();
    res.status(201).json(mapMaterial(created));
  } catch (err) {
    next(err);
  }
});

router.patch("/:cid/materials/:mid", async (req, res, next) => {
  try {
    const {cid, mid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const updates = {};
    if (typeof req.body?.title === "string") {
      const t = req.body.title.trim();
      if (!t) return next({status: 400, message: "title cannot be blank"});
      updates.title = t;
    }
    if (typeof req.body?.description === "string") {
      updates.description = req.body.description;
    }
    if (Object.keys(updates).length === 0) {
      return next({status: 400, message: "no fields to update"});
    }

    const ref = getFirestore().doc(`classes/${cid}/materials/${mid}`);
    const snap = await ref.get();
    if (!snap.exists) {
      return next({status: 404, message: "Material not found"});
    }
    await ref.update(updates);
    const updated = await ref.get();
    res.json(mapMaterial(updated));
  } catch (err) {
    next(err);
  }
});

router.delete("/:cid/materials/:mid", async (req, res, next) => {
  try {
    const {cid, mid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const ref = getFirestore().doc(`classes/${cid}/materials/${mid}`);
    const snap = await ref.get();
    if (!snap.exists) {
      return next({status: 404, message: "Material not found"});
    }
    await ref.delete();
    res.json({deleted: true});
  } catch (err) {
    next(err);
  }
});

module.exports = router;
