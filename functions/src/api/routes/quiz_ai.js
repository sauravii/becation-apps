const {Router} = require("express");
const {getFirestore} = require("firebase-admin/firestore");

const router = Router();

// Mount: app.use("/quizzes", quizAiRouter)
//   POST /quizzes/generate-ai
//
// Migrasi dari Genkit Callable ke Express + direct Gemini API. Drop ~857 deps
// Genkit untuk cold-start lebih ringan. API key tetap via defineSecret di
// `functions/index.js` (Cloud Functions runtime feature, bukan Genkit-specific).

// Stable channel — preview identifier sudah di-retire Google.
// Display name di docs/UI tetap "Gemini 3.1 Flash Lite".
const MODEL = "gemini-3.1-flash-lite";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;

async function verifyIsTeacher(uid) {
  const userDoc = await getFirestore().doc(`users/${uid}`).get();
  if (!userDoc.exists || userDoc.data().role !== "teacher") {
    const err = new Error("Hanya guru yang dapat menggunakan fitur ini.");
    err.status = 403;
    throw err;
  }
}

function buildSystemPrompt({optionsCount, difficulty, language}) {
  return `Anda adalah asisten pembuat kuis pendidikan yang ahli.
Tugas Anda adalah membuat soal pilihan ganda berdasarkan topik yang diminta.
PERATURAN:
1. "correctIndex" adalah angka (0-based index) jawaban benar.
2. JUMLAH PILIHAN: Setiap soal harus memiliki tepat ${optionsCount} pilihan jawaban.
3. KHUSUS 2 PILIHAN: Jika user meminta 2 pilihan, buatlah dalam format Benar/Salah (True/False).
4. TINGKAT KESULITAN: Buat soal pada level "${difficulty}" — Easy (konsep dasar, recall langsung), Medium (aplikasi konsep ke skenario standar), Hard (penalaran multi-langkah, perbandingan, edge case), Expert (sintesis, analisis mendalam, skenario kompleks dunia nyata).
5. BAHASA OUTPUT: Tulis SEMUA soal, pilihan jawaban, dan teks dalam bahasa "${language}". Jangan campur bahasa.`;
}

const RESPONSE_SCHEMA = {
  type: "ARRAY",
  items: {
    type: "OBJECT",
    properties: {
      question: {type: "STRING"},
      options: {type: "ARRAY", items: {type: "STRING"}},
      correctIndex: {type: "INTEGER"},
    },
    required: ["question", "options", "correctIndex"],
  },
};

router.post("/generate-ai", async (req, res, next) => {
  try {
    await verifyIsTeacher(req.user.uid);

    const {prompt, count, optionsCount, difficulty, language} = req.body || {};
    if (!prompt || !count || !optionsCount) {
      return next({
        status: 400,
        message: "Prompt, jumlah soal, dan jumlah pilihan harus diisi.",
      });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return next({status: 500, message: "GEMINI_API_KEY not configured"});
    }

    const finalDifficulty = difficulty || "Medium";
    const finalLanguage = language || "English";

    const body = {
      contents: [
        {
          role: "user",
          parts: [{
            text: `Buatkan ${count} soal pilihan ganda dengan ${optionsCount} pilihan setiap soalnya, berdasarkan: ${prompt}`,
          }],
        },
      ],
      systemInstruction: {
        parts: [{
          text: buildSystemPrompt({
            optionsCount,
            difficulty: finalDifficulty,
            language: finalLanguage,
          }),
        }],
      },
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: RESPONSE_SCHEMA,
      },
    };

    const response = await fetch(`${GEMINI_URL}?key=${apiKey}`, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("[generateQuizAI] Gemini API error:", errText);
      return next({
        status: 502,
        message: "Terjadi kesalahan pada server AI.",
      });
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      return next({
        status: 502,
        message: "AI tidak menghasilkan output yang valid.",
      });
    }

    let questions;
    try {
      questions = JSON.parse(text);
    } catch (parseErr) {
      console.error("[generateQuizAI] Parse error:", parseErr, "raw:", text);
      return next({
        status: 502,
        message: "AI menghasilkan output yang tidak valid.",
      });
    }

    res.json({success: true, data: questions});
  } catch (err) {
    next(err);
  }
});

module.exports = router;
