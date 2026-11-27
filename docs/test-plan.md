# Rencana Pengujian KosFinder

Rencana ini mencakup seluruh 30 acceptance criteria (AC) pada [PRD.md](./PRD.md). Jalankan pengujian manual pada perangkat Android atau emulator. Isi kolom **Hasil nyata** dan **Lulus** setelah setiap skenario diuji.

## Persiapan

- Siapkan koneksi internet yang stabil, lalu siapkan cara memutus koneksi untuk skenario offline.
- Siapkan dua akun pemilik berbeda (Pemilik A dan Pemilik B) untuk menguji pembatasan kepemilikan.
- Siapkan data kos dengan nama, alamat, harga, deskripsi, fasilitas, dan foto yang bervariasi; termasuk kos tanpa fasilitas/foto.
- Untuk pengujian daftar kosong, pencarian kosong, dan filter tanpa hasil, siapkan kondisi data yang sesuai dan pastikan tidak ada data lain yang dapat cocok.
- Untuk pengujian penolakan di backend, kirim permintaan menggunakan sesi akun terkait ke Supabase dan verifikasi hasilnya tanpa menggunakan `service_role`.
- Catat hasil aktual secara ringkas; tandai **Lulus** hanya jika hasil sesuai harapan.

## Skenario Pengujian

