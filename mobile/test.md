# Dokumentasi Functional Testing — Hadirin Mobile

## 1. Cakupan test yang sudah ada (tidak dibuat ulang)

| Area | Lokasi | Skenario yang sudah tercakup |
|---|---|---|
| Admin — data | `test/functional/data/admin/` | Login/profile admin, master data CRUD (tahun ajaran, mata kuliah), jadwal service & repository (filter, konflik ruangan/dosen/kelas), whitelist service (list + create/delete), jadwal options service |
| Mahasiswa — data | `test/functional/data/mhs/` | Login/register lokal, live API login, live CRUD mahasiswa & pengajuan, live E2E UI, schedule reminder |
| Dosen — data | `test/functional/data/dosen/` | Login, register, email case-insensitive, duplicate email, change password (+ error) |
| Admin — UI | `test/functional/pages/admin/` | Login & navbar, profil & email dialog, tahun ajaran, jadwal list/filter/create, validasi form jadwal, konflik lokal, pencarian picker |
| Mahasiswa — UI | `test/functional/pages/mhs/` | Login/register validation, NIM duplikat, face-scan redirect, change password, surat/absensi, profil |
| Dosen — UI | `test/functional/pages/dosen/` | Login/register validation, profil & logout, change password |
| E2E Appium | `test/appium/**` | 73 spesifikasi: admin login, registrasi/login dosen & mahasiswa, presensi, QR, geolocation, face recognition, dll. |

**Gap yang ditemukan:** gate whitelist saat registrasi mahasiswa belum diuji; mutasi/error service whitelist admin baru sebatas list/create/delete; kegagalan form jadwal (validasi sesi, error backend, gagal memuat opsi) belum ada.

## 2. Skenario baru yang ditambahkan

| # | File | Skenario | Asserti fungsional |
|---|---|---|---|
| 1 | `test/functional/data/mhs/student_whitelist_check_test.dart` | NIM belum di-whitelist | `whitelisted == false`, `canRegister == false` |
| 2 | `test/functional/data/mhs/student_whitelist_check_test.dart` | NIM sudah terdaftar | `whitelisted == true`, `registered == true`, `canRegister == false` |
| 3 | `test/functional/data/mhs/student_whitelist_check_test.dart` | NIM whitelist & belum daftar | `canRegister == true` lewat `checkNim()` dan `isNimAllowedToRegister()` |
| 4 | `test/functional/data/admin/admin_whitelist_nim_mutation_test.dart` | `list(search:)` | query `search` ter-trim dikirim, data & status hasil dipetakan |
| 5 | `test/functional/data/admin/admin_whitelist_nim_mutation_test.dart` | `update()` | `PUT /admin/whitelist-nim/{nimLama}`, body NIM baru, hasil ter-map |
| 6 | `test/functional/data/admin/admin_whitelist_nim_mutation_test.dart` | Conflict 409 | `AdminRemoteApiException` status 409 + pesan detail backend |
| 7 | `test/functional/pages/admin/jadwal_form_failure_test.dart` | Sesi selesai < sesi mulai | error "Harus setelah sesi mulai.", POST tidak dikirim |
| 8 | `test/functional/pages/admin/jadwal_form_failure_test.dart` | Backend 409 saat simpan | detail konflik tampil, tidak ada notifikasi sukses, form tetap terbuka |
| 9 | `test/functional/pages/admin/jadwal_form_failure_test.dart` | Gagal memuat opsi form | banner error tampil, Simpan disabled, **Coba lagi** memulihkan form |

## 3. File yang dibuat / diubah

| File | Status | Keterangan |
|---|---|---|
| `test/functional/data/mhs/student_whitelist_check_test.dart` | Baru | 3 test gate whitelist registrasi |
| `test/functional/data/admin/admin_whitelist_nim_mutation_test.dart` | Baru | 3 test mutasi & error handling |
| `test/functional/pages/admin/jadwal_form_failure_test.dart` | Baru | 3 test validasi & kegagalan form |
| `test/functional/data/mhs/live_student_crud_test.dart` | Diubah | Perbaikan fixture: NIM uji di-whitelist sebelum create, dibersihkan setelahnya |

Kode aplikasi tidak diubah. Test lama lainnya tidak diubah.

## 4. Hasil eksekusi

| Perintah | Hasil |
|---|---|
| `dart format --output=none --set-exit-if-changed` (file test) | Clean |
| `flutter analyze` | No issues found |
| `flutter test` (3 file baru) | **9/9 Passed** |
| `flutter test test/functional/data/mhs/live_student_crud_test.dart` | **6/6 Passed** |
| `flutter test` (seluruh suite) | **109/109 Passed** |

## 5. Bug / kendala

| Item | Penyebab | Status |
|---|---|---|
| `live_student_crud_test.dart` gagal di baris 78 (DELETE) | NIM uji `2341999999` belum masuk `whitelist_nim`, sehingga CREATE ditolak backend (409). Assertion CREATE gagal, lalu `finally` ikut gagal saat DELETE (404) dan menutupi error utama | **Fixed**: test menyiapkan whitelist via admin API sebelum CREATE, menghapus mahasiswa lalu whitelist di `finally`, dan assertion DELETE dipindah ke dalam `try` agar error utama tidak tertutupi |
| `WhitelistNimPage` belum punya service injectable | Test UI-level tidak bisa ditambahkan tanpa mengubah implementasi aplikasi | Sesuai ketentuan, kode aplikasi tidak diubah; coverage dilakukan di lapisan service |
| Bug aplikasi baru | Tidak ditemukan yang menghalangi pengujian | — |
