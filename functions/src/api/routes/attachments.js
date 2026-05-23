const {Router} = require("express");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");

const {assertTeacherOfClass} = require("../helpers/authorize");

const router = Router();

// Mount: app.use("/classes", attachmentsRouter)
//   GET    /classes/:cid/materials/:mid/attachments
//   POST   /classes/:cid/materials/:mid/attachments     (metadata-only)
//   PATCH  /classes/:cid/materials/:mid/attachments/:aid
//   DELETE /classes/:cid/materials/:mid/attachments/:aid (cascade Storage)
//
// NOTE: Upload bytes file tetap lewat Storage SDK di client (32MB limit
// Functions + double-hop waste). Endpoint POST di sini cuma untuk metadata
// (mis. link YouTube/Drive, atau metadata setelah client selesai upload).

function mapAttachment(doc) {
  const d = doc.data();
  return {
    id: doc.id,
    title: d.title ?? "",
    type: d.type ?? "",
    url: d.url ?? "",
    fileSize: d.fileSize ?? "",
    fileExtension: d.fileExtension ?? "",
    storagePath: d.storagePath ?? null,
    createdAt: d.createdAt?.toDate?.().toISOString?.() ?? null,
  };
}

router.get("/:cid/materials/:mid/attachments", async (req, res, next) => {
  try {
    const {cid, mid} = req.params;
    const snap = await getFirestore()
        .collection(`classes/${cid}/materials/${mid}/attachments`)
        .orderBy("createdAt")
        .get();
    res.json({attachments: snap.docs.map(mapAttachment)});
  } catch (err) {
    next(err);
  }
});

router.post("/:cid/materials/:mid/attachments", async (req, res, next) => {
  try {
    const {cid, mid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const title = (req.body?.title || "").trim();
    const type = (req.body?.type || "").trim();
    const url = (req.body?.url || "").trim();

    if (!title) return next({status: 400, message: "title is required"});
    if (!type) return next({status: 400, message: "type is required"});
    if (!url) return next({status: 400, message: "url is required"});

    const payload = {
      title,
      type,
      url,
      fileSize: req.body?.fileSize ?? "",
      createdAt: FieldValue.serverTimestamp(),
    };
    if (req.body?.fileExtension) payload.fileExtension = req.body.fileExtension;
    if (req.body?.storagePath) payload.storagePath = req.body.storagePath;

    const doc = await getFirestore()
        .collection(`classes/${cid}/materials/${mid}/attachments`)
        .add(payload);
    const created = await doc.get();
    res.status(201).json(mapAttachment(created));
  } catch (err) {
    next(err);
  }
});

router.patch(
    "/:cid/materials/:mid/attachments/:aid",
    async (req, res, next) => {
      try {
        const {cid, mid, aid} = req.params;
        await assertTeacherOfClass(req.user.uid, cid);

        if (typeof req.body?.title !== "string") {
          return next({status: 400, message: "title is required"});
        }
        const title = req.body.title.trim();
        if (!title) {
          return next({status: 400, message: "title cannot be blank"});
        }

        const ref = getFirestore()
            .doc(`classes/${cid}/materials/${mid}/attachments/${aid}`);
        const snap = await ref.get();
        if (!snap.exists) {
          return next({status: 404, message: "Attachment not found"});
        }
        await ref.update({title});
        const updated = await ref.get();
        res.json(mapAttachment(updated));
      } catch (err) {
        next(err);
      }
    },
);

router.delete(
    "/:cid/materials/:mid/attachments/:aid",
    async (req, res, next) => {
      try {
        const {cid, mid, aid} = req.params;
        await assertTeacherOfClass(req.user.uid, cid);

        const ref = getFirestore()
            .doc(`classes/${cid}/materials/${mid}/attachments/${aid}`);
        const snap = await ref.get();
        if (!snap.exists) {
          return next({status: 404, message: "Attachment not found"});
        }

        // Cascade: hapus file di Storage kalau ada.
        const storagePath = snap.data().storagePath;
        let storageDeleted = false;
        if (storagePath) {
          try {
            await getStorage().bucket().file(storagePath).delete();
            storageDeleted = true;
          } catch (err) {
            console.warn(
                `[attachments] storage delete failed for ${storagePath}: ${err.message}`,
            );
          }
        }

        await ref.delete();
        res.json({deleted: true, storageDeleted});
      } catch (err) {
        next(err);
      }
    },
);

module.exports = router;
