
# Rencana Task KosFinder

Task disusun per vertical slice. Setiap slice wajib tetap dapat dijalankan di perangkat Android; mulai Slice 1, aplikasi dapat dicoba dengan daftar kosong atau data pada proyek Supabase pengembangan. Gunakan konfigurasi lokal `--dart-define`, bukan kredensial dalam source. Data uji hanya untuk pengujian dan tidak dimasukkan sebagai data awal migrasi.

Package `provider` dan `supabase_flutter` mengikuti ARCHITECTURE.md. Perubahan dependency dilakukan setelah persetujuan pengguna. Status task diperbarui sesuai hasil pengerjaan dan verifikasi.

## Slice 1 — Daftar dan detail kos (wajib)

| ID | Tujuan | User Story dan Acceptance Criteria terkait | File yang boleh diubah | Cara menguji | Status |
|---|---|---|---|---|---|
| T01 | Verifikasi skema tabel kos dan RLS yang sudah diterapkan pada Stage 3 tanpa menerapkan ulang migrasi. | US01-AC1, US07-AC1, US08-AC3, US09-AC2, US10-AC2; AC: pembacaan publik berhasil dan operasi tulis lintas pemilik ditolak. | Tidak ada file yang diubah; verifikasi merujuk `supabase/migrations/001_init.sql` yang hanya dibaca. | Periksa tabel, constraint, grants, dan policy yang sudah ada; uji anon dapat membaca serta dua akun tidak dapat mengubah/menghapus data silang. | DONE |
| T02 | Siapkan bootstrap Flutter, inisialisasi Supabase dari dart-define, dan fondasi Provider. | US01-AC3, US04-AC3; AC: konfigurasi dapat dibaca saat aplikasi mulai dan kegagalan koneksi ditangani sebagai error. | `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, `lib/config/supabase_config.dart`, `test/`. | Jalankan `flutter analyze`, `flutter test`, lalu buka aplikasi Android dengan konfigurasi pengembangan; pastikan tidak ada kredensial tetap di source. | TODO |
| T03 | Buat model kos dan Repository untuk membaca daftar serta detail dari Supabase. | US01-AC1–AC3, US04-AC1–AC3; AC: data wajib dipetakan, fasilitas/foto kosong didukung, dan error tidak berubah menjadi data lama. | `lib/models/kos.dart`, `lib/repositories/kos_repository.dart`, `test/repositories/`. | Uji pemetaan data, nilai opsional, hasil kosong, dan error koneksi dengan test; verifikasi baca menggunakan data uji pengembangan. | TODO |
| T04 | Tampilkan daftar kos melalui Provider dan Screen, termasuk state memuat, kosong, dan gagal. | US01-AC1–AC3; AC: nama dan harga tampil, hasil kosong serta kegagalan koneksi memiliki pesan yang jelas. | `lib/providers/kos_provider.dart`, `lib/screens/kos_list_screen.dart`, `test/`. | Jalankan widget test untuk hasil berisi/kosong/error; pada koneksi stabil, ukur daftar hingga 1.000 kos dan pastikan hasil tampil maksimal 3 detik. | TODO |
| T05 | Tambahkan navigasi dari daftar ke detail kos dan tampilkan informasi wajib serta bagian opsional. | US04-AC1–AC3; AC: detail menampilkan nama, alamat, harga, deskripsi; fasilitas/foto opsional dan error ditangani dengan jelas. | `lib/screens/kos_list_screen.dart`, `lib/screens/kos_detail_screen.dart`, `lib/providers/kos_provider.dart`, `test/`. | Jalankan widget test untuk detail lengkap, fasilitas/foto kosong, dan error; pada koneksi stabil, pastikan detail tampil maksimal 3 detik. | TODO |
| T06 | Tambahkan halaman About dengan identitas wajib dan verifikasi Slice 1 dapat dicoba sebagai aplikasi Android. | Tidak ada US khusus (kewajiban AGENTS.md §7); AC: About menampilkan `2415051038 - Gena Anggarani`. | `lib/screens/about_screen.dart`, `lib/main.dart`, `test/`. | Widget test identitas, jalankan `flutter analyze` dan `flutter test`, lalu `flutter run` pada Android; coba daftar kosong dan detail dengan data uji. | TODO |

## Slice 2 — Pencarian dan filter harga maksimum (wajib)

| ID | Tujuan | User Story dan Acceptance Criteria terkait | File yang boleh diubah | Cara menguji | Status |
|---|---|---|---|---|---|
| T07 | Tambahkan pencarian kos berdasarkan nama atau alamat pada daftar. | US02-AC1–AC3; AC: kecocokan nama/alamat tampil, hasil kosong dan koneksi gagal diberi pesan yang tepat. | `lib/repositories/kos_repository.dart`, `lib/providers/kos_provider.dart`, `lib/screens/kos_list_screen.dart`, `test/`. | Test pencarian nama, alamat, tidak cocok, dan error koneksi; ukur pencarian hingga 1.000 kos pada koneksi stabil (maksimal 3 detik). | TODO |
| T08 | Tambahkan filter batas harga maksimum dan pastikan Slice 2 tetap dapat dijalankan. | US03-AC1–AC3; AC: hanya harga ≤ batas tampil, hasil kosong dan error ditangani; tidak menambah filter harga minimum. | `lib/repositories/kos_repository.dart`, `lib/providers/kos_provider.dart`, `lib/screens/kos_list_screen.dart`, `test/`. | Uji harga Rp800.000/Rp1.500.000 dengan batas Rp1.000.000 dan hasil kosong/error; ukur hingga 1.000 kos (maksimal 3 detik), lalu jalankan aplikasi pada Android. | TODO |

## Slice 3 — Registrasi dan login pemilik (wajib)

| ID | Tujuan | User Story dan Acceptance Criteria terkait | File yang boleh diubah | Cara menguji | Status |
|---|---|---|---|---|---|
| T09 | Implementasikan registrasi pemilik melalui Supabase Auth. | US05-AC1–AC3; AC: akun valid dibuat, email/input tidak valid ditolak, dan kegagalan koneksi tidak dilaporkan sebagai sukses. | `lib/repositories/auth_repository.dart`, `lib/providers/auth_provider.dart`, `lib/screens/register_screen.dart`, `test/`. | Uji registrasi berhasil, email terpakai/input tidak valid, serta koneksi gagal pada proyek pengembangan. | TODO |
| T10 | Implementasikan login pemilik dan state sesi terautentikasi. | US06-AC1–AC2; AC: kredensial benar membuka sesi, kredensial salah menolak akses dengan pesan jelas. | `lib/repositories/auth_repository.dart`, `lib/providers/auth_provider.dart`, `lib/screens/login_screen.dart`, `test/`. | Uji login berhasil dan gagal; pastikan password tidak disimpan sebagai teks biasa oleh aplikasi. | TODO |
| T11 | Hubungkan state sesi dengan navigasi pengelolaan tanpa membatasi fitur baca anonim, lalu verifikasi Slice 3 dapat dijalankan. | US06-AC3, US10-AC1, US10-AC3; AC: tanpa login, daftar/pencarian/detail tetap terbuka dan tindakan pengelolaan meminta login. | `lib/main.dart`, `lib/providers/auth_provider.dart`, `lib/screens/`, `test/`. | Widget test akses anonim dan gate pengelolaan; jalankan registrasi, login, dan baca publik pada Android. | TODO |

## Slice 4 — Tambah, ubah, dan hapus kos milik sendiri (wajib)

| ID | Tujuan | User Story dan Acceptance Criteria terkait | File yang boleh diubah | Cara menguji | Status |
|---|---|---|---|---|---|
| T12 | Tampilkan halaman pengelolaan yang memuat kos milik pemilik login dan menyediakan alur tambah/edit. | US07-AC1, US10-AC1; AC: pemilik melihat daftar miliknya dan pengguna anonim diarahkan untuk login sebelum mengelola. | `lib/repositories/kos_repository.dart`, `lib/providers/kos_provider.dart`, `lib/screens/owner_kos_screen.dart`, `test/`. | Uji daftar dengan dua akun; verifikasi tiap sesi hanya menampilkan daftar pengelolaannya sendiri dan fitur baca publik tetap tersedia. | TODO |
| T13 | Buat form tambah kos dengan validasi dan penyimpanan sebagai pemilik yang sedang login. | US07-AC1–AC3, US10-AC2; AC: nama/alamat/deskripsi wajib, harga > 0, fasilitas/foto opsional, dan owner_id sesuai auth.uid(). | `lib/models/kos.dart`, `lib/repositories/kos_repository.dart`, `lib/providers/kos_provider.dart`, `lib/screens/kos_form_screen.dart`, `test/`. | Uji input valid/tidak valid dan koneksi gagal; pastikan insert tanpa sesi/owner_id cocok ditolak serta kos tersimpan dapat dibaca setelah aplikasi dibuka ulang. | TODO |
| T14 | Buat form edit dan pembaruan kos milik sendiri dengan validasi yang sama seperti tambah. | US08-AC1–AC3; AC: perubahan valid tersimpan, data wajib/harga tidak valid ditolak, dan RLS menolak perubahan kos akun lain. | `lib/repositories/kos_repository.dart`, `lib/providers/kos_provider.dart`, `lib/screens/kos_form_screen.dart`, `test/`. | Uji edit valid/tidak valid dan coba ubah kos akun lain menggunakan akun kedua; pastikan data pemilik pertama tidak berubah. | TODO |
| T15 | Tambahkan penghapusan permanen kos milik sendiri dan verifikasi Slice 4 dapat dijalankan. | US09-AC1–AC3, US10-AC2; AC: kos sendiri hilang dari daftar, kos akun lain tetap ada, dan error koneksi tidak dilaporkan sebagai sukses. | `lib/repositories/kos_repository.dart`, `lib/providers/kos_provider.dart`, `lib/screens/owner_kos_screen.dart`, `test/`. | Uji hapus dengan dua akun, pastikan RLS menolak hapus lintas pemilik; jalankan `flutter analyze`, `flutter test`, dan aplikasi pada Android. | TODO |

## Slice 5 — Ketersediaan kamar (BONUS/OPSIONAL)

**Deferred — tidak ada task implementasi pada scope saat ini.** PRD secara eksplisit mengecualikan status ketersediaan/kos penuh. Slice ini hanya dapat direncanakan setelah perubahan PRD disetujui; tidak ada ID atau status TODO karena belum menjadi task.

## Catatan scope

Logout tidak dimasukkan sebagai task karena belum ditetapkan dalam PRD atau ARCHITECTURE.md. Slice 3 saat ini hanya mencakup registrasi, login, dan gate akses pengelolaan sesuai scope yang disetujui. Proses build APK release dan pengunggahan ke GitHub Release ditangani pada Stage 7, bukan dalam daftar task vertical slice ini.
