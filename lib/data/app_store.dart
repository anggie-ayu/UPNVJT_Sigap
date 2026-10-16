import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../core/theme.dart';
import '../models/models.dart';

/// Hash kata sandi. Untuk produksi, hash sebaiknya dilakukan di server
/// (bcrypt/argon2). Di sini SHA-256 supaya kolom password_hash tidak
/// menyimpan teks asli.
String hashPassword(String plain) => sha256.convert(utf8.encode(plain)).toString();

class ActivityLog {
  ActivityLog(this.text, this.time, this.colorIndex);
  final String text;
  final DateTime time;
  final int colorIndex;
}

/// Semua data aplikasi ada di sini (sementara in-memory).
///
/// Saat dihubungkan ke database, isi setiap method (login, register,
/// tambah/ubah/hapus ...) diganti dengan query / pemanggilan API.
/// Tampilan tidak perlu diubah karena semua halaman hanya memanggil
/// method pada [AppStore].
class AppStore extends ChangeNotifier {
  AppStore() {
    _seed();
  }

  static const double komisiRate = 0.08;

  final List<UserModel> users = <UserModel>[];
  final List<KategoriLayanan> kategori = <KategoriLayanan>[];
  final List<Pesanan> pesanan = <Pesanan>[];
  final List<TransaksiKeuangan> transaksi = <TransaksiKeuangan>[];
  final List<Ulasan> ulasan = <Ulasan>[];
  final List<Negosiasi> negosiasi = <Negosiasi>[];
  final List<ActivityLog> activities = <ActivityLog>[];

  UserModel? currentUser;
  DateTime? lastLogin;

  int _uid = 0;
  int _kid = 0;
  int _tid = 0;
  int _rid = 0;
  int _nid = 0;

  // -------------------------------------------------------------------------
  // Lookup
  // -------------------------------------------------------------------------

  UserModel? userById(int? id) {
    if (id == null) return null;
    for (final UserModel u in users) {
      if (u.idUser == id) return u;
    }
    return null;
  }

  KategoriLayanan? kategoriById(int id) {
    for (final KategoriLayanan k in kategori) {
      if (k.idKategori == id) return k;
    }
    return null;
  }

  Pesanan? pesananById(int id) {
    for (final Pesanan p in pesanan) {
      if (p.idPesanan == id) return p;
    }
    return null;
  }

  String namaUser(int? id) => userById(id)?.namaLengkap ?? '—';
  String namaKategori(int id) => kategoriById(id)?.namaKategori ?? '—';

  List<UserModel> get daftarKru =>
      users.where((UserModel u) => u.role == UserRole.kru).toList();

  // -------------------------------------------------------------------------
  // Statistik
  // -------------------------------------------------------------------------

  int countStatus(StatusPesanan s) =>
      pesanan.where((Pesanan p) => p.statusPesanan == s).length;

  int get pesananAktif =>
      countStatus(StatusPesanan.menunggu) +
      countStatus(StatusPesanan.diambil) +
      countStatus(StatusPesanan.dikerjakan);

  int countKategori(int idKategori) =>
      pesanan.where((Pesanan p) => p.idKategori == idKategori).length;

  int countRole(UserRole r) => users.where((UserModel u) => u.role == r).length;

  int get kruKrsTerisi => daftarKru.where((UserModel u) => u.krsTerisi).length;

  double get totalTransaksi =>
      transaksi.fold<double>(0, (double a, TransaksiKeuangan t) => a + t.totalBayar);
  double get totalKomisi =>
      transaksi.fold<double>(0, (double a, TransaksiKeuangan t) => a + t.komisiAdmin);
  double get totalPendapatanKru =>
      transaksi.fold<double>(0, (double a, TransaksiKeuangan t) => a + t.pendapatanKru);

  double get rataRating {
    if (ulasan.isEmpty) return 0;
    final int total = ulasan.fold<int>(0, (int a, Ulasan u) => a + u.rating);
    return total / ulasan.length;
  }

  // -------------------------------------------------------------------------
  // Autentikasi
  // -------------------------------------------------------------------------

