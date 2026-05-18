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

module.exports = {assertTeacherOfClass};
