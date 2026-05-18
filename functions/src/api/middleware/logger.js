/**
 * Log tiap request: method, path, status, duration (ms).
 * Output muncul di Cloud Functions log.
 */
module.exports = function loggerMiddleware(req, res, next) {
  const start = Date.now();
  res.on("finish", () => {
    const duration = Date.now() - start;
    console.log(
        `[api] ${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`,
    );
  });
  next();
};
