const {Router} = require("express");

const router = Router();

/**
 * GET /api/health
 * Public endpoint. Buat smoke test kalau Express sudah live.
 */
router.get("/", (req, res) => {
  res.json({
    status: "ok",
    uptime: process.uptime(),
    version: "1.0.0",
  });
});

module.exports = router;
