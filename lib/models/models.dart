// Model data mengikuti PDM (ERD) SIGAP.
// Nama field = nama kolom database (camelCase) agar mudah dipetakan.

enum UserRole { pelanggan, kru, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.pelanggan:
        return 'Pelanggan';
      case UserRole.kru:
        return 'Kru';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Nilai untuk kolom ENUM `role` di tabel users.
  String get dbValue => name;
}

enum StatusPesanan { menunggu, diambil, dikerjakan, selesai, dibatalkan }

extension StatusPesananX on StatusPesanan {
  String get label {
    switch (this) {
      case StatusPesanan.menunggu:
        return 'Menunggu Helper';
      case StatusPesanan.diambil:
        return 'Diambil';
      case StatusPesanan.dikerjakan:
        return 'Sedang Dikerjakan';
      case StatusPesanan.selesai:
        return 'Selesai';
      case StatusPesanan.dibatalkan:
        return 'Dibatalkan';
    }
  }

  /// Nilai untuk kolom ENUM `status_pesanan` di tabel pesanan.
  String get dbValue => name;
}

enum StatusTawaran { menunggu, diterima, ditolak }

extension StatusTawaranX on StatusTawaran {
  String get label {
    switch (this) {
      case StatusTawaran.menunggu:
        return 'Menunggu';
      case StatusTawaran.diterima:
        return 'Diterima';
      case StatusTawaran.ditolak:
        return 'Ditolak';
    }
  }

  /// Nilai untuk kolom ENUM `status_tawaran` di tabel negosiasi.
  String get dbValue => name;
}

/// Tabel `users`
class UserModel {
  UserModel({
    required this.idUser,
    required this.namaLengkap,
    required this.email,
    required this.passwordHash,
    required this.noTelepon,
    required this.role,
    this.jadwalKrs,
  });

  int idUser;
  String namaLengkap;
  String email;
  String passwordHash;
  String noTelepon;
  UserRole role;
  String? jadwalKrs;

  bool get krsTerisi => (jadwalKrs ?? '').trim().isNotEmpty;
}

/// Tabel `kategori_layanan`
/// tarifDasarKm <= 0 berarti harga dinegosiasikan.
/// [deskripsi] dan [warnaIndex] hanya untuk tampilan (belum ada di PDM).
class KategoriLayanan {
  KategoriLayanan({
    required this.idKategori,
    required this.namaKategori,
    required this.tarifDasarKm,
    this.deskripsi = '',
    this.warnaIndex = 0,
  });

  int idKategori;
  String namaKategori;
  double tarifDasarKm;
  String deskripsi;
  int warnaIndex;

  bool get negosiasi => tarifDasarKm <= 0;

  /// Kategori "Lainnya": pelanggan menulis sendiri layanan di luar daftar
  /// (di luar matriks kategori). Selalu memakai harga negosiasi.
  bool get lainnya => namaKategori.trim().toLowerCase().startsWith('lainnya');
}

/// Tabel `pesanan`
class Pesanan {
  Pesanan({
    required this.idPesanan,
    required this.idPelanggan,
    this.idKru,
    required this.idKategori,
    required this.lokasiJemput,
    required this.lokasiAntar,
    required this.waktuDibutuhkan,
    required this.detailPesanan,
    required this.estimasiBiaya,
    required this.statusPesanan,
    required this.createdAt,
  });

  int idPesanan;
  int idPelanggan;
  int? idKru;
  int idKategori;
  String lokasiJemput;
  String lokasiAntar;
  DateTime waktuDibutuhkan;
  String detailPesanan;
  double estimasiBiaya;
  StatusPesanan statusPesanan;
  DateTime createdAt;
}

/// Tabel `transaksi_keuangan`
class TransaksiKeuangan {
  TransaksiKeuangan({
    required this.idTransaksi,
    required this.idPesanan,
    required this.totalBayar,
    required this.komisiAdmin,
    required this.pendapatanKru,
    required this.waktuSelesai,
  });

  int idTransaksi;
  int idPesanan;
  double totalBayar;
  double komisiAdmin;
  double pendapatanKru;
  DateTime waktuSelesai;
}

/// Tabel `ulasan`
class Ulasan {
  Ulasan({
    required this.idUlasan,
    required this.idPesanan,
    required this.idPelanggan,
    required this.idKru,
    required this.rating,
    this.komentar = '',
    required this.createdAt,
  });

  int idUlasan;
  int idPesanan;
  int idPelanggan;
  int idKru;
  int rating;
  String komentar;
  DateTime createdAt;
}

/// Tabel `negosiasi`
class Negosiasi {
  Negosiasi({
    required this.idNegosiasi,
    required this.idPesanan,
    required this.idPengirim,
    required this.hargaTawar,
    required this.statusTawaran,
    required this.createdAt,
  });

  int idNegosiasi;
  int idPesanan;
  int idPengirim;
  double hargaTawar;
  StatusTawaran statusTawaran;
  DateTime createdAt;
}
