const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {getFirestore} = require("firebase-admin/firestore");

const apiKey = defineSecret("GEMINI_API_KEY");

const db = getFirestore();

// Swap balik ke Vertex AI:
// - getQuizFlow(): const {vertexAI} = require("@genkit-ai/google-genai");
//   plugins: [vertexAI({location: "us-central1"})]
// - MODEL = "vertexai/gemini-2.5-flash"
// - onCall config: hapus secrets: [apiKey] (Vertex pakai ADC, tanpa API key)
const MODEL = "googleai/gemini-3.1-flash-lite-preview";

// Lazy-init via dynamic require: load module @genkit-ai/* (857 deps) di module
// level bikin firebase-tools deploy introspection timeout (>10s). Defer ke
// first request, cache module-wide setelah itu — kena cold start pertama saja.
let _flow;
function getQuizFlow() {
  if (_flow) return _flow;

  const {genkit, z} = require("genkit");
  const {googleAI} = require("@genkit-ai/google-genai");
  const {enableFirebaseTelemetry} = require("@genkit-ai/firebase");

  enableFirebaseTelemetry();
  const ai = genkit({
    plugins: [googleAI()],
  });

  const QuizSchema = z.array(
      z.object({
        question: z.string(),
        options: z.array(z.string()),
        correctIndex: z.number().int().min(0),
      }),
  );

  const InputSchema = z.object({
    prompt: z.string(),
    count: z.number(),
    optionsCount: z.number(),
    difficulty: z.string().optional(),
    language: z.string().optional(),
  });

  _flow = ai.defineFlow(
      {
        name: "generateQuiz",
        inputSchema: InputSchema,
        outputSchema: QuizSchema,
      },
      async ({prompt, count, optionsCount, difficulty, language}) => {
        const finalDifficulty = difficulty ?? "Medium";
        const finalLanguage = language ?? "English";
        const {output} = await ai.generate({
          model: MODEL,
          system: `Anda adalah asisten pembuat kuis pendidikan yang ahli.
Tugas Anda adalah membuat soal pilihan ganda berdasarkan topik yang diminta.
PERATURAN:
1. "correctIndex" adalah angka (0-based index) jawaban benar.
2. JUMLAH PILIHAN: Setiap soal harus memiliki tepat ${optionsCount} pilihan jawaban.
3. KHUSUS 2 PILIHAN: Jika user meminta 2 pilihan, buatlah dalam format Benar/Salah (True/False).
4. TINGKAT KESULITAN: Buat soal pada level "${finalDifficulty}" — Easy (konsep dasar, recall langsung), Medium (aplikasi konsep ke skenario standar), Hard (penalaran multi-langkah, perbandingan, edge case), Expert (sintesis, analisis mendalam, skenario kompleks dunia nyata).
5. BAHASA OUTPUT: Tulis SEMUA soal, pilihan jawaban, dan teks dalam bahasa "${finalLanguage}". Jangan campur bahasa.`,
          prompt: `Buatkan ${count} soal pilihan ganda dengan ${optionsCount} pilihan setiap soalnya, berdasarkan: ${prompt}`,
          output: {schema: QuizSchema},
        });

        if (!output) {
          throw new Error("AI tidak menghasilkan output yang valid.");
        }
        return output;
      },
  );

  return _flow;
}

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
 * Function Utama untuk Generate Quiz menggunakan Gemini via AI Studio (Genkit).
 * Auth/role check di sini (Firebase concern), AI generation di flow (Genkit
 * concern) supaya muncul ber-nama di Genkit Monitoring dashboard.
 */
exports.generateQuizAI = onCall(
    {
      region: "us-central1",
      secrets: [apiKey],
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

      const {prompt, count, optionsCount, difficulty, language} = data ?? {};
      if (!prompt || !count || !optionsCount) {
        throw new HttpsError(
            "invalid-argument",
            "Prompt, jumlah soal, dan jumlah pilihan harus diisi.",
        );
      }

      try {
        const flow = getQuizFlow();
        const result = await flow({
          prompt,
          count,
          optionsCount,
          difficulty,
          language,
        });
        return {success: true, data: result};
      } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("[generateQuizAI]", error);
        throw new HttpsError(
            "internal",
            "Terjadi kesalahan pada server AI.",
        );
      }
    },
);
