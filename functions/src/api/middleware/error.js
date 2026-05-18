/**
 * Centralized error handler.
 * Route boleh pakai `next(err)` atau throw — `express-async-errors`
 * tidak dipakai, jadi tiap async route handler wajib try/catch sendiri.
 *
 * Convention: lempar object dengan `.status` (HTTP code) dan `.message`.
 * Contoh: `next({status: 403, message: "Forbidden"})`.
 */
// eslint-disable-next-line no-unused-vars
module.exports = function errorHandler(err, req, res, _next) {
  const status = err.status || err.statusCode || 500;
  const message = err.message || "Internal server error";

  if (status >= 500) {
    console.error(`[api] ${status} ${req.method} ${req.originalUrl}`, err);
  }

  res.status(status).json({error: message});
};
