const {Router} = require("express");
const {getFirestore} = require("firebase-admin/firestore");

const router = Router();

const ALLOWED_ROLES = new Set(["student", "teacher"]);

function mapUser(doc) {
  const data = doc.data();
  return {
    uid: doc.id,
    email: data.email ?? null,
    displayName: data.displayName ?? "",
    role: data.role ?? "student",
    createdAt: data.createdAt?.toDate?.().toISOString?.() ?? null,
    lastLogin: data.lastLogin?.toDate?.().toISOString?.() ?? null,
  };
}

/**
 * GET /api/users/me — profile user yang lagi login.
 */
router.get("/me", async (req, res, next) => {
  try {
    const snap = await getFirestore().doc(`users/${req.user.uid}`).get();
    if (!snap.exists) {
      return next({status: 404, message: "User profile not found"});
    }
    res.json(mapUser(snap));
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/users?email=<email> — list semua user.
 * Kalau query `email` diisi, filter exact match.
 */
router.get("/", async (req, res, next) => {
  try {
    const db = getFirestore();
    const emailFilter = (req.query.email || "").trim();

    const query = emailFilter
      ? db.collection("users").where("email", "==", emailFilter)
      : db.collection("users").orderBy("email");

    const snap = await query.get();
    res.json({users: snap.docs.map(mapUser)});
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/users/:uid — profile user spesifik.
 */
router.get("/:uid", async (req, res, next) => {
  try {
    const {uid} = req.params;
    const snap = await getFirestore().doc(`users/${uid}`).get();
    if (!snap.exists) {
      return next({status: 404, message: "User not found"});
    }
    res.json(mapUser(snap));
  } catch (err) {
    next(err);
  }
});

/**
 * PATCH /api/users/:uid/role — update role user.
 * Body: { role: "student" | "teacher" }.
 */
router.patch("/:uid/role", async (req, res, next) => {
  try {
    const {uid} = req.params;
    const role = req.body?.role;
    if (!ALLOWED_ROLES.has(role)) {
      return next({
        status: 400,
        message: `Invalid role. Allowed: ${[...ALLOWED_ROLES].join(", ")}`,
      });
    }

    const ref = getFirestore().doc(`users/${uid}`);
    const snap = await ref.get();
    if (!snap.exists) {
      return next({status: 404, message: "User not found"});
    }

    await ref.update({role});
    const updated = await ref.get();
    res.json(mapUser(updated));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
