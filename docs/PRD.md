
# PRD KosFinder - Versi 1

## 1. Masalah dan Tujuan Terukur

Pencari kos kesulitan memperoleh informasi lengkap karena harga, alamat, fasilitas, dan kondisi kos tersebar di berbagai sumber. KosFinder menyediakan satu daftar kos yang dapat dicari, difilter, dan dibuka detailnya.

Tujuan versi pertama:
- Pencari dapat menemukan kos berdasarkan nama atau alamat.
- Pencari dapat membandingkan kos berdasarkan harga per bulan.
- Pemilik dapat mengelola kos miliknya melalui akun.
- Pengguna dapat mencari dan melihat detail kos tanpa akun.
- Keberhasilan diukur melalui kelengkapan data wajib pada seluruh kos yang ditampilkan, keberhasilan pengujian daftar, pencarian, filter, dan detail pada Android, serta penolakan akses pengelolaan terhadap kos milik akun lain.

## 2. Pengguna Aplikasi

- **Pencari kos:** Mahasiswa sebagai pengguna utama dan masyarakat umum. Tidak memerlukan akun.
- **Pemilik kos:** Pengguna terdaftar yang ingin menambah, mengubah, atau menghapus kos miliknya sendiri.

## 3. Scope Versi 1

### Masuk
- Melihat daftar kos.
- Mencari kos berdasarkan nama atau alamat.
- Memfilter kos berdasarkan batas harga maksimum per bulan.
- Melihat detail nama, alamat lengkap, harga, deskripsi, fasilitas, dan foto jika tersedia.
- Registrasi dan login pemilik menggunakan email dan password.
- Menambah kos dengan nama, alamat lengkap, harga lebih dari nol, dan deskripsi. Fasilitas dan foto bersifat opsional.
- Mengubah dan menghapus permanen kos milik sendiri.
- Menggunakan Supabase RLS untuk membatasi operasi pengelolaan berdasarkan pemilik.

### Tidak Masuk
- Pembayaran online, chat, rating, dan ulasan.
- Verifikasi identitas atau bukti kepemilikan.
- Pembatasan pencarian berdasarkan kota atau kampus.
- Pencarian berdasarkan fasilitas dan filter harga minimum.
- Pengelompokan tipe kamar.
- Status ketersediaan atau kos penuh.
- Data kos awal dari sistem.
- Platform selain Android.

## 4. Persyaratan Non-Fungsional (NFR)

- **Keamanan:** Semua pengguna, termasuk yang belum login, dapat membaca daftar dan detail kos yang dipublikasikan (SELECT). Hanya pemilik yang dapat menambah, mengubah, dan menghapus kos miliknya sendiri (INSERT, UPDATE, DELETE). Pembatasan operasi tulis diterapkan melalui Supabase RLS dan diuji menggunakan dua akun pemilik. Menyembunyikan tombol saja bukan perlindungan yang cukup.
- **Keandalan:** Jika koneksi gagal, aplikasi menampilkan pesan yang jelas dan tidak menampilkan data lama seolah-olah merupakan hasil operasi baru. Data yang berhasil disimpan harus dapat dibaca kembali setelah aplikasi dibuka ulang.
- **Kemudahan penggunaan:** Pencarian, filter, detail, login, dan pengelolaan kos dapat dilakukan melalui navigasi Android. Pesan untuk hasil kosong, data tidak valid, koneksi gagal, dan akses ditolak harus jelas.
- **Performa:** Pada data uji hingga 1.000 kos dan koneksi stabil, daftar, pencarian, dan filter menampilkan hasil maksimal 3 detik. Pembukaan detail juga maksimal 3 detik.
- **Privasi:** Password ditangani melalui autentikasi Supabase dan tidak disimpan sebagai teks biasa oleh aplikasi. Aplikasi hanya menggunakan data kos dan identitas akun yang diperlukan.

## 5. User Stories dan Acceptance Criteria

### US01 - Melihat daftar kos
Sebagai pencari kos, saya ingin melihat daftar tempat kos agar dapat menemukan pilihan yang tersedia.

- **US01-AC1:** Given terdapat kos dengan data wajib lengkap dan pengguna belum login, When pengguna membuka daftar, Then nama dan harga kos ditampilkan.
- **US01-AC2:** Given tidak ada kos dengan data wajib lengkap, When daftar dibuka, Then aplikasi menampilkan pesan data kos tidak ditemukan.
- **US01-AC3:** Given koneksi gagal, When daftar dimuat, Then aplikasi menampilkan pesan kegagalan koneksi dan tidak menampilkan hasil sebagai data baru.

### US02 - Mencari kos
Sebagai pencari kos, saya ingin mencari berdasarkan nama atau alamat agar dapat menemukan kos yang relevan.

- **US02-AC1:** Given terdapat kos bernama "Asri" atau beralamat "Jl. Melati", When kata kunci yang cocok dimasukkan, Then kos tersebut ditampilkan.
- **US02-AC2:** Given tidak ada kos yang cocok, When pencarian dijalankan, Then aplikasi menampilkan pesan data tidak ditemukan.
- **US02-AC3:** Given koneksi gagal, When pencarian dijalankan, Then aplikasi menampilkan pesan kegagalan koneksi dan tidak menampilkan hasil palsu.

### US03 - Memfilter kos berdasarkan harga
Sebagai pencari kos, saya ingin menetapkan batas harga maksimum agar dapat menemukan kos sesuai anggaran.

