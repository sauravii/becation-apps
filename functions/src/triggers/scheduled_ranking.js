const {onSchedule} = require("firebase-functions/v2/scheduler");
const {getFirestore, FieldValue, Timestamp} =
    require("firebase-admin/firestore");

const {awardBadge} = require("../shared/badge_award");

/**
 * Cron jobs untuk ranking & semester close.
 *
 *  - weeklyRankSnapshot       — Monday 02:00 Asia/Jakarta — audit trail
 *                                snapshot ranking semua active class.
 *  - dailySemesterCloseCheck  — Daily 03:00 — auto-close class yg sudah
 *                                lewat semesterEnd & belum di-close manual.
 *
 * closeSemester() di-export juga supaya endpoint
 * POST /api/classes/:cid/close-semester di Phase C bisa reuse logika.
 */

// ---------------------------- Cron handlers ----------------------------

const weeklyRankSnapshot = onSchedule(
    {
      schedule: "every monday 02:00",
      timeZone: "Asia/Jakarta",
      region: "us-central1",
    },
    async () => {
      const db = getFirestore();
      const now = Timestamp.now();
      const snap = await db.collection("classes")
          .where("semesterStart", "<=", now)
          .get();

      let count = 0;
      for (const classDoc of snap.docs) {
        const data = classDoc.data();
        if (data.closedAt) continue;
        if (data.semesterEnd &&
            data.semesterEnd.toMillis() < now.toMillis()) {
          continue;
        }
        try {
          await snapshotClassRanking(db, classDoc.id);
          count++;
        } catch (err) {
          console.error(
              `[weeklyRankSnapshot] ${classDoc.id}: ${err.message}`,
          );
        }
      }
      console.info(`[weeklyRankSnapshot] ${count} snapshots written`);
    },
);

const dailySemesterCloseCheck = onSchedule(
    {
      schedule: "every day 03:00",
      timeZone: "Asia/Jakarta",
      region: "us-central1",
    },
    async () => {
      const db = getFirestore();
      const now = Timestamp.now();
      const snap = await db.collection("classes")
          .where("semesterEnd", "<=", now)
          .get();

      let count = 0;
      for (const classDoc of snap.docs) {
        if (classDoc.data().closedAt) continue;
        try {
          await closeSemester(db, classDoc.id);
          count++;
        } catch (err) {
          console.error(
              `[dailySemesterCloseCheck] ${classDoc.id}: ${err.message}`,
          );
        }
      }
      console.info(`[dailySemesterCloseCheck] ${count} semesters closed`);
    },
);

// ---------------------------- Core logic ----------------------------

/**
 * Compute ranking per-class dan tulis snapshot ke rank_snapshots.
 * Return ranking array (sorted desc by point).
 */
async function snapshotClassRanking(db, classId) {
  const memberIds = await fetchActiveMemberIds(db, classId);
  if (memberIds.length === 0) return [];
  const ranking = await rankByPoint(db, memberIds);
  await db.collection(`classes/${classId}/rank_snapshots`).add({
    takenAt: FieldValue.serverTimestamp(),
    ranking,
  });
  return ranking;
}

async function fetchActiveMemberIds(db, classId) {
  const classSnap = await db.doc(`classes/${classId}`).get();
  if (!classSnap.exists) return [];
  const cached = classSnap.data().memberIds;
  if (Array.isArray(cached) && cached.length > 0) return cached;
  const subSnap = await db.collection(`classes/${classId}/members`).get();
  return subSnap.docs.map((d) => d.id);
}

async function rankByPoint(db, uids) {
  if (uids.length === 0) return [];
  // Batch reads — getAll() OK untuk skala kelas (< 1000 student).
  const refs = uids.map((u) => db.doc(`users/${u}`));
  const snaps = await db.getAll(...refs);
  const list = snaps
      .filter((s) => s.exists)
      .map((s) => ({
        uid: s.id,
        displayName: s.data().displayName || "",
        point: s.data().point || 0,
      }));
  list.sort((a, b) => b.point - a.point);
  return list;
}

/**
 * Tutup semester: snapshot final + award badge juara 1/2/3 + set closedAt.
 * Idempotent — kalau closedAt sudah ada, skip semuanya.
 */
async function closeSemester(db, classId) {
  const classRef = db.doc(`classes/${classId}`);
  const classSnap = await classRef.get();
  if (!classSnap.exists) {
    const err = new Error("Class not found");
    err.status = 404;
    throw err;
  }
  if (classSnap.data().closedAt) {
    return {alreadyClosed: true, ranking: [], awardsGranted: []};
  }

  const ranking = await snapshotClassRanking(db, classId);
  const awards = [
    {rank: 1, badgeId: "top_of_world"},
    {rank: 2, badgeId: "almost"},
    {rank: 3, badgeId: "close_enough"},
  ];

  const granted = [];
  for (const a of awards) {
    const winner = ranking[a.rank - 1];
    if (!winner) continue;
    try {
      const result = await awardBadge(winner.uid, a.badgeId, {
        context: {classId},
      });
      if (result.awarded) {
        granted.push({rank: a.rank, badgeId: a.badgeId, uid: winner.uid});
      }
    } catch (err) {
      console.error(
          `[closeSemester] award ${a.badgeId} to ${winner.uid} failed: ${err.message}`,
      );
    }
  }

  await classRef.update({
    closedAt: FieldValue.serverTimestamp(),
  });

  return {alreadyClosed: false, ranking, awardsGranted: granted};
}

module.exports = {
  weeklyRankSnapshot,
  dailySemesterCloseCheck,
  closeSemester,
  snapshotClassRanking,
};
