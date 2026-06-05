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

**Detail Kelas (4 tab)**

- **Class**: banner info kelas (subject, judul, deskripsi) & toggle Quiz/Material untuk lihat list materi
- **Classwork**: kelola topik & materi pembelajaran (tampil tanggal upload di setiap item)
- **People**: kode kelas di atas, daftar anggota kelas dengan foto profil + nama (fresh-fetch dari user doc, auto-update kalau user edit profil), select mode untuk remove student (centang & hapus sekaligus)
- **Leaderboard**: ranking student per-class (1 kelas = 1 leaderboard independent). Sort by per-class point, podium top 3 + list, pull-to-refresh di area ungu

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
- **Quiz Analytics** (teacher-only): dashboard per-quiz dengan 3 tab — agregasi server-side via Express:
  - **Summary**: total attempts, average / min / max score, **pass rate per-student** (best score basis), **failed participants**, **participation rate** (X/Y students), **passing grade**, distribusi skor (bar chart), insight hardest/easiest question.
  - **Per-Question**: correct rate per soal + color threshold, distribusi pemilihan jawaban (donut chart), tap question → jump ke edit page, filter chips untuk drill-down.
  - **Attempts**: list paginated dengan PASS/FAIL pill, attempt number, correct count, sort by submitted date atau score.

**Profile (Teacher)**

- Lihat profil (foto, nama, email, role badge)
- Edit nama + upload foto profil (dengan circular crop preview)
- Stat ringkas: classes created, materials uploaded
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

**Detail Kelas (4 tab)**

- **Class**: detail kelas (nama guru, subject, jumlah siswa, deskripsi) + learning map visualisasi progress
- **Classwork**: semua topik, materi, dan kuis yang bisa diakses (tampil tanggal upload)
- **People**: lihat guru pengampu (school icon) & teman sekelas dengan foto + nama fresh
- **Leaderboard**: ranking kelas — student bisa lihat posisinya vs teman se-class. Pull-to-refresh di area ungu untuk update manual

**Pengerjaan Kuis**

- Kerjakan kuis dengan antarmuka yang bersih dan fokus.
- Indikator waktu sisa (countdown timer) dengan auto-submit ketika habis.
- **Server-side Scoring**: Penilaian otomatis via Cloud Callable `submitQuizAttempt` (region `asia-southeast2`). Jawaban dikirim ke server, dicocokkan dengan answer keys (tidak pernah expose ke client kecuali `showAnswer === true`), score dihitung server-side — anti-cheat.
- Hasil Kuis: Skor langsung muncul, status lulus/gagal, dan review mode (lihat kunci jawaban) kalau guru aktifkan `showAnswer`.
- **Snackbar feedback**: muncul "Quiz completed! Score: X" segera setelah submit.
- **Badge popup**: kalau quiz attempt trigger badge baru (Flash kalau first to complete topic, Straight-A Crusader untuk 3 quiz ≥90 berturut, Comeback Kid untuk recovery dari fail ke pass), modal dialog "Congrats! 🎉 You earned a new badge" muncul setelah result dialog — image badge, name, +X points chip, tombol "Awesome!" untuk close (barrier-dismiss disabled supaya gak ke-tutup gak sengaja).

**Akses Materi**

- Buka materi pembelajaran yang dibagikan guru
- **Gambar** dibuka di full screen viewer dalam app (pinch-to-zoom)
- **File** (PDF, PPTX, dll) dibuka di browser untuk download
- **Link** dibuka di browser atau app yang sesuai
- **Auto-track completion**: setiap attachment yang di-click direkam server-side. Saat SEMUA attachment di material sudah di-akses → material "complete", award +5 point + cek Flash badge (kalau topic complete) + cek Studyaholic badge (kalau akses jam 22+). Snackbar + popup feedback muncul saat just-completed.
- Tampilan read-only (tidak bisa edit)

**Kelola Keanggotaan**

- Leave class dari menu di dalam halaman kelas (dengan countdown konfirmasi 3 detik)
- Sign out

**Profile (Student)**

- Lihat profil (foto, nama, email)
- Edit nama + upload foto profil (image_cropper circular preview, validate ≤5 MB)
- 4 stat card: **Day Streak**, **Total Points**, **Class Joined**, **Materials Completed**
- **Total Points** tappable → **Points Breakdown Page**: list per-class point earned (scrollable, sorted desc, tampil class color + title + subject), plus total card hero
- Badges grid: 6 preview (2 row), tombol "More" untuk show all. Locked = grayscale, secret unearned = masked ('?????'). Modal detail per badge dengan difficulty + status pill + description
- Sign out

### Untuk Admin

