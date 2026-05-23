const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");

// Inisialisasi Admin SDK sekali di sini
initializeApp();

// Cost control: cap concurrent instances. Region default ke asia-southeast2
// (Jakarta) supaya co-located dengan Firestore — minimize latency.
setGlobalOptions({ maxInstances: 10, region: "asia-southeast2" });

const geminiApiKey = defineSecret("GEMINI_API_KEY");

/**
 * Import modul-modul function
 */
const quizScoring = require("./src/quiz_scoring");
const apiApp = require("./src/api");
const quizAttemptTrigger = require("./src/triggers/on_quiz_attempt");
const scheduledRanking = require("./src/triggers/scheduled_ranking");

/**
 * Exports
 *
 * - submitQuizAttempt: Callable, scoring tetap aman di server (anti-cheat).
 * - api: Express app yang handle semua REST endpoint (CRUD + analytics + AI gen).
 *   Secret GEMINI_API_KEY di-declare di sini supaya `process.env.GEMINI_API_KEY`
 *   tersedia di route `/quizzes/generate-ai`.
 * - onQuizAttemptCreated: Firestore trigger, award point + badges.
 * - weeklyRankSnapshot / dailySemesterCloseCheck: scheduled cron.
 */
exports.submitQuizAttempt = quizScoring.submitQuizAttempt;
exports.api = onRequest(
  { region: "asia-southeast2", secrets: [geminiApiKey] },
  apiApp,
);
exports.onQuizAttemptCreated = quizAttemptTrigger.onQuizAttemptCreated;
exports.weeklyRankSnapshot = scheduledRanking.weeklyRankSnapshot;
exports.dailySemesterCloseCheck = scheduledRanking.dailySemesterCloseCheck;
