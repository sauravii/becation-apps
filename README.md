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
- **Class**: kode kelas, informasi kelas & preview materi terbaru
- **Classwork**: kelola topik & materi pembelajaran
- **People**: daftar anggota kelas, select mode untuk remove student (centang & hapus sekaligus)

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
- **Classwork**: semua topik & materi yang bisa diakses
- **People**: lihat guru pengampu & teman sekelas

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

- **Real-time sync** — perubahan dari guru langsung muncul di perangkat siswa tanpa refresh
- **Offline-aware** — Firestore cache otomatis menyimpan data terakhir
- **Responsive design** — menyesuaikan berbagai ukuran layar (flutter_screenutil)
- **Role-based access** — siswa tidak bisa modifikasi materi, hanya guru pemilik kelas
- **Atomic operations** — pembuatan kelas, join, dan leave dijalankan sebagai batch transaction
- **Tap to dismiss keyboard** — tap di area kosong mana pun untuk menutup keyboard
- **Countdown confirmation** — aksi destructive (hapus kelas, topik, leave) dilindungi countdown timer

---

## Tech Stack

| Layer | Teknologi |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage (file upload) |
| State | StreamBuilder + Firestore Streams |
| UI Helper | flutter_screenutil, flutter_svg |
| Utility | url_launcher, google_sign_in, file_picker, permission_handler |

---

## Struktur Project

```
lib/
├── main.dart              # Entry point
├── spashscreen.dart       # Splash & role routing
├── features/              # Halaman per role
│   ├── auth/              # Login, register, forgot password
│   ├── student/           # Dashboard, kelas, materi, settings siswa
│   └── teacher/           # Dashboard, kelas, materi, settings guru
├── components/            # Widget reusable
│   ├── cards/             # Card UI (kelas, materi, topik, attachment)
│   ├── forms/             # Input field & button
│   ├── navigation/        # Bottom nav item
│   └── viewers/           # Image viewer
├── services/              # Business logic & Firebase operations
│   ├── user_service.dart
│   ├── class_service.dart
│   ├── topic_service.dart
│   ├── material_service.dart
│   └── attachment_service.dart
├── models/                # Data class
│   ├── class_model.dart
│   ├── topic_model.dart
│   ├── material_model.dart
│   ├── attachment_model.dart
│   └── member_model.dart
docs/
└── FIREBASE_RULES_GUIDE.md  # Dokumentasi Firestore & Storage rules
```
