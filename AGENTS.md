
# AGENTS.md

## 1. Konteks Proyek
Proyek ini adalah KosFinder, aplikasi pencarian dan pengelolaan informasi tempat kos berbasis Flutter dan Supabase.

Dokumen acuan utama:
- `docs/PRD.md`: kebutuhan dan batasan produk.
- `docs/ARCHITECTURE.md`: rancangan arsitektur dan database.
- `docs/TASKS.md`: daftar task pengembangan.

Ikuti dokumen tersebut. Jangan menambahkan fitur di luar kebutuhan yang telah disetujui.

## 2. Aturan Kerja
- Kerjakan satu task untuk setiap permintaan.
- Jangan mengubah file di luar cakupan task yang sedang dikerjakan.
- Untuk perubahan besar, buat rencana terlebih dahulu dan tunggu persetujuan.
- Pilih solusi paling sederhana yang memenuhi kebutuhan.
- Jangan menambah, menghapus, atau mengganti package tanpa persetujuan pengguna.
- Jika ada kebutuhan atau aturan yang belum jelas, tanyakan sebelum mengimplementasikan.
- Jangan menganggap pekerjaan selesai sebelum hasilnya diperiksa.

## 3. Teknologi
Teknologi yang digunakan:
- Flutter untuk aplikasi.
- Provider untuk state management.
- Supabase untuk autentikasi dan database.

Jangan mengganti teknologi tersebut tanpa persetujuan pengguna.

## 4. Keamanan
- Jangan menulis API key, password, token, atau kredensial rahasia di dalam kode maupun dokumentasi yang masuk Git.
- URL Supabase dan anon key dikonfigurasi melalui `--dart-define`.
- `service_role` key tidak boleh digunakan atau disimpan di aplikasi Flutter.
- Hak akses data wajib ditegakkan melalui Row Level Security (RLS) di Supabase.
- Semua pengguna, termasuk pengguna anonim, boleh membaca data kos yang dipublikasikan.
- Hanya pemilik data yang boleh menambah, mengubah, dan menghapus kos miliknya sendiri.
- Jangan mengandalkan penyembunyian tombol di UI sebagai pengamanan akses.

## 5. Aturan Git
- Satu task menghasilkan satu commit.
- Pesan commit harus mencantumkan ID task yang dikerjakan jika task sudah memiliki ID.
- Jangan melakukan commit atau push tanpa persetujuan pengguna.
- Jangan memasukkan file rahasia, file sementara, atau hasil build yang tidak diperlukan ke repository.

## 6. Definition of Done
Task dinyatakan selesai jika:
- `flutter analyze` berjalan tanpa masalah.
- `flutter test` lulus.
- Aplikasi berhasil dijalankan dan diperiksa pada device.
- Perubahan sesuai dengan PRD dan arsitektur yang disetujui.
- Agen melaporkan file yang berubah, pengujian yang dilakukan, hasilnya, serta hal yang belum diuji.
- Pengguna sudah memeriksa dan menyetujui hasil pekerjaan.

## 7. Halaman About
Halaman About aplikasi wajib menampilkan identitas berikut:

**2415051038 - Gena Anggarani**

Jangan mengubah NIM atau nama tersebut.
