const express = require("express");
const cors = require("cors");

const authMiddleware = require("./middleware/auth");
const loggerMiddleware = require("./middleware/logger");
const errorHandler = require("./middleware/error");

const healthRouter = require("./routes/health");

const app = express();

app.use(cors({origin: true}));
app.use(express.json());
app.use(loggerMiddleware);

// Public routes (no auth).
// Catatan path: function ini di-export sebagai `api`, jadi segment "/api"
// di URL public datang dari NAMA function — Express cuma handle path setelahnya.
// Full URL contoh: https://<region>-<project>.cloudfunctions.net/api/health
app.use("/health", healthRouter);

// Semua route setelah ini wajib login (verify Firebase ID token).
app.use(authMiddleware);

// Route protected akan didaftarkan di sini saat Step 2 (Quiz Analytics).
// app.use("/classes", quizAnalyticsRouter);

// Centralized error handler harus terdaftar paling akhir.
app.use(errorHandler);

module.exports = app;