- Role `admin` di-seed manual di Firestore (`users/{uid}.role = "admin"`) — belum ada self-serve endpoint
- **Manage Roles Page**: promote/demote user antara `student ↔ teacher` via PATCH `/users/:uid/role` (TODO: assertAdmin enforcement)
- Manual grant/revoke badge ke user via API (POST/DELETE `/users/:uid/badges`)
- ⚠️ Belum ada UI admin dashboard yang dedicated — semua via API direct call

### Gamification

- **Point system**:
  - Quiz: `quizScoreReward(score, isFirstSubmitter)` (bonus first submitter + perfect score)
  - Material complete: +5 point (semua attachment di-click)
  - Daily streak: bonus harian via `POST /api/users/me/ping` (called on splash + login)
  - Badge earned: bonus per badge tier
- **Per-class tracking** (v1.5.0): point disimpan di **dua tempat**:
  - `users/{uid}.point` (global total → ditampilkan di profile stat card)
  - `classes/{cid}/members/{uid}.point` (per-class → digunakan untuk leaderboard tiap kelas)
- **Local leaderboard**: tiap kelas punya leaderboard independent (1 kelas = 1 ranking). Sort by per-class point desc, teacher di-exclude
- **Streak**: daily login bonus, milestone Overachiever badge tiap 28 hari
- **Badge system**: ~8 badges dengan tier (Easy/Medium/Hard/Reward + Secret). Auto-award via Firestore trigger `onQuizAttemptCreated` + endpoint `material_progress` + `awardBadge` shared helper
- **Badge announcement popup**: muncul setelah submit quiz / complete material kalau ada badge baru di-earn (modal dialog dengan icon + name + "+X points" chip, tombol "Awesome!" untuk close)
- **Snackbar feedback**: quiz/material completion langsung tampil snackbar score/point earned (instant feedback sambil tunggu trigger async)

### Fitur Sistem

- **AI-Powered** — Integrasi model bahasa besar (LLM) Gemini untuk asisten pembuatan konten kuis.
- **Real-time sync** — perubahan dari guru langsung muncul di perangkat siswa tanpa refresh
- **Offline-aware** — Firestore cache otomatis menyimpan data terakhir
- **Backend Hybrid (~75% Express, ~25% Firebase native)** — Express dominan handle semua CRUD (14 entitas), gamifikasi, quiz analytics, AI generation, dan badge/leaderboard system (~50 endpoint REST). Firebase native dipertahankan untuk hal yang memang Firebase paling cocok: Authentication flow, Storage bytes upload (file & foto profile), realtime Firestore stream untuk UI live (members, materials, dll), serta 1 Callable `submitQuizAttempt` (anti-cheat scoring server-side). Tiap path native punya alasan teknis defensible (auth token plumbing, body limit 32MB Functions, no realtime di Express, anti-cheat scoring).
- **Cloud Functions Architecture** — 5 functions di-deploy di `asia-southeast2` (Jakarta): 1 HTTPS Express (`api`) + 1 Callable (`submitQuizAttempt`) + 1 Firestore trigger (`onQuizAttemptCreated`) + 2 scheduled cron (`weeklyRankSnapshot`, `dailySemesterCloseCheck`).
- **Responsive design** — menyesuaikan berbagai ukuran layar (flutter_screenutil)
- **Role-based access** — siswa tidak bisa modifikasi materi, hanya guru pemilik kelas
- **Atomic operations** — pembuatan kelas, join, leave, dan award point/badge dijalankan sebagai batch transaction
- **Tap to dismiss keyboard** — tap di area kosong mana pun untuk menutup keyboard
- **Countdown confirmation** — aksi destructive (hapus kelas, topik, leave) dilindungi countdown timer

---

## Tech Stack

| Layer        | Teknologi                                                                     |
| ------------ | ----------------------------------------------------------------------------- |
| Framework    | Flutter 3.x                                                                   |
| Language     | Dart, Node.js (Backend)                                                       |
| AI Model     | Gemini 3.1 Flash Lite (Google AI Studio)                                      |
| AI Wiring    | Direct REST call ke `generativelanguage.googleapis.com` via `fetch()` + `responseSchema` (structured output) — migrasi dari Genkit untuk kurangi cold-start |
| Backend      | Node.js on Firebase Cloud Functions Gen 2 (region asia-southeast2 / Jakarta)  |
| REST API     | Express + cors, mounted as single HTTPS function `api` (~50 endpoint, 14 entitas) |
| Auth         | Firebase Authentication (email/password + Google Sign-In)                     |
| Database     | Cloud Firestore                                                               |
| Storage      | Firebase Storage (attachment file + profile photo)                            |
| State        | StreamBuilder + Firestore Streams (realtime UI)                               |
| Charts       | fl_chart (bar + donut chart Quiz Analytics)                                   |
| HTTP Client  | http (REST calls ke Express API dengan Bearer Firebase ID token)              |
| Photo        | image_cropper (1:1 circular crop) + file_picker untuk profile photo upload    |
| UI Helper    | flutter_screenutil, flutter_svg, intl                                         |
| Utility      | url_launcher, google_sign_in, permission_handler                              |
| Build Tools  | flutter_launcher_icons (generate Android + iOS launcher icon dari `lib/assets/icons/logo.png`) |