  /// Mengembalikan pesan error, atau null jika berhasil.
  String? login(String email, String password, UserRole role) {
    final String e = email.trim().toLowerCase();
    for (final UserModel u in users) {
      if (u.email.toLowerCase() == e) {
        if (u.passwordHash != hashPassword(password)) {
          return 'Email atau kata sandi salah.';
        }
        if (u.role != role) {
          return 'Akun ini terdaftar sebagai ${u.role.label}, bukan ${role.label}.';
        }
        if (u.role != UserRole.admin) {
          return 'Panel desktop SIGAP khusus Admin. Akun ${u.role.label} dipakai di aplikasi pelanggan/kru.';
        }
        currentUser = u;
        lastLogin = DateTime.now();
        notifyListeners();
        return null;
      }
    }
    return 'Email atau kata sandi salah.';
  }

  /// Pendaftaran mandiri (dari halaman Daftar) HANYA untuk pelanggan.
  /// Akun kru dan admin hanya dapat dibuat oleh admin lewat [tambahUser].
  String? register({
    required String nama,
    required String email,
    required String telepon,
    required String password,
  }) {
    if (_emailTerpakai(email)) return 'Email sudah terdaftar.';
    users.add(UserModel(
      idUser: ++_uid,
      namaLengkap: nama.trim(),
      email: email.trim(),
      passwordHash: hashPassword(password),
      noTelepon: telepon.trim(),
      role: UserRole.pelanggan,
    ));
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  bool _emailTerpakai(String email, {int? kecualiId}) {
    final String e = email.trim().toLowerCase();
    return users.any((UserModel u) => u.email.toLowerCase() == e && u.idUser != kecualiId);
  }

  // -------------------------------------------------------------------------
  // CRUD users
  // -------------------------------------------------------------------------

  String? tambahUser({
    required String nama,
    required String email,
    required String telepon,
    required String password,
    required UserRole role,
    String? jadwalKrs,
  }) {
    if (currentUser?.role != UserRole.admin) {
      return 'Hanya admin yang dapat mendaftarkan kru atau menambah pengguna.';
    }
    if (role == UserRole.kru && (jadwalKrs ?? '').trim().isEmpty) {
      return 'Jadwal KRS wajib diisi untuk kru.';
    }
    if (_emailTerpakai(email)) return 'Email sudah terdaftar.';
    users.add(UserModel(
      idUser: ++_uid,
      namaLengkap: nama.trim(),
      email: email.trim(),
      passwordHash: hashPassword(password),
      noTelepon: telepon.trim(),
      role: role,
      jadwalKrs: role == UserRole.kru ? (jadwalKrs ?? '').trim() : null,
    ));
    _log('Menambah pengguna "${nama.trim()}"', 0);
    notifyListeners();
    return null;
  }

  String? ubahUser({
    required int id,
    required String nama,
    required String email,
    required String telepon,
    required UserRole role,
    String? jadwalKrs,
    String? passwordBaru,
  }) {
    final UserModel? u = userById(id);
    if (u == null) return 'Pengguna tidak ditemukan.';
    if (_emailTerpakai(email, kecualiId: id)) return 'Email sudah digunakan pengguna lain.';
    if (role == UserRole.kru && (jadwalKrs ?? '').trim().isEmpty) {
      return 'Jadwal KRS wajib diisi untuk kru.';
    }
    if (currentUser?.idUser == id && role != u.role) {
      return 'Peran akun yang sedang dipakai tidak dapat diubah.';
    }
    u.namaLengkap = nama.trim();
    u.email = email.trim();
    u.noTelepon = telepon.trim();
    u.role = role;
    u.jadwalKrs = role == UserRole.kru ? (jadwalKrs ?? '').trim() : null;
    if (passwordBaru != null && passwordBaru.isNotEmpty) {
      u.passwordHash = hashPassword(passwordBaru);
    }
    _log('Memperbarui data ${u.role.label.toLowerCase()} ${u.namaLengkap}', 2);
    notifyListeners();
    return null;
  }

  String? hapusUser(int id) {
    final UserModel? u = userById(id);
    if (u == null) return 'Pengguna tidak ditemukan.';
    if (currentUser?.idUser == id) return 'Akun yang sedang dipakai tidak dapat dihapus.';
    final bool dipakai = pesanan.any((Pesanan p) => p.idPelanggan == id || p.idKru == id) ||
        ulasan.any((Ulasan r) => r.idPelanggan == id || r.idKru == id) ||
        negosiasi.any((Negosiasi n) => n.idPengirim == id);
    if (dipakai) {
      return 'Pengguna masih memiliki pesanan/ulasan/tawaran sehingga tidak dapat dihapus.';
    }
    users.remove(u);
    _log('Menghapus pengguna "${u.namaLengkap}"', 3);
    notifyListeners();
    return null;
  }

  // -------------------------------------------------------------------------
  // CRUD kategori_layanan
  // -------------------------------------------------------------------------

  String? tambahKategori(String nama, double tarif, String deskripsi, int warnaIndex) {
    if (kategori.any((KategoriLayanan k) => k.namaKategori.toLowerCase() == nama.trim().toLowerCase())) {
      return 'Nama kategori sudah ada.';
    }
    kategori.add(KategoriLayanan(
      idKategori: ++_kid,
      namaKategori: nama.trim(),
      tarifDasarKm: tarif,
      deskripsi: deskripsi.trim(),
      warnaIndex: warnaIndex,
    ));
    _log('Menambah kategori "${nama.trim()}"', 0);
    notifyListeners();
    return null;
  }

  String? ubahKategori(int id, String nama, double tarif, String deskripsi, int warnaIndex) {
    final KategoriLayanan? k = kategoriById(id);
    if (k == null) return 'Kategori tidak ditemukan.';
    final bool kembar = kategori.any((KategoriLayanan x) =>
        x.idKategori != id && x.namaKategori.toLowerCase() == nama.trim().toLowerCase());
    if (kembar) return 'Nama kategori sudah ada.';
    if (k.lainnya &&
        (!nama.trim().toLowerCase().startsWith('lainnya') || tarif > 0)) {
      return 'Kategori "Lainnya" bersifat tetap: nama harus diawali "Lainnya" dan tipe harga harus Negosiasi.';
    }
    k.namaKategori = nama.trim();
    k.tarifDasarKm = tarif;
    k.deskripsi = deskripsi.trim();
    k.warnaIndex = warnaIndex;
    _log('Memperbarui kategori "${k.namaKategori}"', 2);
    notifyListeners();
    return null;
  }

  String? hapusKategori(int id) {
    final KategoriLayanan? k = kategoriById(id);
    if (k == null) return 'Kategori tidak ditemukan.';
    if (k.lainnya) {
      return 'Kategori "Lainnya" tidak dapat dihapus karena dipakai untuk permintaan layanan di luar daftar.';
    }
    if (countKategori(id) > 0) return 'Kategori sudah dipakai pesanan sehingga tidak dapat dihapus.';
    kategori.remove(k);
    _log('Menghapus kategori "${k.namaKategori}"', 3);
    notifyListeners();
    return null;
  }

  // -------------------------------------------------------------------------
  // Pesanan
  // -------------------------------------------------------------------------

  String? ubahPesanan(int id, StatusPesanan status, int? idKru) {
    final Pesanan? p = pesananById(id);
    if (p == null) return 'Pesanan tidak ditemukan.';
    if (p.statusPesanan == StatusPesanan.selesai && status != StatusPesanan.selesai) {
      return 'Pesanan yang sudah selesai tidak dapat diubah.';
    }
    final bool perluKru = status == StatusPesanan.diambil ||
        status == StatusPesanan.dikerjakan ||
        status == StatusPesanan.selesai;
    if (perluKru && idKru == null) return 'Pilih kru terlebih dahulu.';
    p.statusPesanan = status;
    p.idKru = status == StatusPesanan.menunggu ? null : idKru;
    if (status == StatusPesanan.selesai &&
        !transaksi.any((TransaksiKeuangan t) => t.idPesanan == id)) {
      _buatTransaksi(p, DateTime.now());
    }
    _log('Mengubah status ${_kodePesanan(id)} menjadi ${status.label}', 2);
    notifyListeners();
    return null;
  }

  int _nextPesananId() {
    int maks = 0;
    for (final Pesanan p in pesanan) {
      if (p.idPesanan > maks) maks = p.idPesanan;
    }
    return maks + 1;
  }

  /// Tambah (id == null) atau ubah pesanan. Mengembalikan pesan error / null.
  String? simpanPesanan({
    int? id,
    required int idPelanggan,
    int? idKru,
    required int idKategori,
    required String lokasiJemput,
    required String lokasiAntar,
    required DateTime waktu,
    required String detail,
    required double biaya,
    required StatusPesanan status,
  }) {
    final UserModel? pel = userById(idPelanggan);
    if (pel == null || pel.role != UserRole.pelanggan) return 'Pelanggan tidak valid.';
    final KategoriLayanan? kat = kategoriById(idKategori);
    if (kat == null) return 'Kategori tidak valid.';
    if (kat.lainnya && detail.trim().isEmpty) {
      return 'Tuliskan layanan yang diminta pelanggan pada kolom detail.';
    }
    final bool perluKru = status == StatusPesanan.diambil ||
        status == StatusPesanan.dikerjakan ||
        status == StatusPesanan.selesai;
    if (perluKru && idKru == null) return 'Pilih kru terlebih dahulu.';
    if (idKru != null) {
      final UserModel? k = userById(idKru);
      if (k == null || k.role != UserRole.kru) return 'Kru tidak valid.';
    }
    final Pesanan? lama = id == null ? null : pesananById(id);
    if (id != null && lama == null) return 'Pesanan tidak ditemukan.';
    if (lama != null && lama.statusPesanan == StatusPesanan.selesai) {
      return 'Pesanan yang sudah selesai tidak dapat diubah.';
    }
    final Pesanan p;
    if (lama == null) {
      p = Pesanan(
        idPesanan: _nextPesananId(),
        idPelanggan: idPelanggan,
        idKategori: idKategori,
        lokasiJemput: lokasiJemput.trim(),
        lokasiAntar: lokasiAntar.trim(),
        waktuDibutuhkan: waktu,
        detailPesanan: detail.trim(),
        estimasiBiaya: biaya,
        statusPesanan: status,
        createdAt: DateTime.now(),
      );
      pesanan.add(p);
    } else {
      p = lama;
      p.idPelanggan = idPelanggan;
      p.idKategori = idKategori;
      p.lokasiJemput = lokasiJemput.trim();
      p.lokasiAntar = lokasiAntar.trim();
      p.waktuDibutuhkan = waktu;
      p.detailPesanan = detail.trim();
      p.estimasiBiaya = biaya;
      p.statusPesanan = status;
    }
    p.idKru = status == StatusPesanan.menunggu ? null : idKru;
    if (status == StatusPesanan.selesai &&
        !transaksi.any((TransaksiKeuangan t) => t.idPesanan == p.idPesanan)) {
      _buatTransaksi(p, DateTime.now());
    }
    _log(lama == null ? 'Menambah pesanan ${_kodePesanan(p.idPesanan)}' : 'Memperbarui pesanan ${_kodePesanan(p.idPesanan)}', lama == null ? 0 : 2);
    notifyListeners();
    return null;
  }

  String? hapusPesanan(int id) {
    final Pesanan? p = pesananById(id);
    if (p == null) return 'Pesanan tidak ditemukan.';
    if (transaksi.any((TransaksiKeuangan t) => t.idPesanan == id)) {
      return 'Pesanan ini sudah memiliki transaksi keuangan sehingga tidak dapat dihapus.';
    }
    ulasan.removeWhere((Ulasan r) => r.idPesanan == id);
    negosiasi.removeWhere((Negosiasi n) => n.idPesanan == id);
    pesanan.remove(p);
    _log('Menghapus pesanan ${_kodePesanan(id)}', 3);
    notifyListeners();
    return null;
  }

  String _kodePesanan(int id) => 'PSN-${id.toString().padLeft(4, '0')}';

  TransaksiKeuangan _buatTransaksi(Pesanan p, DateTime waktu) {
    final double total = p.estimasiBiaya;
    final double komisi = (total * komisiRate).roundToDouble();
    final TransaksiKeuangan t = TransaksiKeuangan(
      idTransaksi: ++_tid,
      idPesanan: p.idPesanan,
      totalBayar: total,
      komisiAdmin: komisi,
      pendapatanKru: total - komisi,
      waktuSelesai: waktu,
    );
    transaksi.add(t);
    return t;
  }

  /// Dipakai kolom pencarian (Dashboard & Master Pesanan).
  /// Mencari di: ID, pelanggan, kru, kategori, lokasi, detail, dan status.
  bool pesananCocok(Pesanan p, String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return _kodePesanan(p.idPesanan).toLowerCase().contains(q) ||
        namaUser(p.idPelanggan).toLowerCase().contains(q) ||
        namaUser(p.idKru).toLowerCase().contains(q) ||
        namaKategori(p.idKategori).toLowerCase().contains(q) ||
        p.lokasiJemput.toLowerCase().contains(q) ||
        p.lokasiAntar.toLowerCase().contains(q) ||
        p.detailPesanan.toLowerCase().contains(q) ||
        p.statusPesanan.label.toLowerCase().contains(q);
  }

  // -------------------------------------------------------------------------
  // Negosiasi harga (tabel negosiasi)
  //
  // Alur: pelanggan / kru mengajukan harga tawar -> pihak lawan menerima,
  // menolak, atau tawar ulang. Tawaran yang diterima menjadi harga final
  // pesanan (estimasi_biaya) dan menjadi dasar komisi admin.
  // -------------------------------------------------------------------------

  Negosiasi? _negoById(int id) {
    for (final Negosiasi n in negosiasi) {
      if (n.idNegosiasi == id) return n;
    }
    return null;
  }

  /// Riwayat tawaran satu pesanan, urut dari yang paling lama.
  List<Negosiasi> negosiasiPesanan(int idPesanan) {
    final List<Negosiasi> list =
        negosiasi.where((Negosiasi n) => n.idPesanan == idPesanan).toList()
          ..sort((Negosiasi a, Negosiasi b) => a.idNegosiasi.compareTo(b.idNegosiasi));
    return list;
  }

  Negosiasi? tawaranDisepakati(int idPesanan) {
    for (final Negosiasi n in negosiasi) {
      if (n.idPesanan == idPesanan && n.statusTawaran == StatusTawaran.diterima) {
        return n;
      }
    }
    return null;
  }

  Negosiasi? tawaranMenunggu(int idPesanan) {
    Negosiasi? hasil;
    for (final Negosiasi n in negosiasi) {
      if (n.idPesanan == idPesanan && n.statusTawaran == StatusTawaran.menunggu) {
        if (hasil == null || n.idNegosiasi > hasil.idNegosiasi) hasil = n;
      }
    }
    return hasil;
  }

  int get jumlahTawaranMenunggu =>
      negosiasi.where((Negosiasi n) => n.statusTawaran == StatusTawaran.menunggu).length;

  /// Pesanan bernegosiasi bila kategorinya bertipe harga "Negosiasi".
  bool pesananBisaNego(Pesanan p) {
    final KategoriLayanan? k = kategoriById(p.idKategori);
    return k != null && k.negosiasi;
  }

  String? ajukanTawaran({
    required int idPesanan,
    required int idPengirim,
    required double harga,
  }) {
    final Pesanan? p = pesananById(idPesanan);
    if (p == null) return 'Pesanan tidak ditemukan.';
    if (!pesananBisaNego(p)) {
      return 'Kategori pesanan ini memakai harga otomatis, tidak ada negosiasi.';
    }
    if (p.statusPesanan == StatusPesanan.selesai ||
        p.statusPesanan == StatusPesanan.dibatalkan) {
      return 'Pesanan ${p.statusPesanan.label.toLowerCase()}, negosiasi sudah ditutup.';
    }
    if (tawaranDisepakati(idPesanan) != null) {
      return 'Harga sudah disepakati, negosiasi sudah ditutup.';
    }
    if (harga <= 0) return 'Harga tawar harus lebih dari 0.';
    final UserModel? pengirim = userById(idPengirim);
    if (pengirim == null) return 'Pengirim tawaran tidak valid.';
    final bool pelangganPesanan = pengirim.idUser == p.idPelanggan;
    final bool kruPesanan = pengirim.role == UserRole.kru &&
        (p.idKru == null || p.idKru == pengirim.idUser);
    if (!pelangganPesanan && !kruPesanan) {
      return 'Pengirim harus pelanggan pesanan ini atau kru yang menanganinya.';
    }
    // Tawar ulang: tawaran lama yang masih menunggu otomatis ditolak.
    for (final Negosiasi n in negosiasi) {
      if (n.idPesanan == idPesanan && n.statusTawaran == StatusTawaran.menunggu) {
        n.statusTawaran = StatusTawaran.ditolak;
      }
    }
    negosiasi.add(Negosiasi(
      idNegosiasi: ++_nid,
      idPesanan: idPesanan,
      idPengirim: idPengirim,
      hargaTawar: harga,
      statusTawaran: StatusTawaran.menunggu,
      createdAt: DateTime.now(),
    ));
    _log('Tawaran ${rupiah(harga)} pada ${_kodePesanan(idPesanan)}', 1);
    notifyListeners();
    return null;
  }

  String? terimaTawaran(int idNegosiasi) {
    final Negosiasi? t = _negoById(idNegosiasi);
    if (t == null) return 'Tawaran tidak ditemukan.';
    final Pesanan? p = pesananById(t.idPesanan);
    if (p == null) return 'Pesanan tidak ditemukan.';
    if (t.statusTawaran != StatusTawaran.menunggu) return 'Tawaran ini sudah diproses.';
    if (p.statusPesanan == StatusPesanan.selesai ||
        p.statusPesanan == StatusPesanan.dibatalkan) {
      return 'Pesanan ${p.statusPesanan.label.toLowerCase()}, tawaran tidak dapat diterima.';
    }
    for (final Negosiasi n in negosiasi) {
      if (n.idPesanan == t.idPesanan &&
          n.idNegosiasi != t.idNegosiasi &&
          n.statusTawaran == StatusTawaran.menunggu) {
        n.statusTawaran = StatusTawaran.ditolak;
      }
    }
    t.statusTawaran = StatusTawaran.diterima;
    p.estimasiBiaya = t.hargaTawar;
    // Bila tawaran datang dari kru, kru tersebut otomatis memegang pesanan.
    final UserModel? pengirim = userById(t.idPengirim);
    if (pengirim != null && pengirim.role == UserRole.kru) {
      p.idKru = pengirim.idUser;
      if (p.statusPesanan == StatusPesanan.menunggu) {
        p.statusPesanan = StatusPesanan.diambil;
      }
    }
    _log('Harga ${_kodePesanan(p.idPesanan)} disepakati ${rupiah(t.hargaTawar)}', 0);
    notifyListeners();
    return null;
  }

  String? tolakTawaran(int idNegosiasi) {
    final Negosiasi? t = _negoById(idNegosiasi);
    if (t == null) return 'Tawaran tidak ditemukan.';
    if (t.statusTawaran != StatusTawaran.menunggu) return 'Tawaran ini sudah diproses.';
    t.statusTawaran = StatusTawaran.ditolak;
    _log('Menolak tawaran ${rupiah(t.hargaTawar)} pada ${_kodePesanan(t.idPesanan)}', 3);
    notifyListeners();
    return null;
  }

  // -------------------------------------------------------------------------
  // Profil
  // -------------------------------------------------------------------------

  String? ubahProfil(String nama, String email, String telepon) {
    final UserModel? u = currentUser;
    if (u == null) return 'Sesi berakhir. Silakan masuk kembali.';
    if (_emailTerpakai(email, kecualiId: u.idUser)) return 'Email sudah digunakan pengguna lain.';
    u.namaLengkap = nama.trim();
    u.email = email.trim();
    u.noTelepon = telepon.trim();
    _log('Memperbarui profil', 2);
    notifyListeners();
    return null;
  }

  String? ubahPassword(String lama, String baru) {
    final UserModel? u = currentUser;
    if (u == null) return 'Sesi berakhir. Silakan masuk kembali.';
    if (u.passwordHash != hashPassword(lama)) return 'Kata sandi lama tidak sesuai.';
    u.passwordHash = hashPassword(baru);
    _log('Memperbarui kata sandi', 2);
    notifyListeners();
    return null;
  }

  void _log(String text, int colorIndex) {
    activities.insert(0, ActivityLog(text, DateTime.now(), colorIndex));
    if (activities.length > 20) activities.removeLast();
  }

  // -------------------------------------------------------------------------
  // Data awal (contoh). Hapus saat sudah memakai database.
  // -------------------------------------------------------------------------

  UserModel _seedUser(String nama, String email, String telp, UserRole role, String pass,
      {String? krs}) {
    final UserModel u = UserModel(
      idUser: ++_uid,
      namaLengkap: nama,
      email: email,
      passwordHash: hashPassword(pass),
      noTelepon: telp,
      role: role,
      jadwalKrs: krs,
    );
    users.add(u);
    return u;
  }

  KategoriLayanan _seedKategori(String nama, double tarif, String desk, int warna) {
    final KategoriLayanan k = KategoriLayanan(
      idKategori: ++_kid,
      namaKategori: nama,
      tarifDasarKm: tarif,
      deskripsi: desk,
      warnaIndex: warna,
    );
    kategori.add(k);
    return k;
  }

  void _seed() {
    // Akun login contoh:
    //   admin     : sultan@email.com / admin123
    //   kru       : rafi.h@email.com / kru12345
    //   pelanggan : nadia.p@email.com / user1234
    _seedUser('Kak Sultan', 'sultan@email.com', '081100000001',
        UserRole.admin, 'admin123');
    _seedUser('Kak Hikmal', 'hikmal@email.com', '081100000002', UserRole.admin, 'admin123');
    final UserModel rafi = _seedUser('Rafi Hidayat', 'rafi.h@email.com', '081278017801',
        UserRole.kru, 'kru12345',
        krs: 'Senin 08.00-10.30 Hukum Pidana - Rabu 13.00-15.30 Manajemen Keuangan');
    final UserModel dimas = _seedUser('Dimas Saputra', 'dimas.s@email.com', '081322102210',
        UserRole.kru, 'kru12345',
        krs: 'Selasa 08.00-10.30 Basis Data');
    final UserModel alya = _seedUser('Alya Rahma', 'alya.r@email.com', '085744324432',
        UserRole.kru, 'kru12345',
        krs: 'Kamis 10.00-12.30 Akuntansi');
    final UserModel kevin = _seedUser('Kevin Wijaya', 'kevin.w@email.com', '087890879087',
        UserRole.kru, 'kru12345',
        krs: 'Jumat 08.00-10.30 Pemrograman Desktop');
    final UserModel nadia = _seedUser('Nadia Putri', 'nadia.p@email.com', '082111561156',
        UserRole.pelanggan, 'user1234');
    final UserModel rizky = _seedUser('Rizky Ananda', 'rizky.a@email.com', '089666246624',
        UserRole.pelanggan, 'user1234');
    final UserModel salsa = _seedUser('Salsa Maharani', 'salsa.m@email.com', '081255550084',
        UserRole.pelanggan, 'user1234');
    final UserModel bagas = _seedUser('Bagas Pratama', 'bagas.p@email.com', '081255550083',
        UserRole.pelanggan, 'user1234');
    final UserModel intan = _seedUser('Intan Lestari', 'intan.l@email.com', '081255550082',
        UserRole.pelanggan, 'user1234');
    final UserModel fikri = _seedUser('Fikri Ramadhan', 'fikri.r@email.com', '081255550081',
        UserRole.pelanggan, 'user1234');

    final KategoriLayanan jastip = _seedKategori('Jastip Makanan', 2500, 'Beli & antar makanan/minuman', 0);
    final KategoriLayanan laundry = _seedKategori('Pengambilan Laundry', 2000, 'Ambil & antar cucian', 1);
    final KategoriLayanan cetak = _seedKategori('Cetak Dokumen', 2000, 'Print, fotokopi & jilid', 2);
    final KategoriLayanan skripsi = _seedKategori('Berkas Skripsi / Wisuda', 3000, 'Pengambilan toga & berkas', 3);
    final KategoriLayanan pindahan =
        _seedKategori('Pindahan Kos', 0, 'Angkut & antar barang kos', 4);
    final KategoriLayanan khusus = _seedKategori('Jasa Khusus / Unik', 0, 'Permintaan di luar katalog', 5);
    final KategoriLayanan lainnya = _seedKategori('Lainnya (Request)', 0,
        'Layanan di luar daftar: pelanggan menulis sendiri permintaannya, harga dinegosiasikan', 5);

    final DateTime d15 = DateTime(2026, 10, 15);
    final DateTime d14 = DateTime(2026, 10, 14);

    void psn(int id, UserModel pel, UserModel? kru, KategoriLayanan kat, String jemput,
        String antar, DateTime waktu, String detail, double biaya, StatusPesanan st) {
      final Pesanan p = Pesanan(
        idPesanan: id,
        idPelanggan: pel.idUser,
        idKru: kru?.idUser,
        idKategori: kat.idKategori,
        lokasiJemput: jemput,
        lokasiAntar: antar,
        waktuDibutuhkan: waktu,
        detailPesanan: detail,
        estimasiBiaya: biaya,
        statusPesanan: st,
        createdAt: waktu.subtract(const Duration(hours: 1)),
      );
      pesanan.add(p);
      if (st == StatusPesanan.selesai) {
        _buatTransaksi(p, waktu.add(const Duration(minutes: 20)));
      }
    }

    psn(76, bagas, alya, jastip, 'Kantin FT', 'Kos MERR', d14.add(const Duration(hours: 10)),
        'Ayam geprek 2 porsi', 25000, StatusPesanan.selesai);
    psn(77, salsa, kevin, skripsi, 'Biro Akademik', 'Kos Gunung Anyar',
        d14.add(const Duration(hours: 11)), 'Ambil berkas wisuda', 60000, StatusPesanan.selesai);
    psn(78, rizky, dimas, cetak, 'Fotokopi Rungkut', 'Kampus FH',
        d14.add(const Duration(hours: 16)), 'Print 40 halaman', 15000, StatusPesanan.selesai);
    psn(79, nadia, rafi, jastip, 'Kantin FIK', 'Kos Medokan', d15.add(const Duration(hours: 12)),
        'Nasi goreng + es teh', 10000, StatusPesanan.selesai);
    psn(81, fikri, null, jastip, 'Kantin FEB', 'Gedung Rektorat',
        d14.add(const Duration(hours: 11, minutes: 45)), 'Mie ayam 1 porsi', 10000,
        StatusPesanan.dibatalkan);
    psn(82, intan, kevin, khusus, 'Kejutan ulang tahun', 'Kos Rungkut Asri',
        d14.add(const Duration(hours: 18)), 'Tim sukses kejutan ulang tahun', 120000,
        StatusPesanan.selesai);
    psn(83, bagas, alya, laundry, 'Laundry Rungkut', 'Kos MERR', d15.add(const Duration(hours: 10)),
        'Cucian 3 kg', 12000, StatusPesanan.selesai);
    psn(84, salsa, dimas, skripsi, 'Biro Akademik', 'Kos Gunung Anyar',
        d15.add(const Duration(hours: 14)), 'Ambil toga', 25000, StatusPesanan.diambil);
    psn(85, rizky, null, cetak, 'Fotokopi Rungkut', 'Kampus FH',
        d15.add(const Duration(hours: 13, minutes: 30)), 'Print skripsi 80 halaman', 8000,
        StatusPesanan.menunggu);
    psn(88, nadia, rafi, jastip, 'Kantin FIK', 'Kos Medokan', d15.add(const Duration(hours: 12)),
        'Nasi goreng 2 porsi + es teh', 10000, StatusPesanan.dikerjakan);

    psn(86, fikri, null, pindahan, 'Kos Medokan', 'Kos Rungkut Asri',
        d15.add(const Duration(hours: 15)), 'Angkut 2 kardus + 1 kasur lipat', 150000,
        StatusPesanan.menunggu);
    psn(87, salsa, null, lainnya, 'Apotek Rungkut', 'Kos Gunung Anyar',
        d15.add(const Duration(hours: 16)), 'Titip beli obat flu di apotek lalu antar ke kos',
        30000, StatusPesanan.menunggu);

    void tawar(int idPsn, UserModel pengirim, double harga, StatusTawaran st, DateTime waktu) {
      negosiasi.add(Negosiasi(
        idNegosiasi: ++_nid,
        idPesanan: idPsn,
        idPengirim: pengirim.idUser,
        hargaTawar: harga,
        statusTawaran: st,
        createdAt: waktu,
      ));
    }

    // Pesanan 82 (jasa khusus): tawar-menawar sampai sepakat Rp120.000.
    tawar(82, intan, 100000, StatusTawaran.ditolak,
        d14.add(const Duration(hours: 16, minutes: 40)));
    tawar(82, kevin, 140000, StatusTawaran.ditolak,
        d14.add(const Duration(hours: 16, minutes: 50)));
    tawar(82, intan, 120000, StatusTawaran.diterima,
        d14.add(const Duration(hours: 17, minutes: 5)));
    // Pesanan 86 (pindahan kos): kru menawar ulang, menunggu keputusan.
    tawar(86, fikri, 150000, StatusTawaran.ditolak,
        d15.add(const Duration(hours: 13, minutes: 10)));
    tawar(86, dimas, 200000, StatusTawaran.menunggu,
        d15.add(const Duration(hours: 13, minutes: 25)));
    // Pesanan 87 (request di luar daftar): tawaran pelanggan menunggu kru.
    tawar(87, salsa, 30000, StatusTawaran.menunggu,
        d15.add(const Duration(hours: 14, minutes: 30)));

    ulasan.add(Ulasan(
        idUlasan: ++_rid, idPesanan: 79, idPelanggan: nadia.idUser, idKru: rafi.idUser,
        rating: 5, komentar: 'Cepat dan ramah', createdAt: d15));
    ulasan.add(Ulasan(
        idUlasan: ++_rid, idPesanan: 83, idPelanggan: bagas.idUser, idKru: alya.idUser,
        rating: 5, komentar: 'Cucian rapi', createdAt: d15));
    ulasan.add(Ulasan(
        idUlasan: ++_rid, idPesanan: 78, idPelanggan: rizky.idUser, idKru: dimas.idUser,
        rating: 4, komentar: 'Sesuai permintaan', createdAt: d14));

    currentUser = null;
  }
}

/// Satu instance dipakai seluruh aplikasi.
final AppStore store = AppStore();
