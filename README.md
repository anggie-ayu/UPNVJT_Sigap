# UPNVJT SIGAP — Aplikasi Desktop Admin (Flutter)

Aplikasi desktop untuk administrasi layanan bantuan antar mahasiswa UPN "Veteran" Jawa Timur.
Fitur UI mengikuti alur tugas Pemrograman Desktop Episode 6: login, registrasi, CRUD master data,
profil, dan logout. Struktur model mengikuti PDM SIGAP: `users`, `kategori_layanan`, `pesanan`,
`negosiasi`, `ulasan`, dan `transaksi_keuangan`.

## Fitur yang tersedia

- Login Admin (panel desktop dibatasi untuk role Admin). Kata sandi bisa dilihat/disembunyikan lewat ikon mata.
- Registrasi mandiri **hanya untuk Pelanggan**. Akun **Kru hanya dapat didaftarkan oleh Admin** lewat Master Pengguna (jadwal KRS wajib diisi).
- Dashboard statistik pesanan, pengguna, kategori, dan transaksi.
- CRUD master kategori layanan, termasuk kategori tetap **Lainnya (Request)** untuk permintaan layanan di luar daftar.
- CRUD master pengguna.
- Kelola status dan data pesanan, termasuk **negosiasi harga** per pesanan (ikon Negosiasi).
- Laporan transaksi/komisi admin dan **ekspor ke Excel (.xlsx)**; ekspor kategori juga ke Excel.
- Kolom **Cari** di setiap tab punya petunjuk kolom yang dicari, tombol hapus, dan info jumlah hasil.
- Profil admin, ubah data profil dan kata sandi.
- Logout kembali ke halaman login.

## Cara menjalankan di Windows

Pastikan Flutter SDK sudah terpasang dan `flutter doctor` tidak menunjukkan masalah untuk Windows desktop.

1. Ekstrak ZIP.
2. Buka CMD/Terminal, masuk ke folder `sigap`.
3. Jalankan `flutter create --platforms=windows .` untuk membuat berkas platform desktop yang belum disertakan dalam ZIP.
4. Jalankan `flutter pub get`.
5. Jalankan `flutter run -d windows`.

Gunakan jendela desktop sekitar 1200 × 720 atau lebih besar agar tabel nyaman dibaca.

## Ekspor Excel

Tombol Ekspor (Master Kategori) dan Ekspor ke Excel (Laporan Keuangan) membuat berkas `.xlsx`
dan menyimpannya ke folder **Downloads** pengguna (jika tidak ada, ke folder sementara).
Lokasi file ditampilkan setelah ekspor. Angka disimpan sebagai angka sehingga bisa dijumlah di Excel.
Paket yang dipakai: `excel` (otomatis terpasang lewat `flutter pub get`).

## Negosiasi harga

Berlaku untuk kategori bertipe harga **Negosiasi** (Pindahan Kos, Jasa Khusus, Lainnya).

1. Buka Master Pesanan, klik ikon **Negosiasi** (gelembung chat) pada pesanan.
2. Pelanggan atau kru mengajukan harga tawar (dicatat admin pada form).
3. Pihak lawan **Terima & sepakati**, **Tolak**, atau **Tawar ulang** (tawar ulang otomatis menolak tawaran yang masih menunggu).
4. Tawaran yang diterima menjadi harga final pesanan (`estimasi_biaya`) dan dasar komisi 8%.
   Bila tawaran diterima berasal dari kru, kru tersebut otomatis memegang pesanan (status Diambil).

Kolom Estimasi di Master Pesanan menampilkan status negosiasi (disepakati / menunggu / belum ada),
dan ada pengingat jumlah tawaran yang menunggu keputusan.

## Kategori "Lainnya (Request)"

Kategori tetap bertipe Negosiasi untuk layanan di luar matriks kategori. Pada form pesanan,
kolom detail berubah menjadi **Layanan yang diminta pelanggan** dan wajib diisi. Kategori ini tidak bisa
dihapus, namanya harus tetap diawali "Lainnya", dan tipe harganya harus Negosiasi.

## Akun demo untuk menguji alur Admin

- Email: `sultan@email.com`
- Kata sandi: `admin123`

Form login diisi dengan akun demo tersebut saat pertama kali dibuka. Data demo dibuat otomatis setiap aplikasi dijalankan ulang.

## Catatan penting tentang database

**Skema MySQL tidak diubah oleh proyek ini.** Model aplikasi mengacu pada kolom PDM yang sudah ada. Namun, versi ZIP ini masih menggunakan `AppStore` berbasis memori (`lib/data/app_store.dart`), bukan koneksi MySQL aktif. Artinya, CRUD dan login bisa diuji sebagai demonstrasi UI, tetapi perubahan data tidak akan tersimpan ke database MySQL dan akan kembali ke data demo setelah aplikasi ditutup.

Jangan menganggap login demo sebagai autentikasi database. Untuk mengaktifkan koneksi ke database yang sudah ada, lapisan `AppStore` perlu diganti dengan repository/API yang menjalankan query ke tabel PDM tanpa mengubah skema. Koneksi MySQL desktop langsung dengan kredensial `root` tidak disarankan untuk distribusi aplikasi.

## Pemetaan model ke PDM

| Model aplikasi | Tabel PDM | Keterangan |
|---|---|---|
| `UserModel` | `users` | data akun dan role |
| `KategoriLayanan` | `kategori_layanan` | nama kategori dan tarif dasar per km |
| `Pesanan` | `pesanan` | pelanggan, kru, kategori, lokasi, waktu, biaya, status |
| `Negosiasi` | `negosiasi` | tawaran harga, pengirim, status tawaran |
| `Ulasan` | `ulasan` | rating dan komentar pesanan |
| `TransaksiKeuangan` | `transaksi_keuangan` | total bayar, komisi admin, pendapatan kru |

Catatan PDM: deskripsi dan warna kategori pada UI hanya untuk presentasi; keduanya bukan kolom pada PDM yang dikirim. Nilai tersebut tidak boleh dianggap tersimpan di MySQL.

## Struktur folder

```text
lib/
  main.dart
  core/theme.dart
  models/models.dart
  data/app_store.dart
  widgets/common.dart
  pages/auth_pages.dart
  pages/home_shell.dart
  pages/dashboard_page.dart
  pages/kategori_page.dart
  pages/pengguna_page.dart
  pages/pesanan_page.dart
  pages/laporan_page.dart
  pages/profil_page.dart
```

## Checklist sebelum UTS

- [ ] Jalankan `flutter pub get`.
- [ ] Jalankan `flutter analyze`.
- [ ] Jalankan aplikasi desktop.
- [ ] Tes login admin dengan akun demo di atas.
- [ ] Tes menu kategori, pengguna, pesanan, laporan, profil, dan logout.
- [ ] Tes kolom Cari di tiap tab, ikon mata pada kata sandi, ekspor Excel, dan negosiasi.
- [ ] Jika dosen mewajibkan data benar-benar tersimpan ke MySQL, integrasi repository/API harus diselesaikan dan diuji terhadap database yang digunakan.
