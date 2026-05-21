const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const {getBadgeDef} = require("../shared/badge_definitions");

/**
 * Award badge ke user. Schema unified untuk semua badge:
 *   users/{uid}/badges/{badgeId} → {
 *     count: number,              // 1 untuk one-time, N untuk repeatable
 *     firstEarnedAt: Timestamp,
 *     lastEarnedAt: Timestamp,
 *     lastContext: { ... },
 *     earnedKeys: [string]        // hanya untuk repeatable — dedup mechanism
 *   }
 *
 * One-time badge: existing doc → skip ("already_earned").
 * Repeatable badge: WAJIB dedupKey unique per earn (mis. attempt aid, topic id,
 *   streak milestone). Kalau key sudah ada di earnedKeys → skip ("dedup").
 *
 * Point bonus (Opsi A): full pointReward setiap earn. points_log doc id pakai
 * dedupKey supaya retry-safe (`badge:{id}:{key}` atau `badge:{id}` untuk one-time).
 *
 * @param {string} uid
 * @param {string} badgeId
 * @param {object} opts
 * @param {object} [opts.context]  — metadata yg disimpan jadi lastContext
 * @param {string} [opts.dedupKey] — REQUIRED untuk repeatable badge
 * @return {Promise<{awarded: boolean, badgeId: string, pointAwarded: number, count: number, reason?: string}>}
 */
async function awardBadge(uid, badgeId, opts = {}) {
  const def = getBadgeDef(badgeId);
  if (!def) {
    console.warn(`[badge_award] unknown badgeId: ${badgeId}`);
    return {awarded: false, badgeId, pointAwarded: 0, count: 0};
  }

  const {context = {}, dedupKey = null} = opts;
  if (def.repeatable && !dedupKey) {
    throw new Error(
        `[badge_award] dedupKey required for repeatable badge "${badgeId}"`,
    );
  }

  const db = getFirestore();
  const badgeRef = db.doc(`users/${uid}/badges/${badgeId}`);
  const userRef = db.doc(`users/${uid}`);
  const logId = dedupKey ?
      `badge:${badgeId}:${dedupKey}` :
      `badge:${badgeId}`;
  const logRef = db.doc(`users/${uid}/points_log/${logId}`);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(badgeRef);
    const existing = snap.exists ? snap.data() : null;

    if (!def.repeatable && existing) {
      return {
        awarded: false,
        badgeId,
        pointAwarded: 0,
        count: existing.count || 1,
        reason: "already_earned",
      };
    }
    if (def.repeatable) {
      const keys = (existing && existing.earnedKeys) || [];
      if (keys.includes(dedupKey)) {
        return {
          awarded: false,
          badgeId,
          pointAwarded: 0,
          count: existing.count || 0,
          reason: "dedup",
        };
      }
    }

    const newCount = (existing && existing.count || 0) + 1;
    const now = FieldValue.serverTimestamp();
    const payload = {
      count: newCount,
      firstEarnedAt: (existing && existing.firstEarnedAt) || now,
      lastEarnedAt: now,
      lastContext: context,
    };
    if (def.repeatable) {
      const prevKeys = (existing && existing.earnedKeys) || [];
      payload.earnedKeys = [...prevKeys, dedupKey];
    }
    tx.set(badgeRef, payload, {merge: true});

    if (def.pointReward > 0) {
      tx.set(
          userRef,
          {point: FieldValue.increment(def.pointReward)},
          {merge: true},
      );
      tx.set(logRef, {
        delta: def.pointReward,
        reason: "badge_earned",
        refType: "badge",
        refId: badgeId,
        meta: {...context, dedupKey, earnNumber: newCount},
        createdAt: now,
      });
    }

    return {
      awarded: true,
      badgeId,
      pointAwarded: def.pointReward,
      count: newCount,
    };
  });
}

module.exports = {awardBadge};
