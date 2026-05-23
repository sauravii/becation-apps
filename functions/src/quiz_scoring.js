const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const db = getFirestore();

/**
 * Submit a quiz attempt.
 */
exports.submitQuizAttempt = onCall(
    {region: "asia-southeast2"},
    async (request) => {
      const {auth, data} = request;

      if (!auth) {
        throw new HttpsError("unauthenticated", "Login dulu");
      }
      const studentId = auth.uid;

      const {classId, quizId, answers} = data ?? {};
      if (!classId || !quizId || typeof answers !== "object") {
        throw new HttpsError(
            "invalid-argument",
            "classId, quizId, answers required",
        );
      }

      const memberRef = db.doc(`classes/${classId}/members/${studentId}`);
      const memberSnap = await memberRef.get();
      if (!memberSnap.exists) {
        throw new HttpsError("permission-denied", "Bukan member kelas ini");
      }

      const quizRef = db.doc(`classes/${classId}/quizzes/${quizId}`);
      const quizSnap = await quizRef.get();
      if (!quizSnap.exists) {
        throw new HttpsError("not-found", "Quiz tidak ditemukan");
      }
      const quiz = quizSnap.data();

      const attemptLimit = quiz.attemptLimit ?? 1;
      const existing = await quizRef
          .collection("attempts")
          .where("studentId", "==", studentId)
          .get();
      if (existing.size >= attemptLimit) {
        throw new HttpsError(
            "resource-exhausted",
            "Attempt limit sudah habis",
        );
      }

      const questionsSnap = await quizRef
          .collection("questions")
          .orderBy("order")
          .get();
      const keysSnap = await quizRef.collection("answer_keys").get();
      const keys = {};
      keysSnap.docs.forEach((doc) => {
        keys[doc.id] = doc.data().correctIndices ?? [];
      });

      let correct = 0;
      const total = keysSnap.size;
      for (const [qId, correctIndices] of Object.entries(keys)) {
        const studentAnswer = answers[qId];
        if (
          typeof studentAnswer === "number" &&
          correctIndices.includes(studentAnswer)
        ) {
          correct++;
        }
      }
      const score = total > 0 ? Math.round((correct / total) * 100) : 0;
      const passed = score >= (quiz.passingGrade ?? 0);
      const attemptNumber = existing.size + 1;

      const questionSnapshot = questionsSnap.docs.map((doc) => {
        const d = doc.data();
        return {
          id: doc.id,
          type: d.type ?? "multiple_choice",
          question: d.question ?? "",
          options: d.options ?? [],
          correctIndices: keys[doc.id] ?? [],
        };
      });

      const studentName =
        memberSnap.data().displayName ?? auth.token?.name ?? "";
      await quizRef.collection("attempts").add({
        studentId,
        studentName,
        answers,
        score,
        correct,
        total,
        passed,
        attemptNumber,
        questionSnapshot,
        completedAt: FieldValue.serverTimestamp(),
      });

      const response = {score, correct, total, passed, attemptNumber};
      if (quiz.showAnswer === true) {
        response.correctAnswers = keys;
      }
      return response;
    },
);