---

## Struktur Project

```text
lib/
├── main.dart                       # Entry point (MaterialApp + ScreenUtil)
├── spashscreen.dart                # Splash, role routing, streak ping
├── assets/icons/                   # Logo aplikasi (source untuk launcher icon)
├── components/                     # Widget reusable
│   ├── buttons/                    # Tombol kustom (auth, dll)
│   ├── cards/                      # Card UI (kelas, materi, kuis, attachment)
│   ├── forms/                      # Input field form
│   ├── gamification/               # Badge card, badge_award_popup (modal congrats!), gamification_feedback (snackbar + badge popup), points_chip, streak_indicator
│   ├── map/                        # Komponen peta pembelajaran
│   ├── member_avatar.dart          # CircleAvatar + skeleton + auto-refresh fresh photo/name
│   ├── navigation/                 # Bottom nav item
│   ├── skeleton_circle_avatar.dart # Shimmer loading skeleton + NetworkCircleAvatar helper
│   └── viewers/                    # Image viewer (full screen pinch zoom)
├── features/
│   ├── auth/                       # Login, register, forgot password, verify
│   ├── home/                       # Halaman utama & role routing
│   ├── profile/                    # ProfileEditPage (nama + photo upload), PointsBreakdownPage
│   ├── student/                    # Dashboard, kuis attempt, materi detail, profile, leaderboard, class detail
│   └── teacher/                    # Dashboard, kuis create/edit (AI & Manual), analytics, materi detail, profile, class detail
├── models/
│   ├── attachment_model.dart
│   ├── class_model.dart
│   ├── material_model.dart         # formattedTime + formattedDate
│   ├── member_model.dart
│   ├── question_model.dart
│   ├── quiz_model.dart
│   └── topic_model.dart
└── services/                       # Business logic & API/Firebase operations (pure backend, no UI)
    ├── api_client.dart             # HTTP client dengan auto-attach Firebase ID token
    ├── attachment_service.dart
    ├── auth_service.dart           # FirebaseAuth + GoogleSignIn wrapper (login/register/logout/reset)
    ├── badges_service.dart         # /users/:uid/badges
    ├── class_service.dart
    ├── leaderboard_service.dart    # /classes/:cid/leaderboard + close-semester
    ├── material_progress_service.dart  # POST attachment access tracking
    ├── material_service.dart
    ├── media_service.dart          # File picker + image cropper (profile photo)
    ├── points_service.dart         # /points, /points/log, /points/by-class, /me/ping
    ├── quiz_analytics_service.dart
    ├── quiz_service.dart           # Quiz CRUD + submitQuizAttempt callable + AI generate + analytics reads
    ├── topic_service.dart
    └── user_service.dart           # User CRUD + photo upload + role + displayName sync

functions/                          # Backend (Node.js on Firebase Functions Gen 2, asia-southeast2)
├── index.js                        # Exports: submitQuizAttempt (Callable), api (Express HTTPS), onQuizAttemptCreated (trigger), weeklyRankSnapshot + dailySemesterCloseCheck (cron)
└── src/
    ├── quiz_scoring.js             # Callable submitQuizAttempt (anti-cheat server-side scoring)
    ├── api/
    │   ├── index.js                # Express app factory (cors, json, auth, error handler)
    │   ├── middleware/             # auth (Firebase ID token verify), request_logger, error_handler
    │   ├── helpers/                # authorize (admin / teacher-of-class / member-of-class / self-or-admin), pagination
    │   └── routes/                 # 14 entitas: health, users, classes, memberships, topics, materials, attachments, quizzes, quiz_analytics, quiz_ai (Gemini direct), points (incl by-class v1.5.0), badges, leaderboard, material_progress
    ├── shared/                     # point_rules, badge_definitions, badge_award (member.point increment kalau context.classId), topic_progress
    └── triggers/
        ├── on_quiz_attempt.js      # onCreate attempts → award point (users + members), straight_a / comeback_kid / flash checks
        └── scheduled_ranking.js    # weeklyRankSnapshot + dailySemesterCloseCheck + closeSemester helper

docs/
├── endpoints.md            # Dokumentasi semua endpoint Express + Callable + background functions
├── FIREBASE_RULES_GUIDE.md # Firestore & Storage rules guide (commit-able doc satu-satunya)
└── (lokal-only)            # CurrentTestCaseReport.md, test_scenarios.md, pkm_kc_corrections.md — gak commit per policy
```
