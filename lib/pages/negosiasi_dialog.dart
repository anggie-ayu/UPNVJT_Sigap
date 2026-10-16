import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../widgets/common.dart';

/// Membuka dialog negosiasi harga untuk satu pesanan (tabel `negosiasi`).
Future<void> showNegosiasiDialog(BuildContext context, int idPesanan) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 660),
          child: _NegosiasiPanel(idPesanan: idPesanan),
        ),
      );
    },
  );
}

Color _warnaTawaran(StatusTawaran s) {
  switch (s) {
    case StatusTawaran.menunggu:
      return AppColors.amber;
    case StatusTawaran.diterima:
      return AppColors.green;
    case StatusTawaran.ditolak:
      return AppColors.red;
  }
}

class _NegosiasiPanel extends StatefulWidget {
  const _NegosiasiPanel({required this.idPesanan});

  final int idPesanan;

  @override
  State<_NegosiasiPanel> createState() => _NegosiasiPanelState();
}

class _NegosiasiPanelState extends State<_NegosiasiPanel> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _harga = TextEditingController();
  int? _pengirim;
  String? _pesan;
  bool _pesanError = false;

  @override
  void dispose() {
    _harga.dispose();
    super.dispose();
  }

  void _kirim(Pesanan p) {
    if (!_formKey.currentState!.validate()) return;
    final int? pengirim = _pengirim;
    if (pengirim == null) {
      setState(() {
        _pesan = 'Pilih dulu siapa yang mengajukan tawaran.';
        _pesanError = true;
      });
      return;
    }
    final double harga = double.parse(_harga.text.trim());
    final String? err = store.ajukanTawaran(
      idPesanan: p.idPesanan,
      idPengirim: pengirim,
      harga: harga,
    );
    setState(() {
      _pesan = err ?? 'Tawaran ${rupiah(harga)} terkirim. Menunggu keputusan pihak lawan.';
      _pesanError = err != null;
      if (err == null) _harga.clear();
    });
  }

  void _terima(Negosiasi n) {
    final String? err = store.terimaTawaran(n.idNegosiasi);
    setState(() {
      _pesan = err ?? 'Tawaran ${rupiah(n.hargaTawar)} diterima. Harga pesanan kini ${rupiah(n.hargaTawar)}.';
      _pesanError = err != null;
    });
  }

  void _tolak(Negosiasi n) {
    final String? err = store.tolakTawaran(n.idNegosiasi);
    setState(() {
      _pesan = err ?? 'Tawaran ${rupiah(n.hargaTawar)} ditolak. Ajukan tawaran baru bila perlu.';
      _pesanError = err != null;
    });
  }

  Widget _banner(String text, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 11, color: AppColors.text, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, Widget nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
          Expanded(child: nilai),
        ],
      ),
    );
  }

  Widget _statusNego(Pesanan p, bool bisaNego, List<Negosiasi> riwayat) {
    if (!bisaNego) return leftAlign(const Pill('Harga otomatis', AppColors.blue));
    final Negosiasi? sepakat = store.tawaranDisepakati(p.idPesanan);
    if (sepakat != null) {
      return leftAlign(Pill('Disepakati ${rupiah(sepakat.hargaTawar)}', AppColors.green));
    }
    if (store.tawaranMenunggu(p.idPesanan) != null) {
      return leftAlign(const Pill('Menunggu keputusan', AppColors.amber));
    }
    if (riwayat.isEmpty) return leftAlign(const Pill('Belum ada tawaran', AppColors.muted));
    return leftAlign(const Pill('Menunggu tawaran baru', AppColors.amber));
  }

  Widget _barisTawaran(Negosiasi n, {required bool bisaRespon}) {
    final UserModel? u = store.userById(n.idPengirim);
    final String nama = u?.namaLengkap ?? '—';
    final bool diterima = n.statusTawaran == StatusTawaran.diterima;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: diterima ? AppColors.green.withAlpha(20) : AppColors.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: diterima ? AppColors.green : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Avatar(
                name: nama,
                color: AppColors.palette[(u?.idUser ?? 0) % AppColors.palette.length],
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(child: cellText(nama, bold: true)),
                        const SizedBox(width: 6),
                        if (u != null) Pill(u.role.label, roleColor(u.role)),
                      ],
                    ),
                    cellText(tglWaktu(n.createdAt), size: 10, color: AppColors.muted),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(rupiah(n.hargaTawar),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Pill(n.statusTawaran.label, _warnaTawaran(n.statusTawaran)),
                ],
              ),
            ],
          ),
          if (bisaRespon) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => _tolak(n),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Tolak'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _terima(n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Terima & sepakati'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _formTawaran(Pesanan p, bool tawarUlang) {
    final List<UserModel> opsi = <UserModel>[];
    final UserModel? pel = store.userById(p.idPelanggan);
    if (pel != null) opsi.add(pel);
    if (p.idKru != null) {
      final UserModel? kru = store.userById(p.idKru);
      if (kru != null) opsi.add(kru);
    } else {
      opsi.addAll(store.daftarKru);
    }
    final int? nilai =
        opsi.any((UserModel u) => u.idUser == _pengirim) ? _pengirim : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(tawarUlang ? 'Tawar ulang' : 'Ajukan tawaran',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        const Text(
            'Tawaran baru otomatis menolak tawaran yang masih menunggu keputusan.',
            style: TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Diajukan oleh',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 6),
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.field,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButton<int>(
                      value: nilai,
                      hint: const Text('Pilih pengirim', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 13, color: AppColors.text),
                      items: <DropdownMenuItem<int>>[
                        for (final UserModel u in opsi)
                          DropdownMenuItem<int>(
                            value: u.idUser,
                            child: Text('${u.namaLengkap} (${u.role.label})',
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (int? v) => setState(() => _pengirim = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppField(
                controller: _harga,
                label: 'Harga tawar (Rp)',
                hint: '25000',
                keyboardType: TextInputType.number,
                validator: (String? v) {
                  final double? n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Isi harga berupa angka lebih dari 0';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: tawarUlang ? 'Kirim Tawaran Ulang' : 'Kirim Tawaran',
          icon: Icons.send_outlined,
          onPressed: () => _kirim(p),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, Widget? _) {
        final Pesanan? p = store.pesananById(widget.idPesanan);
        if (p == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Pesanan tidak ditemukan.'),
          );
        }
        final KategoriLayanan? kat = store.kategoriById(p.idKategori);
        final bool bisaNego = store.pesananBisaNego(p);
        final List<Negosiasi> riwayat = store.negosiasiPesanan(p.idPesanan);
        final Negosiasi? sepakat = store.tawaranDisepakati(p.idPesanan);
        final Negosiasi? menunggu = store.tawaranMenunggu(p.idPesanan);
        final bool terkunci = p.statusPesanan == StatusPesanan.selesai ||
            p.statusPesanan == StatusPesanan.dibatalkan;
        final bool terbuka = bisaNego && !terkunci && sepakat == null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.forum_outlined, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Negosiasi ${kodePsn(p.idPesanan)}',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        const Text('Tawar-menawar harga antara pelanggan dan kru',
                            style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _banner(
                        'Cara kerja: (1) pelanggan atau kru mengajukan harga tawar. '
                        '(2) Pihak lawan menerima, menolak, atau tawar ulang. '
                        '(3) Tawaran yang diterima menjadi harga final pesanan dan '
                        'dasar komisi admin 8%.',
                        AppColors.blue,
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 14),
                      _info('Kategori',
                          cellText(kat?.namaKategori ?? '—', bold: true)),
                      _info('Pelanggan',
                          cellText(store.namaUser(p.idPelanggan), bold: true)),
                      _info('Kru', cellText(store.namaUser(p.idKru), bold: true)),
                      if (kat != null && kat.lainnya)
                        _info(
                          'Permintaan',
                          Text(
                            p.detailPesanan.trim().isEmpty ? '—' : p.detailPesanan.trim(),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      _info('Harga pesanan saat ini',
                          cellText(rupiah(p.estimasiBiaya), bold: true)),
                      _info('Status negosiasi', _statusNego(p, bisaNego, riwayat)),
                      const SizedBox(height: 14),
                      if (!bisaNego)
                        _banner(
                          'Kategori "${kat?.namaKategori ?? '—'}" memakai harga otomatis '
                          '(tarif per km), jadi tidak ada negosiasi. Ubah tipe harga menjadi '
                          '"Negosiasi" di Master Kategori bila kategori ini perlu ditawar.',
                          AppColors.amber,
                          Icons.lock_outline,
                        )
                      else ...<Widget>[
                        Text('Riwayat tawaran (${riwayat.length})',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        if (riwayat.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                                'Belum ada tawaran. Ajukan tawaran pertama pada form di bawah.',
                                style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          ),
                        for (final Negosiasi n in riwayat)
                          _barisTawaran(
                            n,
                            bisaRespon: terbuka &&
                                n.statusTawaran == StatusTawaran.menunggu &&
                                menunggu?.idNegosiasi == n.idNegosiasi,
                          ),
                        const SizedBox(height: 6),
                        if (terbuka)
                          _formTawaran(p, menunggu != null || riwayat.isNotEmpty)
                        else if (sepakat != null)
                          _banner(
                            'Negosiasi ditutup: harga disepakati ${rupiah(sepakat.hargaTawar)}.',
                            AppColors.green,
                            Icons.check_circle_outline,
                          )
                        else
                          _banner(
                            'Pesanan ${p.statusPesanan.label.toLowerCase()}, negosiasi sudah ditutup.',
                            AppColors.muted,
                            Icons.lock_outline,
                          ),
                      ],
                      if (_pesan != null) ...<Widget>[
                        const SizedBox(height: 12),
                        _banner(
                          _pesan!,
                          _pesanError ? AppColors.red : AppColors.green,
                          _pesanError ? Icons.error_outline : Icons.check_circle_outline,
                        ),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 110,
                  child: PrimaryButton(
                    label: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
