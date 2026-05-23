# Becation

**Better Education** — aplikasi pembelajaran berbasis kelas untuk guru dan siswa. Dibangun dengan Flutter + Firebase.

Becation memungkinkan guru membuat kelas digital, mengorganisir materi per topik, dan membagikannya ke siswa melalui kode kelas unik. Siswa cukup memasukkan kode untuk bergabung dan langsung mengakses seluruh materi pembelajaran.

---

## Fitur Utama

### Autentikasi

- Daftar & login dengan **email + password**
- **Login dengan Google** (Google Sign-In)
- Lupa password via email (link reset)
- Input nama lengkap saat registrasi

### Untuk Guru

**Dashboard**

- Greeting personal sesuai waktu (pagi/siang/malam)
- Ringkasan jumlah kelas yang dikelola
- Kalender interaktif
- Daftar kelas aktif dengan quick-access

**Manajemen Kelas**

- Buat kelas baru dengan: judul, mata pelajaran, deskripsi, warna kustom
- **Kode kelas otomatis** 6 karakter (unik) untuk dibagikan ke siswa
- Edit judul, subject, dan deskripsi kelas
- Copy class code ke clipboard
- Hapus kelas beserta seluruh isinya (dengan countdown konfirmasi 5 detik)
- Lihat jumlah siswa di tiap kelas secara real-time

**Detail Kelas (3 tab)**

- **Class**: banner info kelas (subject, judul, deskripsi) & toggle Quiz/Material untuk lihat list materi
- **Classwork**: kelola topik & materi pembelajaran
- **People**: kode kelas di atas, daftar anggota kelas, select mode untuk remove student (centang & hapus sekaligus)

**Topik & Materi**

- Buat **topik** sebagai pengelompok materi (misal: "Bab 1 - Pengenalan")
- Edit nama topik
- Hapus topik beserta semua material di dalamnya (countdown 5 detik)
- Tambah **materi** di bawah topik dengan judul & deskripsi
- Edit judul & deskripsi materi (edit mode dengan icon pensil)
- Hapus materi

**Attachment**

- Upload **file** (PDF, PPTX, DOCX, dll) ke Firebase Storage
- Upload **gambar** ke Firebase Storage
- Tambah **link** eksternal (YouTube, Google Drive, website, dll)
- Edit judul attachment
- Hapus attachment (file di Storage ikut terhapus)
- Label otomatis tipe & ukuran file (misal "PDF • 2.5 MB")

**Kuis & Evaluasi**

- **AI Quiz Generator**: Membuat kuis otomatis dalam hitungan detik menggunakan **Gemini 3.1 Flash Lite**.
- Konfigurasi AI: Pilih jumlah soal (5-20), jumlah pilihan jawaban (2-5), **tingkat kesulitan** (Easy / Medium / Hard / Expert), **bahasa output** (English / Bahasa Indonesia), dan masukkan prompt topik kuis.
- **Tipe Soal True/False**: Mendukung pembuatan soal Benar/Salah baik secara manual maupun otomatis via AI.
- **Kuis Manual**: Susun soal pilihan ganda sendiri dengan kontrol penuh atas pilihan jawaban.
- Pengaturan Kuis: Judul kuis, batas waktu (1-1440 menit / 24 jam), nilai kelulusan (passing grade 0-100%), dan batas percobaan (1-10 attempts).
- **Preview & Edit**: Guru bisa meninjau, mengubah urutan (reorder, hanya saat create), dan mengedit soal hasil AI sebelum dipublikasikan.
- **Soft-delete dengan undo**: Tap delete pada soal akan menandai (grey-out + strike-through) bukan menghapus langsung. Tap restore untuk batalkan. Save/Publish menampilkan ringkasan perubahan sebelum commit.
- **Quiz Analytics** (teacher-only): dashboard per-quiz dengan 3 tab:
  - **Summary**: total attempts, average / min / max score, pass rate, distribusi skor (bar chart).
  - **Per-Question**: correct rate per soal, distribusi pemilihan jawaban (donut chart).
  - **Attempts**: list paginated semua attempt siswa (sort by submitted date atau score).
  - Dibangun di atas Express REST API yang melakukan agregasi server-side (lebih hemat bandwidth dibanding query mentah dari client).

**Settings**

- Lihat & edit profil (nama, email)
- Manajemen role user
- Sign out

### Untuk Siswa

**Dashboard**

- Greeting personal sesuai waktu
- Statistik kelas yang diikuti
- Kalender interaktif
- Daftar kelas aktif yang langsung clickable

**Gabung Kelas**

- Masuk ke kelas dengan memasukkan **kode 6 karakter** dari guru
- Validasi otomatis: kode salah, kelas tidak ditemukan, atau sudah jadi member
- Kelas langsung muncul di dashboard setelah join

**Detail Kelas (3 tab)**

- **Class**: detail kelas (nama guru, subject, jumlah siswa, deskripsi)
- **Classwork**: semua topik, materi, dan kuis yang bisa diakses
- **People**: lihat guru pengampu & teman sekelas

**Pengerjaan Kuis**

- Kerjakan kuis dengan antarmuka yang bersih dan fokus.
- Indikator waktu sisa (countdown timer).
- **Server-side Scoring**: Penilaian otomatis yang aman dijalankan melalui **Firebase Functions** (mencegah kecurangan).
- Hasil Kuis: Skor langsung muncul, status lulus/gagal, dan melihat kunci jawaban (jika diaktifkan guru).

