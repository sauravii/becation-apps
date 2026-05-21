# Firebase Rules & Data Flow Guide

Dokumentasi lengkap tentang Firestore Security Rules, Storage Rules, dan bagaimana data mengalir di aplikasi Becation.

---

## Daftar Isi
1. [Firestore Security Rules](#firestore-security-rules)
2. [Storage Security Rules](#storage-security-rules)
3. [Data Flow: Cara Kerja Tiap Fitur](#data-flow)
4. [Struktur Firestore Collections](#struktur-firestore-collections)
5. [Struktur Firebase Storage](#struktur-firebase-storage)

---

## Firestore Security Rules

File: `firestore.rules`

### Helper Functions

```
isAuth()          — Cek apakah user sudah login (request.auth != null)
isOwner(userId)   — Cek apakah UID user yang request == userId
getUserRole()     — Ambil role user dari Firestore doc /users/{uid}
isClassMember()   — Cek apakah user punya doc di /classes/{id}/members/{uid}
isClassTeacher()  — Cek apakah user adalah teacher di kelas tersebut
isAdmin()         — Cek apakah role user di /users/{uid} == "admin" (v1.4.0)
```

### Rules per Collection

#### `/users/{userId}`
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Semua user login | Untuk cek role, search user by email |
| **create** | Pemilik UID | User hanya bisa buat doc sendiri (saat register) |
| **update** | Pemilik ATAU teacher | User update profile sendiri, teacher bisa update role user lain |

#### `/users/{userId}/badges/{badgeId}` (v1.4.0)
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Semua user login | Publik dalam app — supaya bisa tampil di leaderboard / profile orang lain |
| **write** | **No one** (Cloud Functions only) | Award badge dilakukan via trigger / endpoint, admin SDK bypass rules |

#### `/users/{userId}/points_log/{logId}` (v1.4.0)
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Pemilik ATAU admin | Audit trail point — sensitif, jangan publik |
| **write** | **No one** | Cloud Functions only |

#### `/users/{userId}/material_completion/{materialId}` (v1.4.0)
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Pemilik saja | Internal cache untuk track attachment yang sudah di-click |
| **write** | **No one** | Cloud Functions only (via endpoint `attachments/:aid/access`) |

#### `/users/{userId}/material_access/{logId}` (v1.4.0)
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Pemilik saja | Log akses material (untuk badge Studyaholic) |
| **write** | **No one** | Cloud Functions only |

#### `/users/{userId}/topic_progress/{progressKey}` (v1.4.0)
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Pemilik saja | Internal cache progress topic (untuk badge Flash) |
| **write** | **No one** | Cloud Functions only |

#### `/users/{userId}/quiz_streaks/{classId}` (v1.4.0)
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Pemilik saja | Cache 3 quiz terakhir (untuk badge Straight-A Crusader) |
| **write** | **No one** | Cloud Functions only |

#### `/classes/{classId}`
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **get** | Semua user login | Bisa baca detail satu class (untuk join class, lihat class code) |
| **list** | Teacher pemilik ATAU member | Teacher query by `teacherId`, student query by `memberIds` |
| **create** | Teacher saja | Hanya teacher yang bisa buat kelas baru |
| **update** | Teacher, member, ATAU student yang sedang join | Teacher edit class info, member update (leave), student join (tambah UID ke memberIds) |
| **delete** | Teacher saja | Hanya teacher pemilik yang bisa hapus kelas |

**Catatan penting tentang `update` rule:**
```
(request.auth.uid in request.resource.data.memberIds &&
 !(request.auth.uid in resource.data.memberIds))
```
Ini mengizinkan student yang **sedang join** untuk update `memberIds` dan `studentCount`. Tanpa rule ini, student tidak bisa join karena batch write (create member + update class) dievaluasi sebelum member doc ada.

#### `/classes/{classId}/members/{memberId}`
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Member kelas ATAU pemilik doc | Member lihat daftar anggota, user cek keanggotaan sendiri |
| **create** | Teacher ATAU pemilik doc | Teacher tambah member, student join (buat doc sendiri) |
| **delete** | Teacher ATAU pemilik doc | Teacher remove student, student leave class (hapus doc sendiri) |

#### `/classes/{classId}/topics/{topicId}`
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Member kelas | Semua anggota bisa lihat topics |
| **write** | Teacher saja | Hanya teacher yang bisa CRUD topic |

#### `/classes/{classId}/materials/{materialId}`
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Member kelas | Semua anggota bisa lihat materials |
| **write** | Teacher saja | Hanya teacher yang bisa CRUD material |

#### `/classes/{classId}/materials/{materialId}/attachments/{attachmentId}`
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Member kelas | Semua anggota bisa lihat & download attachments |
| **write** | Teacher saja | Hanya teacher yang bisa tambah/hapus attachment |

#### `/classes/{classId}/rank_snapshots/{snapshotId}` (v1.4.0)
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Member kelas | Audit ranking snapshot mingguan, untuk transparency |
| **write** | **No one** (Cloud Functions only) | Cron `weeklyRankSnapshot` yg menulis |

#### `/badge_definitions/{badgeId}` (v1.4.0)
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Semua user login | Metadata badge global (name, description, iconUrl) — perlu untuk display |
| **write** | **No one** (admin SDK only) | Di-seed via `functions/scripts/seed_badge_definitions.js` |

#### `/class_codes/{code}`
| Operasi | Siapa yang boleh | Penjelasan |
|---|---|---|
| **read** | Semua user login | Student perlu baca untuk join class by code |
| **create** | Teacher saja | Code dibuat otomatis saat teacher buat kelas |
| **delete** | Teacher saja | Code dihapus saat teacher hapus kelas |

---

## Storage Security Rules

File: `storage.rules`

### Path Structure
```
/classes/{classId}/materials/{materialId}/{timestamp}_{filename}    — material attachments
/badges/{badgeId}.png                                                 — badge icons (v1.4.0)
```

### Rules

#### `/classes/{classId}/materials/{materialId}/**`
| Operasi | Siapa yang boleh | Batasan |
|---|---|---|
| **read** | Semua user login | Bisa download/lihat file |
| **write** | Semua user login | Max 25MB per file |

#### `/badges/{badgeFile}` (v1.4.0)
| Operasi | Siapa yang boleh | Batasan |
|---|---|---|
| **read** | **Public** (no auth required) | Supaya `Image.network(iconUrl)` di Flutter bisa load tanpa header |
| **write** | **No one** | Upload manual via Firebase Console / Storage SDK admin |

### Catatan
- Material attachments: write belum dibatasi ke teacher saja (semua user login bisa upload). Bisa diperketat nanti jika diperlukan, tapi membutuhkan cross-service rules yang lebih kompleks.
- Limit 25MB per file sudah cukup untuk dokumen, presentasi, dan gambar. Untuk video perlu dinaikkan.
- Badge icons: public read aman karena hanya gambar metadata (tidak sensitif). Seed script `seed_badge_definitions.js` construct URL pattern `https://firebasestorage.googleapis.com/v0/b/{bucket}/o/badges%2F{id}.png?alt=media`.

---

## Data Flow

### Teacher Buat Kelas Baru
```
1. Teacher klik + di halaman Classes
2. Isi form: subject, title, description, color
3. ClassService.createClass():
   a. Generate class code unik (6 karakter) → cek di collection class_codes
   b. Batch write:
      - Buat doc di /classes/{classId}
      - Buat doc di /classes/{classId}/members/{teacherUid} (role: teacher)
      - Buat doc di /class_codes/{code} → { classId: ... }
4. Kelas muncul di dashboard dan halaman Classes (StreamBuilder realtime)
```

### Student Join Kelas
```
1. Student klik + di halaman Classes → masukkan class code
2. ClassService.joinClassByCode():
   a. Baca /class_codes/{code} → dapat classId
   b. Cek apakah sudah member (/classes/{classId}/members/{studentUid})
   c. Batch write:
      - Buat doc di /classes/{classId}/members/{studentUid} (role: student)
      - Update /classes/{classId}: increment studentCount, tambah UID ke memberIds
3. Kelas muncul di dashboard dan halaman Classes student
```

### Teacher Upload Attachment (File)
```
1. Teacher buka material detail → klik tombol attach (FAB)
2. Pilih tipe: File/Image/Link
3. Jika File/Image:
   a. Request storage permission (Android)
   b. Buka file picker → pilih file
   c. AttachmentService.uploadFileAttachment():
      - Upload ke Firebase Storage: /classes/{classId}/materials/{materialId}/{timestamp}_{filename}
      - Dapat download URL
      - Simpan metadata ke Firestore: /classes/.../materials/.../attachments/{attachmentId}
        Fields: title, type, url, fileSize, fileExtension, storagePath, createdAt
4. Jika Link:
   - Langsung simpan URL ke Firestore (tanpa upload ke Storage)
5. Attachment muncul di list (StreamBuilder realtime)
```

### Teacher Hapus Kelas
```
1. Teacher klik titik tiga di class card → Delete
2. Dialog countdown 5 detik (barrierDismissible: false)
3. ClassService.deleteClassWithContents():
   a. Baca semua subcollections: members, materials, topics
   b. Untuk setiap material: baca subcollection attachments
   c. Batch delete: semua attachments + materials + topics + members
   d. Hapus doc di /class_codes/{classCode}
   e. Hapus doc di /classes/{classId}
4. Catatan: file di Firebase Storage TIDAK otomatis terhapus.
   (Perlu Cloud Functions untuk cleanup, atau manual delete dari console)
```

### Teacher Hapus Topic
```
1. Teacher klik titik tiga di topic header → Delete
2. Dialog countdown 5 detik
3. TopicService.deleteTopicWithMaterials():
   a. Query semua materials yang punya topicId == topic yang dihapus
   b. Batch delete: semua materials + topic doc
4. Catatan: attachments di dalam materials dan file di Storage
   TIDAK otomatis terhapus (sama seperti delete class)
```

### Student Leave Kelas
```
1. Student klik titik tiga di header class detail → Leave Class
2. Dialog countdown 3 detik
3. ClassService.leaveClass():
   a. Batch:
      - Hapus doc /classes/{classId}/members/{studentUid}
      - Update /classes/{classId}: decrement studentCount, remove UID dari memberIds
4. Kelas hilang dari dashboard dan halaman Classes student
```

---

## Struktur Firestore Collections

```
/users/{userId}
  ├── email: string
  ├── displayName: string
  ├── role: "student" | "teacher"
  ├── createdAt: timestamp
  └── lastLogin: timestamp

/classes/{classId}
  ├── title: string
  ├── subject: string
  ├── description: string
  ├── colorValue: int
  ├── classCode: string (6 karakter)
  ├── teacherId: string (UID)
  ├── teacherName: string
  ├── studentCount: int
  ├── memberIds: string[] (array of UIDs)
  ├── createdAt: timestamp
  ├── updatedAt: timestamp
  │
  ├── /members/{userId}
  │     ├── role: "teacher" | "student"
  │     ├── displayName: string
  │     ├── email: string
  │     └── joinedAt: timestamp
  │
  ├── /topics/{topicId}
  │     ├── title: string
  │     ├── order: int
  │     ├── createdAt: timestamp
  │     └── createdBy: string (UID)
  │
  └── /materials/{materialId}
        ├── title: string
        ├── description: string
        ├── topicId: string
        ├── topicTitle: string
        ├── createdAt: timestamp
        ├── createdBy: string (UID)
        │
        └── /attachments/{attachmentId}
              ├── title: string
              ├── type: "link" | "file" | "image"
              ├── url: string (download URL atau link)
              ├── fileSize: string ("2.5 MB", "Web Link")
              ├── fileExtension: string ("pdf", "pptx", "")
              ├── storagePath: string? (path di Storage, null untuk link)
              └── createdAt: timestamp

/class_codes/{code}
  └── classId: string
```

---

## Struktur Firebase Storage

```
/classes/{classId}/materials/{materialId}/
  ├── 1714000000000_slide_chapter1.pptx
  ├── 1714000000001_homework.pdf
  └── 1714000000002_diagram.png
```

Format nama file: `{timestamp}_{original_filename}`
- Timestamp mencegah nama file bentrok
- Original filename disimpan untuk referensi

---
