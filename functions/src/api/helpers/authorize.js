const {getFirestore} = require("firebase-admin/firestore");

/**
 * Pastikan `uid` adalah teacher dari class `classId`.
 * - Throw 404 kalau class doc tidak ada.
 * - Throw 403 kalau teacherId di doc tidak match `uid`.
 * Return data class doc kalau lolos.
 */
async function assertTeacherOfClass(uid, classId) {
  const classSnap = await getFirestore().doc(`classes/${classId}`).get();
  if (!classSnap.exists) {
    const err = new Error("Class not found");
    err.status = 404;
    throw err;
  }
  const data = classSnap.data();
  if (data.teacherId !== uid) {
    const err = new Error("Not the teacher of this class");
    err.status = 403;
    throw err;
  }
  return data;
}

/**
 * Pastikan `uid` punya role "admin" di users/{uid}.
 * - Throw 403 kalau bukan admin (doc absent atau role !== "admin").
 * Return user doc data kalau lolos.
 */
async function assertAdmin(uid) {
  const userSnap = await getFirestore().doc(`users/${uid}`).get();
  if (!userSnap.exists || userSnap.data().role !== "admin") {
    const err = new Error("Admin role required");
    err.status = 403;
    throw err;
  }
  return userSnap.data();
}

/**
 * Pastikan `uid` adalah teacher OR member-student dari class `classId`.
 * - Throw 404 kalau class doc tidak ada.
 * - Throw 403 kalau bukan teacher dan bukan member.
 * Pakai field cache `memberIds` di class doc — fallback ke sub-doc kalau
 * array absen (data lama / migrasi).
 * Return { isTeacher, classData } kalau lolos.
 */
async function assertMemberOfClass(uid, classId) {
  const db = getFirestore();
  const classSnap = await db.doc(`classes/${classId}`).get();
  if (!classSnap.exists) {
    const err = new Error("Class not found");
    err.status = 404;
    throw err;
  }
  const data = classSnap.data();
  if (data.teacherId === uid) {
    return {isTeacher: true, classData: data};
  }
  const memberIds = Array.isArray(data.memberIds) ? data.memberIds : null;
  if (memberIds && memberIds.includes(uid)) {
    return {isTeacher: false, classData: data};
  }
  // Fallback — array mungkin belum ter-populate untuk kelas lama.
  const memberSnap = await db.doc(`classes/${classId}/members/${uid}`).get();
  if (memberSnap.exists) {
    return {isTeacher: false, classData: data};
  }
  const err = new Error("Not a member of this class");
  err.status = 403;
  throw err;
}

/**
 * Pastikan `uid` sama dengan `targetUid` ATAU `uid` adalah admin.
 * - Throw 403 kalau bukan self dan bukan admin.
 */
async function assertSelfOrAdmin(uid, targetUid) {
  if (uid === targetUid) return;
  await assertAdmin(uid);
}

module.exports = {
  assertTeacherOfClass,
  assertAdmin,
  assertMemberOfClass,
  assertSelfOrAdmin,
};
