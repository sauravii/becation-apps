const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// Cost control: cap concurrent instances so a runaway loop or attack
// can't run up the bill.
setGlobalOptions({maxInstances: 10});

/**
 * Submit a quiz attempt. Scoring happens server-side so students never see
 * the answer keys.
 *
 * Input:  { classId, quizId, answers: { [questionId]: number } }
 * Output: { score, correct, total, passed, attemptNumber }
 */
exports.submitQuizAttempt = onCall(
    {region: "us-central1"}, // Default
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

      // 1. Verify class membership
      const memberRef = db.doc(`classes/${classId}/members/${studentId}`);
      const memberSnap = await memberRef.get();
      if (!memberSnap.exists) {
        throw new HttpsError("permission-denied", "Bukan member kelas ini");
      }

      // 2. Get quiz metadata
      const quizRef = db.doc(`classes/${classId}/quizzes/${quizId}`);
      const quizSnap = await quizRef.get();
      if (!quizSnap.exists) {
        throw new HttpsError("not-found", "Quiz tidak ditemukan");
      }
      const quiz = quizSnap.data();

      // 3. Enforce attempt limit
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

      // 4. Read questions + answer keys (admin SDK bypasses Firestore rules)
      const questionsSnap = await quizRef
          .collection("questions")
          .orderBy("order")
          .get();
      const keysSnap = await quizRef.collection("answer_keys").get();
      const keys = {};
      keysSnap.docs.forEach((doc) => {
        keys[doc.id] = doc.data().correctIndices ?? [];
      });

      // 5. Score
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

      // 6. Snapshot the quiz state at submission time so future edits
      // to questions/answer_keys don't break past attempt review.
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

      // 7. Persist attempt
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

      // 8. Build response. Only reveal correctAnswers if quiz opted in.
      const response = {score, correct, total, passed, attemptNumber};
      if (quiz.showAnswer === true) {
        response.correctAnswers = keys; // {questionId: [correctIndices]}
      }
      return response;
    },
);
