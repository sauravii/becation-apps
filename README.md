# Becation

**Better Education** — aplikasi pembelajaran berbasis kelas untuk guru dan siswa. Dibangun dengan Flutter + Firebase.

Becation memungkinkan guru membuat kelas digital, mengorganisir materi per topik, dan membagikannya ke siswa melalui kode kelas unik. Siswa cukup memasukkan kode untuk bergabung dan langsung mengakses seluruh materi pembelajaran.

---

## Fitur Utama

### Autentikasi
- Daftar & login dengan **email + password**
- **Login dengan Google** (Google Sign-In)
- Lupa password via email
- Pemilihan role saat registrasi: **Guru** atau **Siswa**

### Untuk Guru

**Dashboard**
- Greeting personal sesuai waktu (pagi/siang/malam)
- Ringkasan jumlah kelas yang dikelola
- Kalender interaktif
- Daftar kelas aktif dengan quick-access

**Manajemen Kelas**
- Buat kelas baru dengan: judul, mata pelajaran, deskripsi, warna kustom
- **Kode kelas otomatis** 6 karakter (unik) untuk dibagikan ke siswa
- Lihat semua kelas yang dibuat
- Lihat jumlah siswa di tiap kelas secara real-time

**Detail Kelas (3 tab)**
- **Class**: informasi kelas & preview materi terbaru
- **Classwork**: kelola topik & materi pembelajaran
- **People**: daftar seluruh siswa yang tergabung

**Materi Pembelajaran**
- Buat **topik** sebagai pengelompok materi (misal: "Bab 1 - Pengenalan")
- Tambah **materi** di bawah topik dengan judul & deskripsi
- Upload **attachment** beragam tipe: PDF, presentasi, dokumen, gambar, atau link eksternal
- Edit & hapus materi
- Urutan topik otomatis terjaga

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
- **Class**: info kelas & materi terbaru dari guru
- **Classwork**: semua topik & materi yang bisa diakses
- **People**: lihat guru pengampu & teman sekelas

**Akses Materi**
- Buka materi pembelajaran yang dibagikan guru
- Download/buka attachment (PDF, presentasi, gambar, link)
- Tampilan read-only (tidak bisa edit)

**Settings**
- Lihat profil pribadi
- Leave class (keluar dari kelas)
- Sign out

### Fitur Sistem

- **Real-time sync** — perubahan dari guru langsung muncul di perangkat siswa tanpa refresh
- **Offline-aware** — Firestore cache otomatis menyimpan data terakhir
- **Responsive design** — menyesuaikan berbagai ukuran layar (flutter_screenutil)
- **Role-based access** — siswa tidak bisa modifikasi materi, hanya guru pemilik kelas
- **Atomic operations** — pembuatan kelas, join, dan leave dijalankan sebagai transaksi sehingga data selalu konsisten

---

## Tech Stack

| Layer | Teknologi |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| State | StreamBuilder + Firestore Streams |
| UI Helper | flutter_screenutil, flutter_svg |
| Utility | url_launcher, google_sign_in |

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
│   └── navigation/        # Bottom nav item
├── services/              # Business logic & Firestore ops
│   ├── user_service.dart
│   ├── class_service.dart
│   ├── topic_service.dart
│   ├── material_service.dart
│   └── attachment_service.dart
└── models/                # Data class
    ├── class_model.dart
    ├── topic_model.dart
    ├── material_model.dart
    ├── attachment_model.dart
    └── member_model.dart
```