| ID | AC terkait | Langkah | Hasil yang diharapkan | Hasil nyata | Lulus |
|---|---|---|---|---|---|
| TP-01 | US01-AC1 | Logout. Pastikan tersedia kos dengan data wajib lengkap. Buka halaman daftar kos. | Daftar dapat dibuka tanpa login dan menampilkan nama serta harga kos. | | |
| TP-02 | US01-AC2 | Siapkan kondisi tanpa kos dengan data wajib lengkap. Logout, lalu buka daftar kos. | Aplikasi menampilkan pesan bahwa data kos tidak ditemukan; tidak menampilkan kos yang tidak memenuhi data wajib. | | |
| TP-03 | US01-AC3 | Matikan koneksi internet, lalu buka atau muat ulang daftar kos. | Aplikasi menampilkan pesan kegagalan koneksi dan tidak menyajikan data lama sebagai hasil pemuatan baru. | | |
| TP-04 | US02-AC1 | Logout. Cari nama yang cocok dengan kos bernama “Asri”, lalu ulangi dengan alamat yang cocok dengan “Jl. Melati”. | Kos yang cocok ditampilkan untuk pencarian berdasarkan nama maupun alamat. | | |
| TP-05 | US02-AC2 | Masukkan kata kunci yang dipastikan tidak cocok dengan nama atau alamat kos mana pun, lalu jalankan pencarian. | Aplikasi menampilkan pesan data tidak ditemukan dan tidak menampilkan hasil yang tidak cocok. | | |
| TP-06 | US02-AC3 | Matikan koneksi internet, lalu jalankan pencarian dengan kata kunci yang sebelumnya menghasilkan kos. | Aplikasi menampilkan pesan kegagalan koneksi dan tidak menampilkan hasil palsu atau hasil lama seolah-olah pencarian berhasil. | | |
| TP-07 | US03-AC1 | Pastikan tersedia kos Rp800.000 dan Rp1.500.000. Terapkan batas maksimum Rp1.000.000. | Kos Rp800.000 ditampilkan dan kos Rp1.500.000 tidak ditampilkan. | | |
| TP-08 | US03-AC2 | Terapkan batas maksimum yang lebih rendah daripada harga semua kos yang tersedia. | Aplikasi menampilkan pesan data tidak ditemukan dan tidak menampilkan kos yang melampaui batas. | | |
| TP-09 | US03-AC3 | Matikan koneksi internet, lalu jalankan filter harga. | Aplikasi menampilkan pesan kegagalan koneksi dan tidak menyajikan data lama sebagai hasil filter baru. | | |
| TP-10 | US04-AC1 | Buka detail kos yang memiliki nama, alamat, harga, deskripsi, fasilitas, dan foto. | Detail menampilkan seluruh informasi tersebut dengan benar, termasuk foto. | | |
| TP-11 | US04-AC2 | Buka detail kos yang tidak memiliki foto dan/atau fasilitas. | Informasi wajib tetap tampil; bagian foto/fasilitas yang tidak tersedia ditangani dengan jelas tanpa mengganggu detail. | | |
| TP-12 | US04-AC3 | Buka suatu detail kos, matikan koneksi internet, lalu coba muat detail kos lain. | Aplikasi menampilkan pesan kegagalan dan tidak menampilkan detail kos sebelumnya seolah-olah milik kos yang baru dipilih. | | |
| TP-13 | US05-AC1 | Dengan koneksi internet, daftarkan akun pemilik memakai email yang belum digunakan dan password valid. Setelah berhasil, lanjutkan ke login atau periksa sesi terautentikasi. | Akun berhasil dibuat dan pemilik dapat melanjutkan ke login atau berada dalam sesi terautentikasi. | | |
| TP-14 | US05-AC2 | Coba registrasi dengan email yang sudah terdaftar. Ulangi dengan input tidak valid (misalnya format email salah atau password tidak memenuhi validasi). | Setiap percobaan ditolak, akun baru tidak dibuat, dan pesan kesalahan ditampilkan. | | |
| TP-15 | US05-AC3 | Matikan koneksi internet, lalu kirim formulir registrasi dengan input valid. | Aplikasi menampilkan pesan kegagalan koneksi dan tidak menyatakan akun berhasil dibuat. | | |
| TP-16 | US06-AC1 | Login menggunakan email dan password pemilik yang benar. | Aplikasi membuka sesi terautentikasi dan pemilik dapat mengakses pengelolaan kos. | | |
| TP-17 | US06-AC2 | Coba login dengan email atau password yang salah. | Akses pengelolaan ditolak dan aplikasi menampilkan pesan kesalahan. | | |
| TP-18 | US06-AC3 | Logout. Buka daftar, cari kos, dan buka detail kos sebagai pengguna anonim. | Daftar, pencarian, dan detail tetap dapat digunakan tanpa login. | | |
| TP-19 | US07-AC1 | Login sebagai Pemilik A. Tambahkan kos dengan nama, alamat lengkap, harga lebih dari nol, dan deskripsi yang valid; fasilitas dan foto boleh diisi atau dikosongkan. Simpan. | Kos tersimpan dan tampil pada daftar. | | |
| TP-20 | US07-AC2 | Coba menyimpan kos dengan nama kosong, alamat kosong, atau deskripsi kosong; ulangi dengan harga kosong, nol, dan negatif. | Setiap data tidak valid ditolak, pesan validasi ditampilkan, dan kos tidak tersimpan. | | |
| TP-21 | US07-AC3 | Login sebagai pemilik, isi formulir kos dengan data valid, matikan koneksi, lalu tekan simpan. | Aplikasi menampilkan pesan kegagalan dan tidak menyatakan kos berhasil tersimpan. | | |
| TP-22 | US08-AC1 | Login sebagai Pemilik A. Ubah data kos milik A dengan nilai wajib yang valid, lalu simpan. | Perubahan berhasil disimpan dan data terbaru tampil saat kos dibuka kembali. | | |
| TP-23 | US08-AC2 | Edit kos milik sendiri. Coba simpan perubahan dengan setiap data wajib dikosongkan dan dengan harga nol atau negatif. | Perubahan ditolak; pesan validasi muncul dan data sebelumnya tetap berlaku. | | |
| TP-24 | US08-AC3 | Login sebagai Pemilik B, lalu coba mengubah kos milik Pemilik A melalui UI dan/atau permintaan langsung ke backend. Periksa kembali data sebagai Pemilik A. | Supabase RLS menolak perubahan dan data milik A tidak berubah. | | |
| TP-25 | US09-AC1 | Login sebagai pemilik kos. Hapus kos milik sendiri dan konfirmasi penghapusan. Periksa daftar serta pencarian. | Kos terhapus permanen dan tidak lagi muncul pada daftar maupun pencarian. | | |
| TP-26 | US09-AC2 | Login sebagai Pemilik B, lalu coba menghapus kos milik Pemilik A melalui UI dan/atau permintaan langsung ke backend. Periksa kembali daftar sebagai Pemilik A. | Supabase RLS menolak penghapusan dan kos milik A tetap ada. | | |
| TP-27 | US09-AC3 | Login sebagai pemilik, pilih kos milik sendiri untuk dihapus, matikan koneksi sebelum mengirim permintaan, lalu konfirmasi. | Aplikasi menampilkan pesan kegagalan dan tidak menyatakan kos berhasil dihapus. | | |
| TP-28 | US10-AC1 | Logout. Coba menambah, mengubah, dan menghapus kos melalui UI. | Setiap tindakan pengelolaan ditolak dan pengguna diarahkan untuk login. | | |
| TP-29 | US10-AC2 | Tanpa sesi login, kirim permintaan pengelolaan langsung ke backend untuk menambah, mengubah, atau menghapus kos. | Supabase RLS menolak setiap permintaan; tidak ada data yang ditambahkan, diubah, atau dihapus. | | |
| TP-30 | US10-AC3 | Logout. Buka daftar, cari kos, terapkan filter harga, lalu buka detail kos. | Semua fungsi baca (daftar, pencarian, filter, dan detail) tetap tersedia tanpa login. | | |

## Rekap Cakupan

- Acceptance criteria tercakup: **30 dari 30** (US01–US10).
- Skenario pengujian: **30**.
