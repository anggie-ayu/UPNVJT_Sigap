import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _tarif = TextEditingController();
  final TextEditingController _desk = TextEditingController();

  String _query = '';
  KategoriLayanan? _editing;
  bool _negosiasi = false;
  int _warna = 0;

  @override
  void dispose() {
    _nama.dispose();
    _tarif.dispose();
    _desk.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _editing = null;
      _negosiasi = false;
      _warna = 0;
      _nama.clear();
      _tarif.clear();
      _desk.clear();
    });
    _formKey.currentState?.reset();
  }

  void _edit(KategoriLayanan k) {
    setState(() {
      _editing = k;
      _negosiasi = k.negosiasi;
      _warna = k.warnaIndex % AppColors.palette.length;
      _nama.text = k.namaKategori;
      _tarif.text = k.negosiasi ? '' : k.tarifDasarKm.round().toString();
      _desk.text = k.deskripsi;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final double tarif = _negosiasi ? 0 : double.parse(_tarif.text.trim());
    final KategoriLayanan? edit = _editing;
    final String? err = edit == null
        ? store.tambahKategori(_nama.text, tarif, _desk.text, _warna)
        : store.ubahKategori(edit.idKategori, _nama.text, tarif, _desk.text, _warna);
    if (err != null) {
      toast(context, err, error: true);
      return;
    }
    toast(context, edit == null ? 'Kategori berhasil ditambahkan.' : 'Kategori berhasil diperbarui.');
    _reset();
  }

  Future<void> _hapus(KategoriLayanan k) async {
    final bool ok = await showConfirm(
      context,
      title: 'Hapus kategori?',
      message: 'Kategori "${k.namaKategori}" akan dihapus permanen.',
      confirmLabel: 'Ya, Hapus',
      icon: Icons.delete_outline,
    );
    if (!ok || !mounted) return;
    final String? err = store.hapusKategori(k.idKategori);
    if (err != null) {
      toast(context, err, error: true);
    } else {
      if (_editing?.idKategori == k.idKategori) _reset();
      toast(context, 'Kategori dihapus.');
    }
  }

  void _lihat(KategoriLayanan k) {
    showDetail(context, 'Detail Kategori', <MapEntry<String, String>>[
      MapEntry<String, String>('ID', kodeKtg(k.idKategori)),
      MapEntry<String, String>('Nama kategori', k.namaKategori),
      MapEntry<String, String>('Tarif dasar / km', k.negosiasi ? '—' : rupiah(k.tarifDasarKm)),
      MapEntry<String, String>('Tipe harga', k.negosiasi ? 'Negosiasi' : 'Otomatis'),
      MapEntry<String, String>('Jumlah pesanan', '${store.countKategori(k.idKategori)}'),
      MapEntry<String, String>('Deskripsi', k.deskripsi.isEmpty ? '—' : k.deskripsi),
    ]);
  }

  Future<void> _ekspor() {
    return eksporKeExcel(
      context,
      namaDasar: 'sigap_kategori_layanan',
      namaSheet: 'Kategori Layanan',
      header: <String>[
        'ID Kategori',
        'Nama Kategori',
        'Tarif Dasar per KM (Rp)',
        'Tipe Harga',
        'Jumlah Pesanan',
        'Deskripsi',
      ],
      lebarKolom: <double>[14, 28, 24, 14, 16, 50],
      baris: <List<Object?>>[
        for (final KategoriLayanan k in store.kategori)
          <Object?>[
            kodeKtg(k.idKategori),
            k.namaKategori,
            k.tarifDasarKm.round(),
            k.negosiasi ? 'Negosiasi' : 'Otomatis',
            store.countKategori(k.idKategori),
            k.deskripsi,
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, Widget? _) {
        final String q = _query.trim().toLowerCase();
        final List<KategoriLayanan> data = store.kategori.where((KategoriLayanan k) {
          if (q.isEmpty) return true;
          return k.namaKategori.toLowerCase().contains(q) ||
              k.deskripsi.toLowerCase().contains(q) ||
              kodeKtg(k.idKategori).toLowerCase().contains(q) ||
              (k.negosiasi ? 'negosiasi' : 'otomatis').contains(q);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PageHeader(
              title: 'Master Kategori Layanan',
              subtitle: 'Kelola kategori jasa & tarif dasar per km · tabel kategori_layanan',
              onSearch: (String v) => setState(() => _query = v),
              searchHint: 'Cari nama, deskripsi, tipe harga...',
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _tabel(data)),
                const SizedBox(width: 16),
                SizedBox(width: 300, child: _form()),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _tabel(List<KategoriLayanan> data) {
    return Column(
      children: <Widget>[
        SearchInfo(query: _query, found: data.length, total: store.kategori.length),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Pill('${store.kategori.length} kategori aktif', AppColors.green),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _ekspor,
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Ekspor'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TableHead(
                trailing: RowActions.width,
                cols: const <MapEntry<String, int>>[
                  MapEntry<String, int>('ID', 1),
                  MapEntry<String, int>('Kategori', 4),
                  MapEntry<String, int>('Tarif dasar/km', 2),
                  MapEntry<String, int>('Tipe harga', 2),
                  MapEntry<String, int>('Pesanan', 1),
                ],
              ),
              if (data.isEmpty) const EmptyRow('Tidak ada kategori yang cocok.'),
              for (final KategoriLayanan k in data)
                TableRowBox(children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: cellText(kodeKtg(k.idKategori), bold: true, color: AppColors.muted)),
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.palette[k.warnaIndex % AppColors.palette.length]
                                .withAlpha(40),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            kategoriIcon(k),
                            size: 16,
                            color: AppColors.palette[k.warnaIndex % AppColors.palette.length],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              cellText(k.namaKategori, bold: true),
                              cellText(k.deskripsi, size: 10, color: AppColors.muted),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      flex: 2,
                      child: cellText(k.negosiasi ? '—' : rupiah(k.tarifDasarKm), bold: true)),
                  Expanded(
                    flex: 2,
                    child: leftAlign(Pill(
                      k.negosiasi ? 'Negosiasi' : 'Otomatis',
                      k.negosiasi ? AppColors.amber : AppColors.blue,
                    )),
                  ),
                  Expanded(flex: 1, child: cellText('${store.countKategori(k.idKategori)}')),
                  RowActions(
                    onView: () => _lihat(k),
                    onEdit: () => _edit(k),
                    onDelete: () => _hapus(k),
                  ),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.yellow.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.star_outline, size: 16, color: AppColors.amber),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Otomatis: harga = tarif dasar per km × jarak (jastip standar Rp2.000–Rp3.000/km). Negosiasi: harga ditawar pelanggan & kru pada tiap pesanan (Master Pesanan → ikon Negosiasi). Kategori "Lainnya (Request)" dipakai pelanggan untuk meminta layanan di luar daftar dan bersifat tetap.',
                  style: TextStyle(fontSize: 11, color: AppColors.navy),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _form() {
    final bool edit = _editing != null;
    return CardBox(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(edit ? Icons.edit_outlined : Icons.add,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(edit ? 'Ubah Kategori' : 'Tambah Kategori Baru',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      const Text('Input master data kategori_layanan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppField(
              controller: _nama,
              label: 'Nama kategori',
              hint: 'Contoh: Titip Belanja Kebutuhan',
              icon: Icons.layers_outlined,
              validator: (String? v) => Validators.wajib(v, 'Nama kategori wajib diisi'),
            ),
            const SizedBox(height: 12),
            AppField(
              controller: _tarif,
              label: 'Tarif dasar per km (Rp)',
              hint: '2500',
              icon: Icons.payments_outlined,
              enabled: !_negosiasi,
              keyboardType: TextInputType.number,
              validator: (String? v) {
                if (_negosiasi) return null;
                final double? n = double.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Isi tarif berupa angka lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text('Tipe harga',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Segmented(
              labels: const <String>['Otomatis', 'Negosiasi'],
              index: _negosiasi ? 1 : 0,
              onChanged: (int i) => setState(() => _negosiasi = i == 1),
            ),
            const SizedBox(height: 6),
            Text(
              _negosiasi
                  ? 'Negosiasi: tarif per km tidak dipakai. Harga ditawar pelanggan & kru lewat tombol Negosiasi di Master Pesanan.'
                  : 'Otomatis: harga dihitung dari tarif dasar per km.',
              style: const TextStyle(fontSize: 10, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text('Warna label',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                for (int i = 0; i < AppColors.palette.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _warna = i),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.palette[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == _warna ? AppColors.navy : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppField(
              controller: _desk,
              label: 'Deskripsi singkat',
              hint: 'Jelaskan layanan untuk pelanggan...',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: PrimaryButton(
                    label: 'Simpan Kategori',
                    icon: Icons.check,
                    onPressed: _save,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: GhostButton(label: 'Batal', onPressed: _reset)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
