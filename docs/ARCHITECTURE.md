# Rencana Arsitektur KosFinder

Rancangan versi pertama ditujukan untuk Android dan hanya mencakup kebutuhan dalam PRD.

## A. Gambaran Arsitektur

KosFinder menggunakan alur **Screen - Provider - Repository - Supabase**:

- **Screen** menampilkan informasi dan meneruskan tindakan pengguna tanpa mengakses database secara langsung.
- **Provider** mengelola state tampilan, memanggil Repository, dan memberi tahu Screen ketika hasil berubah.
- **Repository** menangani permintaan baca, autentikasi, serta perubahan data ke Supabase.
- **Supabase** menangani autentikasi, PostgreSQL, dan penegakan Row Level Security (RLS).

Alur data: Screen → Provider → Repository → Supabase. Hasil atau kesalahan dikembalikan melalui Repository dan Provider ke Screen. Supabase memeriksa RLS untuk setiap operasi tulis. Microservice dan cache tidak diperlukan.

## B. Layar dan Navigasi

- **Daftar kos:** halaman awal, dilengkapi pencarian berdasarkan nama/alamat dan filter harga maksimum.
- **Detail kos:** menampilkan informasi lengkap kos yang dipilih.
- **Login dan registrasi:** digunakan pemilik untuk mengakses pengelolaan kos.
- **Daftar kos milik sendiri:** menampilkan kos yang dikelola pemilik.
- **Form tambah dan edit:** digunakan untuk menambahkan atau mengubah informasi kos.
- **About:** menampilkan identitas **2415051038 - Gena Anggarani**.

Pengguna anonim dapat melihat, mencari, memfilter, dan membuka detail kos. Pemilik yang login dapat membaca serta mengelola kos miliknya. RLS, bukan sekadar navigasi atau tombol, melindungi operasi tulis.

## C. Rencana Database

Database menggunakan satu tabel `public.kos`. Setiap baris merupakan kos yang dapat dibaca pengguna karena PRD tidak memerlukan status draft atau publikasi.

| Kolom | Tipe | Aturan |
|---|---|---|
| `id` | `uuid` | Primary key, default `gen_random_uuid()` |
| `owner_id` | `uuid` | Wajib, foreign key ke `auth.users(id)`, default `auth.uid()` |
| `nama` | `text` | Wajib dan tidak boleh kosong |
| `alamat` | `text` | Wajib dan tidak boleh kosong |
| `harga_bulanan` | `numeric(12,2)` | Wajib dan harus lebih dari 0 |
| `deskripsi` | `text` | Wajib dan tidak boleh kosong |
| `fasilitas` | `text` | Opsional |
| `foto_url` | `text` | Opsional, berupa tautan satu foto |
| `created_at` | `timestamptz` | Wajib, waktu pembuatan otomatis |

Tidak diperlukan tabel lain atau `updated_at` karena riwayat perubahan tidak termasuk kebutuhan. Fasilitas disimpan sebagai teks dan foto sebagai tautan; pengunggahan file tidak termasuk scope versi pertama.

## D. Akses dan Keamanan

RLS diaktifkan pada tabel `kos`.

- **SELECT:** role `anon` dan `authenticated` dapat membaca semua baris.
- **INSERT:** hanya `authenticated` yang dapat menambahkan kos dengan `owner_id` sesuai `auth.uid()`.
- **UPDATE:** hanya pemilik baris yang dapat mengubahnya. Pemeriksaan `USING` membatasi baris yang diubah, sedangkan `WITH CHECK` mencegah perubahan kepemilikan.
- **DELETE:** hanya pemilik baris yang dapat menghapusnya.

Pemilik B tidak dapat mengubah atau menghapus kos Pemilik A. Pengguna anonim tidak memiliki izin tulis. Hak akses ditegakkan di backend melalui RLS, bukan hanya dengan menyembunyikan tombol pada UI.

Aplikasi Flutter menggunakan anon key dan tidak boleh menggunakan `service_role`.

## E. Konfigurasi Supabase

URL proyek dan anon key diberikan saat menjalankan aplikasi menggunakan:

```text
--dart-define=SUPABASE_URL=<URL-proyek>
--dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Jangan menanam kredensial rahasia di source code atau repository. Anon key bukan pengganti RLS.

## F. Package yang Dibutuhkan

| Nama | Kegunaan dan alasan | User Story |
|---|---|---|
| Flutter SDK | Kerangka aplikasi Android dan UI bawaan; bukan package pub tambahan. | US01–US10 |
| `provider` | Mengelola state daftar, detail, pencarian, filter, dan pengelolaan kos. | US01–US09 |
| `supabase_flutter` | Menghubungkan aplikasi dengan autentikasi dan database Supabase. | US01–US10 |

Tidak diperlukan package tambahan untuk UI, pencarian, filter, atau routing. `pubspec.yaml` belum diubah pada tahap perencanaan.

## G. Pengujian dan Rilis

Sebelum rilis, jalankan `flutter analyze` dan `flutter test`. Uji daftar, pencarian, filter, detail, autentikasi, serta pengelolaan kos pada perangkat Android.

Pengujian keamanan harus mencakup dua akun pemilik dan pengguna anonim. Periksa juga kondisi koneksi gagal dan pastikan tidak ada kredensial rahasia yang tertanam.

Buat APK menggunakan `flutter build apk --release`, periksa hasil dan versinya, kemudian unggah APK melalui GitHub Release.
