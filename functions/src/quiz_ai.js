const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getFirestore} = require("firebase-admin/firestore");
const {GoogleGenerativeAI} = require("@google/generative-ai");

const db = getFirestore();

/**
 * Helper untuk validasi role guru
 * @param {string} uid - User ID
 */
async function verifyIsTeacher(uid) {
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists || userDoc.data().role !== "teacher") {
    throw new HttpsError(
        "permission-denied",
        "Hanya guru yang dapat menggunakan fitur ini.",
    );
  }
}

/**
 * Function Utama untuk Generate Quiz menggunakan Gemini
 */
exports.generateQuizAI = onCall(
    {
      region: "us-central1",
      secrets: ["GEMINI_API_KEY"],
    },
    async (request) => {
      const {auth, data} = request;

      if (!auth) {
        throw new HttpsError(
            "unauthenticated",
            "Anda harus login terlebih dahulu.",
        );
      }

      await verifyIsTeacher(auth.uid);

      const {prompt, count, optionsCount} = data ?? {};
      if (!prompt || !count || !optionsCount) {
        throw new HttpsError(
            "invalid-argument",
            "Prompt, jumlah soal, dan jumlah pilihan harus diisi.",
        );
      }

      try {
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
        const model = genAI.getGenerativeModel({
          model: "gemini-3-flash-preview",
          systemInstruction: `Anda adalah asisten pembuat kuis pendidikan yang ahli.
        Tugas Anda adalah membuat soal pilihan ganda berdasarkan topik yang diminta.
        PERATURAN OUTPUT:
        1. Output HARUS dalam format JSON murni.
        2. JANGAN sertakan markdown seperti \`\`\`json ... \`\`\`.
        3. Struktur JSON harus berupa ARRAY dari OBJEK:
           [{ "question": "teks soal", "options": ["opsi A", "opsi B"], "correctIndex": 0 }]
        4. "correctIndex" adalah angka (0-based index) jawaban benar.
        5. JUMLAH PILIHAN: Setiap soal harus memiliki tepat ${optionsCount} pilihan jawaban.
        6. KHUSUS 2 PILIHAN: Jika user meminta 2 pilihan, buatlah dalam format Benar/Salah (True/False).`,
        });

        const fullPrompt = `Buatkan ${count} soal pilihan ganda dengan ${optionsCount} pilihan setiap soalnya, berdasarkan: ${prompt}`;

        const result = await model.generateContent(fullPrompt);
        const responseText = result.response.text();

        let quizData;
        try {
          const cleanJson = responseText.replace(/```json|```/g, "").trim();
          quizData = JSON.parse(cleanJson);
        } catch (e) {
          throw new HttpsError(
              "internal",
              "AI memberikan format data yang salah.",
          );
        }

        return {
          success: true,
          data: quizData,
        };
      } catch (error) {
        throw new HttpsError("internal", "Terjadi kesalahan pada server AI.");
      }
    },
);
