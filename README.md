# KosFinder

KosFinder adalah aplikasi Android untuk mencari tempat kos dan melihat informasi kos seperti alamat, harga bulanan, deskripsi, fasilitas, dan foto jika tersedia. Data disimpan di Supabase.

## Fitur utama

- Melihat daftar kos tanpa harus login.
- Mencari kos berdasarkan nama atau alamat.
- Memfilter daftar dengan batas harga maksimum per bulan.
- Melihat detail kos, termasuk fasilitas dan foto jika tersedia.
- Registrasi dan login untuk pemilik kos.
- Melihat kos milik akun dan menghapus kos setelah konfirmasi.

> Catatan kondisi implementasi: form tambah/edit kos tersedia di source, tetapi belum terhubung ke navigasi aplikasi. Karena itu alur tambah dan edit belum dapat digunakan dari UI.

## Menjalankan aplikasi

Persyaratan: Flutter SDK yang sesuai dengan batas SDK di `pubspec.yaml`, Android SDK, dan proyek Supabase untuk pengembangan.

1. Pastikan migrasi `supabase/migrations/001_init.sql` telah diterapkan pada proyek Supabase.
2. Dari root repository, jalankan:

   ```sh
   flutter pub get
   flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
   ```
3. Ganti placeholder dengan URL proyek dan publishable/anon key proyek Supabase yang sesuai. Jangan menggunakan atau memasukkan `service_role` key ke aplikasi.

## Konfigurasi Supabase

Aplikasi membaca konfigurasi melalui compile-time `--dart-define`:

- `SUPABASE_URL`: URL proyek Supabase.
- `SUPABASE_ANON_KEY`: publishable/anon key untuk akses aplikasi klien. Key ini bukan pengganti kebijakan Row Level Security (RLS).

Pastikan RLS pada tabel `public.kos` aktif. Pembacaan daftar/detail tersedia untuk pengguna anonim maupun terautentikasi; operasi tulis harus dibatasi kepada pemilik data oleh RLS. Jangan menyimpan password, token, atau key rahasia di source code, dokumentasi, atau Git.

## Batasan versi 1

- Platform yang ditargetkan adalah Android.
- Tidak mencakup pembayaran online, chat, rating, ulasan, verifikasi identitas, status ketersediaan kamar, atau data kos awal dari sistem.
- Pencarian hanya berdasarkan nama/alamat dan filter hanya menyediakan batas harga maksimum.
- Fasilitas dan foto bersifat opsional; foto menggunakan URL, tanpa fitur unggah berkas.
- Data dan akun memerlukan konfigurasi proyek Supabase; aplikasi tidak menyediakan data demo awal.
