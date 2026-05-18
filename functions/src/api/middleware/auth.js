const {getAuth} = require("firebase-admin/auth");

/**
 * Verify Firebase ID token dari header `Authorization: Bearer <token>`.
 * Kalau valid, decoded token (uid, email, name, dll) di-attach ke `req.user`.
 */
module.exports = async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({error: "Missing Bearer token"});
  }

  const token = header.substring("Bearer ".length).trim();
  if (!token) {
    return res.status(401).json({error: "Empty Bearer token"});
  }

  try {
    req.user = await getAuth().verifyIdToken(token);
    return next();
  } catch (err) {
    return res.status(401).json({error: "Invalid or expired token"});
  }
};
