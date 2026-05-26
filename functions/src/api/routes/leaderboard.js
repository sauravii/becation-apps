const {Router} = require("express");
const {getFirestore} = require("firebase-admin/firestore");

const {closeSemester} =
    require("../../triggers/scheduled_ranking");
const {assertMemberOfClass, assertTeacherOfClass} =
    require("../helpers/authorize");
const {parsePagination} = require("../helpers/pagination");

const router = Router();

// Mount: app.use("/classes", leaderboardRouter)
//   GET   /classes/:cid/leaderboard?limit=100   — member of class
//   POST  /classes/:cid/close-semester          — teacher of class

router.get("/:cid/leaderboard", async (req, res, next) => {
  try {
    const {cid} = req.params;
    await assertMemberOfClass(req.user.uid, cid);
    const {limit} = parsePagination(req.query, {
      defaultLimit: 100,
      maxLimit: 100,
    });

    const db = getFirestore();
    const classSnap = await db.doc(`classes/${cid}`).get();
    if (!classSnap.exists) {
      return next({status: 404, message: "Class not found"});
    }

    const teacherId = classSnap.data().teacherId;

    let memberIds = classSnap.data().memberIds;
    if (!Array.isArray(memberIds) || memberIds.length === 0) {
      // Fallback ke sub-collection kalau memberIds cache belum populated.
      const subSnap =
          await db.collection(`classes/${cid}/members`).get();
      memberIds = subSnap.docs.map((d) => d.id);
    }
    // Exclude teacher — leaderboard hanya untuk student.
    memberIds = memberIds.filter((uid) => uid !== teacherId);
    if (memberIds.length === 0) {
      return res.json({ranking: [], total: 0});
    }

    // Ambil 2 sumber paralel:
    //  - users/{uid} → displayName + photoUrl (single source of truth)
    //  - classes/{cid}/members/{uid} → point per-class (LOCAL leaderboard,
    //    bukan global users.point)
    const userRefs = memberIds.map((u) => db.doc(`users/${u}`));
    const memberRefs = memberIds.map(
        (u) => db.doc(`classes/${cid}/members/${u}`),
    );
    const [userSnaps, memberSnaps] = await Promise.all([
      db.getAll(...userRefs),
      db.getAll(...memberRefs),
    ]);

    const memberPointsByUid = new Map();
    for (const ms of memberSnaps) {
      if (ms.exists) memberPointsByUid.set(ms.id, ms.data().point || 0);
    }

    const list = userSnaps
        .filter((s) => s.exists)
        .map((s) => ({
          uid: s.id,
          displayName: s.data().displayName || "",
          photoUrl: s.data().photoUrl || "",
          point: memberPointsByUid.get(s.id) || 0,
        }));
    list.sort((a, b) => b.point - a.point);

    const ranking = list.slice(0, limit).map((u, i) => ({
      ...u,
      rank: i + 1,
    }));
    res.json({
      ranking,
      total: list.length,
      closed: Boolean(classSnap.data().closedAt),
    });
  } catch (err) {
    next(err);
  }
});

router.post("/:cid/close-semester", async (req, res, next) => {
  try {
    const {cid} = req.params;
    await assertTeacherOfClass(req.user.uid, cid);

    const db = getFirestore();
    const result = await closeSemester(db, cid);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
