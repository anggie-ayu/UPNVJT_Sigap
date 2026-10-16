import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'negosiasi_dialog.dart';

class PesananPage extends StatefulWidget {
  const PesananPage({super.key});

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  String _query = '';
  StatusPesanan? _filter; // null = semua

  Widget _chip(String label, int count, StatusPesanan? status) {
    final bool selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _filter = status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.navy : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.text)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? AppColors.yellow : AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: selected ? AppColors.navy : AppColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _lihat(Pesanan p) {
    showDetail(context, 'Detail ${kodePsn(p.idPesanan)}', <MapEntry<String, String>>[
      MapEntry<String, String>('Pelanggan', store.namaUser(p.idPelanggan)),
      MapEntry<String, String>('Kategori', store.namaKategori(p.idKategori)),
      MapEntry<String, String>('Kru', store.namaUser(p.idKru)),
      MapEntry<String, String>('Lokasi jemput', p.lokasiJemput),
      MapEntry<String, String>('Lokasi antar', p.lokasiAntar),
      MapEntry<String, String>('Waktu dibutuhkan', tglWaktu(p.waktuDibutuhkan)),
      MapEntry<String, String>('Detail pesanan', p.detailPesanan.isEmpty ? '—' : p.detailPesanan),
      MapEntry<String, String>('Estimasi biaya', rupiah(p.estimasiBiaya)),
      MapEntry<String, String>('Negosiasi', _ringkasNego(p)),
      MapEntry<String, String>('Status', p.statusPesanan.label),
      MapEntry<String, String>('Dibuat', tglWaktu(p.createdAt)),
    ]);
  }

  /// Ringkasan negosiasi satu pesanan (teks), dipakai di dialog detail.
  String _ringkasNego(Pesanan p) {
    if (!store.pesananBisaNego(p)) return 'Tidak ada (harga otomatis)';
    final Negosiasi? sepakat = store.tawaranDisepakati(p.idPesanan);
    if (sepakat != null) return 'Harga disepakati ${rupiah(sepakat.hargaTawar)}';
    final int n = store.negosiasiPesanan(p.idPesanan).length;
    if (n == 0) return 'Belum ada tawaran';
    if (store.tawaranMenunggu(p.idPesanan) != null) return '$n tawaran · menunggu keputusan';
    return '$n tawaran · belum ada kesepakatan';
  }

  /// Baris kedua kolom kategori: untuk kategori Lainnya tampilkan permintaannya.
  String _labelKategori(Pesanan p) {
    final KategoriLayanan? k = store.kategoriById(p.idKategori);
    final String detail = p.detailPesanan.trim();
    if (k != null && k.lainnya && detail.isNotEmpty) {
      return '${k.namaKategori}: $detail';
    }
    return store.namaKategori(p.idKategori);
  }

