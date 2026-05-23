const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");

// Inisialisasi Admin SDK sekali di sini
initializeApp();

// Cost control: cap concurrent instances
setGlobalOptions({ maxInstances: 10 });

const geminiApiKey = defineSecret("GEMINI_API_KEY");

/**
 * Import modul-modul function
 */
const quizScoring = require("./src/quiz_scoring");
const apiApp = require("./src/api");

/**
 * Exports
 *
 * - submitQuizAttempt: Callable, scoring tetap aman di server (anti-cheat).
 * - api: Express app yang handle semua REST endpoint (CRUD + analytics + AI gen).
 *   Secret GEMINI_API_KEY di-declare di sini supaya `process.env.GEMINI_API_KEY`
 *   tersedia di route `/quizzes/generate-ai`.
 */
exports.submitQuizAttempt = quizScoring.submitQuizAttempt;
exports.api = onRequest(
  { region: "us-central1", secrets: [geminiApiKey] },
  apiApp,
);
