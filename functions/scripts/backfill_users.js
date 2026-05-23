/**
 * One-shot backfill: pastikan setiap doc di `users/` punya field
 *   - point: 0
 *   - streak: { current: 0, longest: 0, lastLoginDate: null,
 *               lastOverachieverMilestone: 0 }
 *
 * Idempotent — kalau field sudah ada, di-skip.
 *
 * Usage (sekali sebelum deploy v1.4.0 ke production):
 *   cd functions
 *   gcloud auth application-default login         # sekali setup
 *   gcloud config set project becation-eac04
 *   node scripts/backfill_users.js
 */

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp({credential: applicationDefault()});

async function main() {
  const db = getFirestore();
  const snap = await db.collection("users").get();
  console.log(`[backfill_users] Found ${snap.size} user docs.`);

  let updated = 0;
  let skipped = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    const updates = {};

    if (typeof data.point !== "number") {
      updates.point = 0;
    }
    if (!data.streak || typeof data.streak !== "object") {
      updates.streak = {
        current: 0,
        longest: 0,
        lastLoginDate: null,
        lastOverachieverMilestone: 0,
      };
    } else {
      // Patch sub-fields kalau ada yg missing.
      const sub = {...data.streak};
      let patched = false;
      if (typeof sub.current !== "number") {sub.current = 0; patched = true;}
      if (typeof sub.longest !== "number") {sub.longest = 0; patched = true;}
      if (!("lastLoginDate" in sub)) {
        sub.lastLoginDate = null;
        patched = true;
      }
      if (typeof sub.lastOverachieverMilestone !== "number") {
        sub.lastOverachieverMilestone = 0;
        patched = true;
      }
      if (patched) updates.streak = sub;
    }

    if (Object.keys(updates).length === 0) {
      skipped++;
      continue;
    }
    await doc.ref.set(updates, {merge: true});
    updated++;
  }

  console.log(`[backfill_users] updated=${updated} skipped=${skipped}`);
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error("[backfill_users] failed:", err);
      process.exit(1);
    });