  Widget _estimasi(Pesanan p) {
    String? info;
    Color warna = AppColors.muted;
    if (store.pesananBisaNego(p)) {
      if (store.tawaranDisepakati(p.idPesanan) != null) {
        info = 'Nego: disepakati';
        warna = AppColors.green;
      } else if (store.tawaranMenunggu(p.idPesanan) != null) {
        info = 'Nego: menunggu';
        warna = AppColors.amber;
      } else {
        info = 'Nego: belum ada';
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        cellText(rupiah(p.estimasiBiaya), bold: true),
        if (info != null) cellText(info, size: 10, color: warna),
      ],
    );
  }

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _dropdownBox<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        hint: hint == null ? null : Text(hint, style: const TextStyle(fontSize: 13)),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: const TextStyle(fontSize: 13, color: AppColors.text),
      ),
    );
  }

  /// Dialog tambah (p == null) / ubah pesanan.
  Future<void> _form(Pesanan? p) async {
    final GlobalKey<FormState> key = GlobalKey<FormState>();
    final TextEditingController jemput = TextEditingController(text: p?.lokasiJemput ?? '');
    final TextEditingController antar = TextEditingController(text: p?.lokasiAntar ?? '');
    final TextEditingController detail = TextEditingController(text: p?.detailPesanan ?? '');
    final TextEditingController biaya = TextEditingController(
        text: p == null ? '' : p.estimasiBiaya.round().toString());
    int? pelanggan = p?.idPelanggan;
    int? kategori = p?.idKategori;
    int? kru = p?.idKru;
    StatusPesanan status = p?.statusPesanan ?? StatusPesanan.menunggu;
    DateTime waktu = p?.waktuDibutuhkan ?? DateTime.now().add(const Duration(hours: 1));
    String? error;
    final bool terkunci = p != null && p.statusPesanan == StatusPesanan.selesai;
    final List<UserModel> daftarPelanggan =
        store.users.where((UserModel u) => u.role == UserRole.pelanggan).toList();
    final List<UserModel> daftarKru = store.daftarKru;

    final bool? hasil = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setLocal) {
            final KategoriLayanan? katPilih =
                kategori == null ? null : store.kategoriById(kategori!);
            final bool lainnya = katPilih?.lainnya ?? false;
            final bool nego = katPilih?.negosiasi ?? false;
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(p == null ? 'Tambah Pesanan' : 'Ubah ${kodePsn(p.idPesanan)}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                          terkunci
                              ? 'Pesanan selesai tidak dapat diubah.'
                              : 'Isi data sesuai tabel pesanan.',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Form(
                            key: key,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _lbl('Pelanggan'),
                                _dropdownBox<int?>(
                                  value: pelanggan,
                                  hint: 'Pilih pelanggan',
                                  items: <DropdownMenuItem<int?>>[
                                    for (final UserModel u in daftarPelanggan)
                                      DropdownMenuItem<int?>(
                                          value: u.idUser, child: Text(u.namaLengkap)),
                                  ],
                                  onChanged: terkunci
                                      ? null
                                      : (int? v) => setLocal(() => pelanggan = v),
                                ),
                                const SizedBox(height: 12),
                                _lbl('Kategori layanan'),
                                _dropdownBox<int?>(
                                  value: kategori,
                                  hint: 'Pilih kategori',
                                  items: <DropdownMenuItem<int?>>[
                                    for (final KategoriLayanan k in store.kategori)
                                      DropdownMenuItem<int?>(
                                          value: k.idKategori, child: Text(k.namaKategori)),
                                  ],
                                  onChanged: terkunci
                                      ? null
                                      : (int? v) => setLocal(() => kategori = v),
                                ),
                                if (nego) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      lainnya
                                          ? 'Kategori Lainnya: tulis layanan yang diminta pelanggan pada kolom di bawah. Harga ditentukan lewat negosiasi.'
                                          : 'Kategori ini memakai negosiasi: harga akhir ditentukan lewat tombol Negosiasi pada baris pesanan.',
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.navy, height: 1.4),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: AppField(
                                        controller: jemput,
                                        label: 'Lokasi jemput',
                                        hint: 'Contoh: Kantin FIK',
                                        enabled: !terkunci,
                                        validator: (String? v) =>
                                            Validators.wajib(v, 'Lokasi jemput wajib diisi'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AppField(
                                        controller: antar,
                                        label: 'Lokasi antar',
                                        hint: 'Contoh: Kos Medokan',
                                        enabled: !terkunci,
                                        validator: (String? v) =>
                                            Validators.wajib(v, 'Lokasi antar wajib diisi'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _lbl('Waktu dibutuhkan'),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    onPressed: terkunci
                                        ? null
                                        : () async {
                                            final DateTime? d = await showDatePicker(
                                              context: ctx2,
                                              initialDate: waktu,
                                              firstDate: DateTime(2024),
                                              lastDate: DateTime(2100),
                                            );
                                            if (d == null || !ctx2.mounted) return;
                                            final TimeOfDay? t = await showTimePicker(
                                              context: ctx2,
                                              initialTime: TimeOfDay.fromDateTime(waktu),
                                            );
                                            if (t == null) return;
                                            setLocal(() => waktu = DateTime(
                                                d.year, d.month, d.day, t.hour, t.minute));
                                          },
                                    icon: const Icon(Icons.event, size: 16),
                                    label: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(tglWaktu(waktu)),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.text,
                                      side: const BorderSide(color: AppColors.border),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppField(
                                  controller: detail,
                                  label: lainnya ? 'Layanan yang diminta pelanggan' : 'Detail pesanan',
                                  hint: lainnya
                                      ? 'Tulis layanan di luar daftar, contoh: titip beli obat di apotek lalu antar ke kos'
                                      : 'Contoh: Nasi goreng 2 porsi + es teh',
                                  maxLines: 3,
                                  enabled: !terkunci,
                                  validator: lainnya
                                      ? (String? v) => Validators.wajib(
                                          v, 'Tuliskan layanan yang diminta pelanggan')
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                AppField(
                                  controller: biaya,
                                  label: nego ? 'Harga awal / usulan (Rp)' : 'Estimasi biaya (Rp)',
                                  hint: '10000',
                                  keyboardType: TextInputType.number,
                                  enabled: !terkunci,
                                  validator: (String? v) {
                                    final double? n = double.tryParse((v ?? '').trim());
                                    if (n == null || n <= 0) {
                                      return 'Isi biaya berupa angka lebih dari 0';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          _lbl('Status pesanan'),
                                          _dropdownBox<StatusPesanan>(
                                            value: status,
                                            items: <DropdownMenuItem<StatusPesanan>>[
                                              for (final StatusPesanan s
                                                  in StatusPesanan.values)
                                                DropdownMenuItem<StatusPesanan>(
                                                    value: s, child: Text(s.label)),
                                            ],
                                            onChanged: terkunci
                                                ? null
                                                : (StatusPesanan? v) {
                                                    if (v != null) {
                                                      setLocal(() => status = v);
                                                    }
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          _lbl('Kru'),
                                          _dropdownBox<int?>(
                                            value: kru,
                                            items: <DropdownMenuItem<int?>>[
                                              const DropdownMenuItem<int?>(
                                                  value: null,
                                                  child: Text('— Belum ada —')),
                                              for (final UserModel u in daftarKru)
                                                DropdownMenuItem<int?>(
                                                    value: u.idUser,
                                                    child: Text(u.namaLengkap)),
                                            ],
                                            onChanged: terkunci
                                                ? null
                                                : (int? v) => setLocal(() => kru = v),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (error != null) ...<Widget>[
                                  const SizedBox(height: 12),
                                  Text(error!,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.red)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: GhostButton(
                              label: 'Batal',
                              onPressed: () => Navigator.of(ctx).pop(false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Simpan',
                              icon: Icons.check,
                              onPressed: terkunci
                                  ? null
                                  : () {
                                      if (!key.currentState!.validate()) return;
                                      if (pelanggan == null || kategori == null) {
                                        setLocal(() =>
                                            error = 'Pilih pelanggan dan kategori terlebih dahulu.');
                                        return;
                                      }
                                      final String? err = store.simpanPesanan(
                                        id: p?.idPesanan,
                                        idPelanggan: pelanggan!,
                                        idKru: kru,
                                        idKategori: kategori!,
                                        lokasiJemput: jemput.text,
                                        lokasiAntar: antar.text,
                                        waktu: waktu,
                                        detail: detail.text,
                                        biaya: double.parse(biaya.text.trim()),
                                        status: status,
                                      );
                                      if (err != null) {
                                        setLocal(() => error = err);
                                        return;
                                      }
                                      Navigator.of(ctx).pop(true);
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (hasil == true && mounted) {
      toast(context, p == null ? 'Pesanan berhasil ditambahkan.' : 'Pesanan berhasil diperbarui.');
    }
  }

  Future<void> _hapus(Pesanan p) async {
    final bool ok = await showConfirm(
      context,
      title: 'Hapus pesanan?',
      message: 'Pesanan ${kodePsn(p.idPesanan)} akan dihapus permanen.',
      confirmLabel: 'Ya, Hapus',
      icon: Icons.delete_outline,
    );
    if (!ok || !mounted) return;
    final String? err = store.hapusPesanan(p.idPesanan);
    toast(context, err ?? 'Pesanan dihapus.', error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, Widget? _) {
        final String q = _query.trim().toLowerCase();
        final List<Pesanan> data = store.pesanan.where((Pesanan p) {
          if (_filter != null && p.statusPesanan != _filter) return false;
          return store.pesananCocok(p, q);
        }).toList()
          ..sort((Pesanan a, Pesanan b) => b.idPesanan.compareTo(a.idPesanan));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PageHeader(
              title: 'Master Pesanan',
              subtitle: 'Pantau & kelola semua pesanan · tabel pesanan',
              onSearch: (String v) => setState(() => _query = v),
              searchHint: 'Cari ID, pelanggan, kru, kategori, lokasi...',
              trailing: ElevatedButton.icon(
                onPressed: () => _form(null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Pesanan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              runSpacing: 8,
              children: <Widget>[
                _chip('Semua', store.pesanan.length, null),
                for (final StatusPesanan s in StatusPesanan.values)
                  _chip(s.label, store.countStatus(s), s),
              ],
            ),
            const SizedBox(height: 16),
            if (store.jumlahTawaranMenunggu > 0) ...<Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.forum_outlined, size: 16, color: AppColors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${store.jumlahTawaranMenunggu} tawaran harga menunggu keputusan. Klik ikon Negosiasi pada pesanan terkait untuk menerima, menolak, atau tawar ulang.',
                        style: const TextStyle(fontSize: 11, color: AppColors.navy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SearchInfo(query: _query, found: data.length, total: store.pesanan.length),
            CardBox(
              child: Column(
                children: <Widget>[
                  TableHead(
                    trailing: RowActions.widthNego,
                    cols: const <MapEntry<String, int>>[
                      MapEntry<String, int>('ID', 2),
                      MapEntry<String, int>('Pelanggan & kategori', 3),
                      MapEntry<String, int>('Jemput → Antar', 3),
                      MapEntry<String, int>('Waktu', 2),
                      MapEntry<String, int>('Kru', 2),
                      MapEntry<String, int>('Status', 3),
                      MapEntry<String, int>('Estimasi', 2),
                    ],
                  ),
                  if (data.isEmpty) const EmptyRow('Tidak ada pesanan yang cocok.'),
                  for (final Pesanan p in data)
                    TableRowBox(children: <Widget>[
                      Expanded(
                          flex: 2,
                          child: cellText(kodePsn(p.idPesanan),
                              bold: true, color: AppColors.green)),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            cellText(store.namaUser(p.idPelanggan), bold: true),
                            cellText(_labelKategori(p),
                                size: 10, color: AppColors.muted),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            cellText(p.lokasiJemput),
                            cellText('→ ${p.lokasiAntar}', size: 10, color: AppColors.muted),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: cellText(tglWaktu(p.waktuDibutuhkan))),
                      Expanded(
                        flex: 2,
                        child: p.idKru == null
                            ? cellText('—', color: AppColors.muted)
                            : Row(
                                children: <Widget>[
                                  Avatar(
                                    name: store.namaUser(p.idKru),
                                    color: AppColors.palette[
                                        p.idKru! % AppColors.palette.length],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                      child: cellText(store.namaUser(p.idKru), bold: true)),
                                ],
                              ),
                      ),
                      Expanded(
                        flex: 3,
                        child: leftAlign(
                            Pill(p.statusPesanan.label, statusColor(p.statusPesanan))),
                      ),
                      Expanded(flex: 2, child: _estimasi(p)),
                      RowActions(
                        onView: () => _lihat(p),
                        onNego: () => showNegosiasiDialog(context, p.idPesanan),
                        onEdit: () => _form(p),
                        onDelete: () => _hapus(p),
                      ),
                    ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Alur Status Pesanan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('Status diperbarui kru & memicu notifikasi otomatis ke pelanggan',
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      _langkah(1, 'Menunggu Helper', StatusPesanan.menunggu),
                      _panah(),
                      _langkah(2, 'Diambil', StatusPesanan.diambil),
                      _panah(),
                      _langkah(3, 'Sedang Dikerjakan', StatusPesanan.dikerjakan),
                      _panah(),
                      _langkah(4, 'Selesai', StatusPesanan.selesai),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _panah() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.arrow_forward, size: 16, color: AppColors.muted),
      );

  Widget _langkah(int no, String label, StatusPesanan s) {
    final Color c = statusColor(s);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: c.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child: Text('$no',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Expanded(child: cellText(label, bold: true)),
          ],
        ),
      ),
    );
  }
}