- **US03-AC1:** Given terdapat kos berharga Rp800.000 dan Rp1.500.000 serta batas maksimum Rp1.000.000, When filter diterapkan, Then hanya kos dengan harga maksimal Rp1.000.000 ditampilkan.
- **US03-AC2:** Given tidak ada kos yang memenuhi batas harga, When filter diterapkan, Then aplikasi menampilkan pesan data tidak ditemukan.
- **US03-AC3:** Given koneksi gagal, When filter dijalankan, Then aplikasi menampilkan pesan kegagalan koneksi dan tidak menampilkan hasil sebagai data baru.

### US04 - Melihat detail kos
Sebagai pencari kos, saya ingin melihat detail kos agar dapat membaca informasi sebelum memilih.

- **US04-AC1:** Given kos memiliki data nama, alamat, harga, deskripsi, fasilitas, dan foto, When detail dibuka, Then seluruh informasi tersebut ditampilkan.
- **US04-AC2:** Given kos tidak memiliki foto atau fasilitas, When detail dibuka, Then informasi wajib tetap ditampilkan dan bagian opsional ditangani dengan jelas.
- **US04-AC3:** Given koneksi gagal, When detail dimuat, Then aplikasi menampilkan pesan kegagalan dan tidak menampilkan detail lama sebagai milik kos lain.

### US05 - Registrasi pemilik
Sebagai pemilik kos, saya ingin mendaftar menggunakan email dan password agar dapat mengelola kos milik saya.

- **US05-AC1:** Given email belum digunakan dan password valid, When registrasi dikirim, Then akun berhasil dibuat dan pemilik dapat melanjutkan ke login atau sesi terautentikasi.
- **US05-AC2:** Given email sudah digunakan atau input tidak valid, When registrasi dikirim, Then akun tidak dibuat dan pesan kesalahan ditampilkan.
- **US05-AC3:** Given koneksi gagal, When registrasi dijalankan, Then aplikasi menampilkan pesan kegagalan koneksi dan tidak menyatakan akun berhasil dibuat.

### US06 - Login pemilik
Sebagai pemilik kos, saya ingin login menggunakan email dan password agar dapat mengakses pengelolaan kos.

- **US06-AC1:** Given email dan password benar, When pemilik login, Then aplikasi membuka sesi terautentikasi.
- **US06-AC2:** Given email atau password salah, When login dicoba, Then akses pengelolaan ditolak dan pesan kesalahan ditampilkan.
- **US06-AC3:** Given pengguna belum login, When pengguna membuka daftar, mencari, atau melihat detail kos, Then fitur baca tetap tersedia.

### US07 - Menambah kos
Sebagai pemilik kos, saya ingin menambahkan informasi kos agar dapat ditemukan pencari.

- **US07-AC1:** Given pemilik sudah login dan seluruh data wajib valid, When kos disimpan, Then kos tersimpan dan ditampilkan pada daftar.
- **US07-AC2:** Given nama, alamat, deskripsi, atau harga kosong, atau harga kurang dari atau sama dengan nol, When kos disimpan, Then data ditolak dan pesan validasi ditampilkan.
- **US07-AC3:** Given koneksi gagal saat menyimpan, When pemilik menekan tombol simpan, Then aplikasi menampilkan pesan kegagalan dan tidak menyatakan kos berhasil tersimpan.

### US08 - Mengubah kos milik sendiri
Sebagai pemilik kos, saya ingin mengubah informasi kos milik saya agar datanya tetap tepat.

- **US08-AC1:** Given pemilik login sebagai pemilik kos dan data perubahan valid, When perubahan disimpan, Then data diperbarui.
- **US08-AC2:** Given perubahan membuat data wajib kosong atau harga nol atau negatif, When perubahan disimpan, Then perubahan ditolak dan data sebelumnya tetap berlaku.
- **US08-AC3:** Given pemilik mencoba mengubah kos milik akun lain melalui UI atau backend, When permintaan dijalankan, Then Supabase RLS menolak perubahan dan data tidak berubah.

### US09 - Menghapus kos milik sendiri
Sebagai pemilik kos, saya ingin menghapus kos milik saya secara permanen agar tidak lagi ditampilkan.

- **US09-AC1:** Given pemilik login sebagai pemilik kos, When penghapusan dikonfirmasi, Then kos dihapus permanen dan tidak muncul pada daftar atau pencarian.
- **US09-AC2:** Given pemilik mencoba menghapus kos milik akun lain melalui UI atau backend, When permintaan dijalankan, Then Supabase RLS menolak penghapusan dan kos tetap ada.
- **US09-AC3:** Given koneksi gagal saat menghapus, When permintaan dijalankan, Then aplikasi menampilkan pesan kegagalan dan tidak menyatakan kos berhasil dihapus.

### US10 - Mengakses pengelolaan kos setelah login
Sebagai pemilik kos, saya ingin hanya dapat melakukan pengelolaan setelah login agar data terlindungi dari akses tanpa izin.

- **US10-AC1:** Given pengguna belum login, When mencoba menambah, mengubah, atau menghapus kos, Then tindakan ditolak dan pengguna diarahkan untuk login.
- **US10-AC2:** Given pengguna belum login mengirim permintaan pengelolaan langsung ke backend, When permintaan dijalankan, Then Supabase RLS menolaknya.
- **US10-AC3:** Given pengguna belum login, When melihat daftar, mencari, memfilter, atau membuka detail kos, Then seluruh fungsi baca tetap tersedia.

## 6. Pertanyaan atau Ambiguitas

Tidak ada pertanyaan klarifikasi yang tersisa. Implementasi selanjutnya harus mengikuti batasan dan aturan dalam PRD ini tanpa menambahkan fitur di luar scope versi pertama.