**Akses Materi**

- Buka materi pembelajaran yang dibagikan guru
- **Gambar** dibuka di full screen viewer dalam app (pinch-to-zoom)
- **File** (PDF, PPTX, dll) dibuka di browser untuk download
- **Link** dibuka di browser atau app yang sesuai
- Tampilan read-only (tidak bisa edit)

**Kelola Keanggotaan**

- Leave class dari menu di dalam halaman kelas (dengan countdown konfirmasi 3 detik)
- Sign out

### Fitur Sistem

- **AI-Powered** — Integrasi model bahasa besar (LLM) Gemini untuk asisten pembuatan konten kuis.
- **Real-time sync** — perubahan dari guru langsung muncul di perangkat siswa tanpa refresh
- **Offline-aware** — Firestore cache otomatis menyimpan data terakhir
- **Secure Backend** — Logika krusial (seperti penilaian kuis) dijalankan di Node.js via Firebase Functions.
- **REST API selektif** — Express dipakai khusus untuk fitur yang butuh agregasi server-side (Quiz Analytics). Fitur lain tetap pakai Direct Firestore Stream (realtime) atau HTTPS Callable (action-based) sesuai fit-nya.
- **Responsive design** — menyesuaikan berbagai ukuran layar (flutter_screenutil)
- **Role-based access** — siswa tidak bisa modifikasi materi, hanya guru pemilik kelas
- **Atomic operations** — pembuatan kelas, join, dan leave dijalankan sebagai batch transaction
- **Tap to dismiss keyboard** — tap di area kosong mana pun untuk menutup keyboard
- **Countdown confirmation** — aksi destructive (hapus kelas, topik, leave) dilindungi countdown timer

---

## Tech Stack

| Layer        | Teknologi                                                     |
| ------------ | ------------------------------------------------------------- |
| Framework    | Flutter 3.x                                                   |
| Language     | Dart, Node.js (Backend)                                       |
| AI Model     | Gemini 3.1 Flash-Lite Preview (AI Studio)                     |
| AI Framework | Genkit + Firebase Genkit Monitoring                           |
| Backend      | Node.js on Firebase Cloud Functions (Gen 2)                   |
| REST API     | Express + cors (mounted as HTTPS function `api`)              |
| Auth         | Firebase Authentication                                       |
| Database     | Cloud Firestore                                               |
| Storage      | Firebase Storage (file upload)                                |
| State        | StreamBuilder + Firestore Streams                             |
| Charts       | fl_chart (bar chart, donut chart untuk Quiz Analytics)        |
| HTTP Client  | http (REST calls ke Express API dengan Bearer ID token)       |
| UI Helper    | flutter_screenutil, flutter_svg, intl                         |
| Utility      | url_launcher, google_sign_in, file_picker, permission_handler |

---

## Struktur Project

```text
lib/
├── main.dart              # Entry point
├── spashscreen.dart       # Splash & role routing
├── assets/                # Aset statis aplikasi (gambar & ikon)
├── components/            # Widget reusable
│   ├── buttons/           # Tombol kustom
│   ├── cards/             # Card UI (kelas, materi, kuis, attachment)
│   ├── forms/             # Input field form
│   ├── map/               # Komponen peta pembelajaran
│   ├── navigation/        # Bottom nav item
│   └── viewers/           # Image viewer
├── features/              # Halaman per role & fitur
│   ├── auth/              # Login, register, forgot password, verify
│   ├── home/              # Halaman utama & manajemen role
│   ├── student/           # Dashboard, kuis, materi, settings siswa
│   └── teacher/           # Dashboard, kuis (AI & Manual), materi, guru
├── models/                # Data class
│   ├── attachment_model.dart
│   ├── class_model.dart
│   ├── material_model.dart
│   ├── member_model.dart
│   ├── question_model.dart
│   ├── quiz_model.dart
│   └── topic_model.dart
├── services/              # Business logic & Firebase operations
│   ├── attachment_service.dart
│   ├── class_service.dart
│   ├── quiz_service.dart           # Logika kuis & integrasi AI
│   ├── quiz_analytics_service.dart # REST client untuk endpoint Express analytics
│   ├── topic_service.dart
│   ├── material_service.dart
│   └── attachment_service.dart
├── models/                # Data class
│   ├── class_model.dart
│   ├── quiz_model.dart
│   ├── topic_model.dart
│   ├── material_model.dart
│   ├── attachment_model.dart
│   └── member_model.dart
functions/                 # Backend (Node.js + Genkit on Firebase Functions Gen 2)
├── src/
│   ├── quiz_ai.js                  # Genkit flow: AI Studio Gemini integration
│   ├── quiz_scoring.js             # Penilaian kuis aman (callable)
│   └── api/                        # Express REST API skeleton
│       ├── index.js                # Express app factory (cors, json, auth, error)
│       ├── middleware/             # auth (Firebase ID token), logger, error
│       ├── helpers/                # authorize (teacher-of-class check)
│       └── routes/                 # health, quiz_analytics (3 GET endpoints)
├── index.js                        # Entry point Cloud Functions
docs/
├── FIREBASE_RULES_GUIDE.md  # Dokumentasi Firestore & Storage rules
└── CHANGELOG.md             # Catatan perubahan versi aplikasi
```
