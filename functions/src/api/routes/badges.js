const {Router} = require("express");
const {getFirestore} = require("firebase-admin/firestore");

const {BADGES, getBadgeDef} =
    require("../../shared/badge_definitions");
const {awardBadge} = require("../../shared/badge_award");
const {assertAdmin} = require("../helpers/authorize");

const router = Router();

// Mount: app.use("/users", badgesRouter)
//   GET    /users/:uid/badges            — list badge user (merge def + earned)
//   POST   /users/:uid/badges            — admin manual grant
//   DELETE /users/:uid/badges/:badgeId   — admin revoke

function resolveUid(req) {
  const p = req.params.uid;
  return p === "me" ? req.user.uid : p;
}

function isoOrNull(ts) {
  return ts && ts.toDate ? ts.toDate().toISOString() : null;
}

router.get("/:uid/badges", async (req, res, next) => {
  try {
    const targetUid = resolveUid(req);
    const snap =
        await getFirestore().collection(`users/${targetUid}/badges`).get();
    const earned = {};
    snap.docs.forEach((d) => {
      earned[d.id] = d.data();
    });

    // Secret badges hidden kalau belum earned.
    const visible = BADGES.filter((b) => earned[b.id] || !b.isSecret);
    const badges = visible.map((b) => {
      const e = earned[b.id];
      const base = {
        id: b.id,
        name: b.name,
        description: b.description,
        tier: b.tier,
        iconPath: b.iconPath,
        pointReward: b.pointReward,
        isSecret: b.isSecret,
        repeatable: b.repeatable,
        criteriaType: b.criteriaType,
        earned: Boolean(e),
      };
      if (!e) return base;
      return {
        ...base,
        count: e.count || 1,
        firstEarnedAt: isoOrNull(e.firstEarnedAt),
        lastEarnedAt: isoOrNull(e.lastEarnedAt),
        lastContext: e.lastContext || {},
      };
    });

    res.json({uid: targetUid, badges});
  } catch (err) {
    next(err);
  }
});

router.post("/:uid/badges", async (req, res, next) => {
  try {
    await assertAdmin(req.user.uid);
    const targetUid = resolveUid(req);
    const badgeId = (req.body?.badgeId || "").trim();
    if (!badgeId) {
      return next({status: 400, message: "badgeId is required"});
    }
    const def = getBadgeDef(badgeId);
    if (!def) {
      return next({status: 400, message: `Unknown badgeId: ${badgeId}`});
    }

    const opts = {
      context: {
        ...(req.body?.context || {}),
        manualGrantBy: req.user.uid,
      },
    };
    if (def.repeatable) {
      opts.dedupKey = req.body?.dedupKey ||
          `manual:${req.user.uid}:${Date.now()}`;
    }

    const result = await awardBadge(targetUid, badgeId, opts);
    res.status(result.awarded ? 201 : 200).json(result);
  } catch (err) {
    next(err);
  }
});

router.delete("/:uid/badges/:badgeId", async (req, res, next) => {
  try {
    await assertAdmin(req.user.uid);
    const targetUid = resolveUid(req);
    const {badgeId} = req.params;

    const ref =
        getFirestore().doc(`users/${targetUid}/badges/${badgeId}`);
    const snap = await ref.get();
    if (!snap.exists) {
      return next({status: 404, message: "Badge not found on user"});
    }
    await ref.delete();
    res.json({deleted: true, badgeId});
  } catch (err) {
    next(err);
  }
});

module.exports = router;
