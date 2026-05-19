const express = require("express");
const cors = require("cors");

const authMiddleware = require("./middleware/auth");
const loggerMiddleware = require("./middleware/logger");
const errorHandler = require("./middleware/error");

const healthRouter = require("./routes/health");
const quizAnalyticsRouter = require("./routes/quiz_analytics");
const usersRouter = require("./routes/users");
const topicsRouter = require("./routes/topics");
const materialsRouter = require("./routes/materials");
const attachmentsRouter = require("./routes/attachments");
const classesRouter = require("./routes/classes");
const {joinRouter, memberRouter} = require("./routes/memberships");
const quizzesRouter = require("./routes/quizzes");
const quizAiRouter = require("./routes/quiz_ai");

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

app.use("/classes", quizAnalyticsRouter);
app.use("/classes", topicsRouter);
app.use("/classes", materialsRouter);
app.use("/classes", attachmentsRouter);
app.use("/classes", quizzesRouter);
app.use("/classes", classesRouter);
app.use("/classes", memberRouter);
app.use("/memberships", joinRouter);
app.use("/users", usersRouter);
app.use("/quizzes", quizAiRouter);

// Centralized error handler harus terdaftar paling akhir.
app.use(errorHandler);

module.exports = app;
