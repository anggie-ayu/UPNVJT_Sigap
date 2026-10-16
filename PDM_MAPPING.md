# Catatan Integrasi PDM UPNVJT SIGAP

Dokumen ini hanya dokumentasi mapping; tidak menjalankan atau mengubah database.

Pastikan nama kolom di query mengikuti PDM yang sudah dibuat:
- `users`: `id_user`, `nama_lengkap`, `email`, `password_hash`, `no_telepon`, `role`, `jadwal_krs`
- `kategori_layanan`: `id_kategori`, `nama_kategori`, `tarif_dasar_km`
- `pesanan`: `id_pesanan`, `id_pelanggan`, `id_kru`, `id_kategori`, `lokasi_jemput`, `lokasi_antar`, `waktu_dibutuhkan`, `detail_pesanan`, `estimasi_biaya`, `status_pesanan`, `created_at`
- `negosiasi`: `id_negosiasi`, `id_pesanan`, `id_pengirim`, `harga_tawar`, `status_tawaran`, `created_at`
- `ulasan`: `id_ulasan`, `id_pesanan`, `id_pelanggan`, `id_kru`, `rating`, `komentar`, `created_at`
- `transaksi_keuangan`: `id_transaksi`, `id_pesanan`, `total_bayar`, `komisi_admin`, `pendapatan_kru`, `waktu_selesai`

Jangan menambahkan kolom baru hanya untuk menyesuaikan UI. Jika nama kolom aktual di database berbeda, gunakan nama yang sudah ada di database.

Catatan fitur terbaru (tanpa perubahan skema):
- Negosiasi memakai tabel `negosiasi` apa adanya: `status_tawaran` = `menunggu` / `diterima` / `ditolak`.
- Kategori "Lainnya (Request)" adalah baris biasa di `kategori_layanan` dengan `tarif_dasar_km` = 0 (negosiasi).
  Teks permintaan pelanggan disimpan di kolom `detail_pesanan`, bukan kolom baru.
