/**
 * Seed `badge_definitions/{badgeId}` collection dari BADGES constant di
 * src/shared/badge_definitions.js. Auto-resolve iconUrl dari Firebase Storage
 * (file harus sudah ter-upload di path `badges/{id}.png`).
 *
 * Idempotent — set with merge:true. Re-run kalau ada perubahan di source file
 * atau setelah upload icon baru.
 *
 * URL pattern: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encodedPath}?alt=media
 * Bekerja TANPA token kalau Storage Rule allow public read di path `badges/*`
 * (lihat storage.rules — sudah di-set v1.4.0).
 *
 * Usage:
 *   cd functions
 *   gcloud auth application-default login          # sekali setup
 *   gcloud config set project becation-showcase
 *   node scripts/seed_badge_definitions.js
 *
 * Override bucket via env var kalau perlu:
 *   STORAGE_BUCKET=other-bucket.appspot.com node scripts/seed_badge_definitions.js
 */

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");

const STORAGE_BUCKET =
    process.env.STORAGE_BUCKET ||
    "becation-showcase.firebasestorage.app";

initializeApp({
  credential: applicationDefault(),
  storageBucket: STORAGE_BUCKET,
});

const {BADGES} = require("../src/shared/badge_definitions");

async function resolveIconUrl(bucket, iconPath) {
  const file = bucket.file(iconPath);
  const [exists] = await file.exists();
  if (!exists) {
    console.warn(`  ⚠ icon not uploaded: ${iconPath}`);
    return null;
  }
  const encoded = encodeURIComponent(iconPath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encoded}?alt=media`;
}

async function main() {
  const db = getFirestore();
  const bucket = getStorage().bucket();
  console.log(`[seed_badges] bucket = ${bucket.name}`);

  let seeded = 0;
  let withIcon = 0;
  for (const badge of BADGES) {
    const iconUrl = await resolveIconUrl(bucket, badge.iconPath);
    if (iconUrl) withIcon++;

    const payload = {
      name: badge.name,
      description: badge.description,
      tier: badge.tier,
      iconPath: badge.iconPath,
      iconUrl,
      pointReward: badge.pointReward,
      isSecret: badge.isSecret,
      repeatable: badge.repeatable,
      criteriaType: badge.criteriaType,
    };
    if (badge.rankPosition) payload.rankPosition = badge.rankPosition;

    await db.doc(`badge_definitions/${badge.id}`).set(payload, {merge: true});
    seeded++;
    console.log(`  ✓ ${badge.id} ${iconUrl ? "(icon ok)" : "(no icon)"}`);
  }

  console.log(
      `[seed_badges] seeded ${seeded} definitions, ${withIcon} with iconUrl.`,
  );
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error("[seed_badges] failed:", err);
      process.exit(1);
    });
