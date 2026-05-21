/**
 * Seed `badge_definitions/{badgeId}` collection dari BADGES constant di
 * src/shared/badge_definitions.js.
 *
 * Idempotent — set with merge:true. Tinggal re-run kalau ada perubahan di
 * source file.
 *
 * Catatan iconUrl: script ini set field `iconUrl: null`. URL public icon
 * di-resolve di runtime via Firebase Storage SDK di Flutter. Kalau mau
 * pre-resolve persistent URL di sini, uncomment block getSignedUrl di bawah
 * dan pastikan icon sudah ter-upload ke `badges/{id}.png` di Storage.
 *
 * Usage:
 *   cd functions
 *   gcloud auth application-default login          # sekali setup
 *   gcloud config set project becation-eac04
 *   node scripts/seed_badge_definitions.js
 */

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp({credential: applicationDefault()});

const {BADGES} = require("../src/shared/badge_definitions");

async function main() {
  const db = getFirestore();
  let seeded = 0;
  for (const badge of BADGES) {
    const payload = {
      name: badge.name,
      description: badge.description,
      tier: badge.tier,
      iconPath: badge.iconPath,
      iconUrl: null,
      pointReward: badge.pointReward,
      isSecret: badge.isSecret,
      repeatable: badge.repeatable,
      criteriaType: badge.criteriaType,
    };
    if (badge.rankPosition) payload.rankPosition = badge.rankPosition;

    await db.doc(`badge_definitions/${badge.id}`).set(payload, {merge: true});
    seeded++;
    console.log(`  ✓ ${badge.id}`);
  }
  console.log(`[seed_badges] seeded ${seeded} badge definitions.`);
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error("[seed_badges] failed:", err);
      process.exit(1);
    });
