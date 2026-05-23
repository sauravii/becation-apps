const {Router} = require("express");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {dailyStreakReward, dateKeyJakarta} =
    require("../../shared/point_rules");
const {awardBadge} = require("../../shared/badge_award");
const {assertSelfOrAdmin} = require("../helpers/authorize");
const {parsePagination} = require("../helpers/pagination");

const router = Router();

// Mount: app.use("/users", pointsRouter)
//   POST  /users/me/ping              — daily streak update + overachiever check
//   GET   /users/:uid/points          — self or admin
//   GET   /users/:uid/points/log      — paginated, self or admin

const OVERACHIEVER_INTERVAL = 28;

function resolveUid(req) {
  const p = req.params.uid;
  return p === "me" ? req.user.uid : p;
}

function isoOrNull(ts) {
  return ts && ts.toDate ? ts.toDate().toISOString() : null;
}

router.post("/me/ping", async (req, res, next) => {
  try {
    const uid = req.user.uid;
    const now = new Date();
    const todayKey = dateKeyJakarta(now);
    const yesterdayKey = dateKeyJakarta(new Date(now.getTime() - 86400000));

    const db = getFirestore();
    const userRef = db.doc(`users/${uid}`);

    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      const data = snap.exists ? snap.data() : {};
      const streak = data.streak || {
        current: 0,
        longest: 0,
        lastLoginDate: null,
        lastOverachieverMilestone: 0,
      };

      if (streak.lastLoginDate === todayKey) {
        return {
          streak,
          milestoneReached: null,
          isNewDay: false,
          pointAwarded: 0,
        };
      }

      const newCurrent = streak.lastLoginDate === yesterdayKey ?
          (streak.current || 0) + 1 :
          1;
      const newLongest = Math.max(streak.longest || 0, newCurrent);
      const reward = dailyStreakReward(newCurrent);

      let milestoneReached = null;
      const lastMs = streak.lastOverachieverMilestone || 0;
      if (newCurrent >= OVERACHIEVER_INTERVAL &&
          newCurrent >= lastMs + OVERACHIEVER_INTERVAL) {
        milestoneReached =
            Math.floor(newCurrent / OVERACHIEVER_INTERVAL) * OVERACHIEVER_INTERVAL;
      }

      const newStreak = {
        current: newCurrent,
        longest: newLongest,
        lastLoginDate: todayKey,
        lastOverachieverMilestone:
            milestoneReached || lastMs,
      };
      tx.set(userRef, {streak: newStreak}, {merge: true});

      if (reward > 0) {
        tx.set(userRef, {point: FieldValue.increment(reward)}, {merge: true});
        tx.set(db.doc(`users/${uid}/points_log/streak:${todayKey}`), {
          delta: reward,
          reason: "daily_streak",
          refType: "streak",
          refId: todayKey,
          meta: {streakDay: newCurrent},
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      return {
        streak: newStreak,
        milestoneReached,
        isNewDay: true,
        pointAwarded: reward,
      };
    });

    // Award Overachiever outside transaction.
    let overachieverEarned = false;
    if (result.milestoneReached) {
      try {
        const awardResult = await awardBadge(uid, "overachiever", {
          context: {
            streakDay: result.streak.current,
            milestone: result.milestoneReached,
          },
          dedupKey: `milestone:${result.milestoneReached}`,
        });
        overachieverEarned = awardResult.awarded;
      } catch (err) {
        console.error(`[ping] overachiever award failed: ${err.message}`);
      }
    }

    res.json({
      streakDay: result.streak.current,
      longestStreak: result.streak.longest,
      isNewDay: result.isNewDay,
      pointAwarded: result.pointAwarded,
      milestoneReached: result.milestoneReached,
      overachieverEarned,
    });
  } catch (err) {
    next(err);
  }
});

router.get("/:uid/points", async (req, res, next) => {
  try {
    const targetUid = resolveUid(req);
    await assertSelfOrAdmin(req.user.uid, targetUid);

    const snap = await getFirestore().doc(`users/${targetUid}`).get();
    if (!snap.exists) {
      return next({status: 404, message: "User not found"});
    }
    const data = snap.data();
    res.json({
      uid: targetUid,
      point: data.point || 0,
      streak: data.streak || {
        current: 0,
        longest: 0,
        lastLoginDate: null,
      },
    });
  } catch (err) {
    next(err);
  }
});

router.get("/:uid/points/log", async (req, res, next) => {
  try {
    const targetUid = resolveUid(req);
    await assertSelfOrAdmin(req.user.uid, targetUid);
    const {limit, cursor} = parsePagination(req.query, {defaultLimit: 30});

    const db = getFirestore();
    let q = db.collection(`users/${targetUid}/points_log`)
        .orderBy("createdAt", "desc")
        .limit(limit);
    if (cursor) {
      const cursorSnap =
          await db.doc(`users/${targetUid}/points_log/${cursor}`).get();
      if (cursorSnap.exists) q = q.startAfter(cursorSnap);
    }
    const snap = await q.get();
    const logs = snap.docs.map((d) => ({
      id: d.id,
      delta: d.data().delta || 0,
      reason: d.data().reason || "",
      refType: d.data().refType || "",
      refId: d.data().refId || "",
      meta: d.data().meta || {},
      createdAt: isoOrNull(d.data().createdAt),
    }));
    const nextCursor = snap.docs.length === limit ?
        snap.docs[snap.docs.length - 1].id :
        null;
    res.json({logs, nextCursor});
  } catch (err) {
    next(err);
  }
});

module.exports = router;
