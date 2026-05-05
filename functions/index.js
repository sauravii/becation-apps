const { setGlobalOptions } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");

// Inisialisasi Admin SDK sekali di sini
initializeApp();

// Cost control: cap concurrent instances
setGlobalOptions({ maxInstances: 10 });

/**
 * Import modul-modul function
 */
const quizScoring = require("./src/quiz_scoring");
const quizAI = require("./src/quiz_ai");

/**
 * Exports
 */
exports.submitQuizAttempt = quizScoring.submitQuizAttempt;
exports.generateQuizAI = quizAI.generateQuizAI;
