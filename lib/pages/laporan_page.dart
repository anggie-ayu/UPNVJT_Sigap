import 'package:flutter/material.dart';

import '../core/export_excel.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String _query = '';

  Future<void> _ekspor() {
    final List<TransaksiKeuangan> urut = <TransaksiKeuangan>[...store.transaksi]
      ..sort((TransaksiKeuangan a, TransaksiKeuangan b) =>
          b.waktuSelesai.compareTo(a.waktuSelesai));
    return eksporKeExcel(
      context,
      namaDasar: 'sigap_laporan_keuangan',
      namaSheet: 'Laporan Keuangan',
      header: <String>[
        'ID Transaksi',
        'ID Pesanan',
        'Kategori',
        'Pelanggan',
        'Kru',
        'Total Bayar (Rp)',
        'Komisi Admin 8% (Rp)',
        'Pendapatan Kru (Rp)',
        'Waktu Selesai',
      ],
      lebarKolom: <double>[16, 14, 26, 22, 22, 18, 22, 20, 20],
      baris: <List<Object?>>[
        for (final TransaksiKeuangan t in urut)
          <Object?>[
            kodeTrx(t.idTransaksi),
            kodePsn(t.idPesanan),
            store.namaKategori(store.pesananById(t.idPesanan)?.idKategori ?? 0),
            store.namaUser(store.pesananById(t.idPesanan)?.idPelanggan),
            store.namaUser(store.pesananById(t.idPesanan)?.idKru),
            t.totalBayar.round(),
            t.komisiAdmin.round(),
            t.pendapatanKru.round(),
            formatWaktuExcel(t.waktuSelesai),
          ],
        <Object?>[
          'TOTAL',
          '',
          '',
          '',
          '',
          store.totalTransaksi.round(),
          store.totalKomisi.round(),
          store.totalPendapatanKru.round(),
          '',
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
        final List<TransaksiKeuangan> semua = <TransaksiKeuangan>[...store.transaksi]
          ..sort((TransaksiKeuangan a, TransaksiKeuangan b) =>
              b.waktuSelesai.compareTo(a.waktuSelesai));
        final List<TransaksiKeuangan> data = semua.where((TransaksiKeuangan t) {
          if (q.isEmpty) return true;
          final Pesanan? p = store.pesananById(t.idPesanan);
          final String kategori = p == null ? '' : store.namaKategori(p.idKategori);
          return kodeTrx(t.idTransaksi).toLowerCase().contains(q) ||
              kodePsn(t.idPesanan).toLowerCase().contains(q) ||
              kategori.toLowerCase().contains(q);
        }).toList();

        final double total = store.totalTransaksi;
        final double komisi = store.totalKomisi;
        final double kru = store.totalPendapatanKru;
        final int persenKru = total == 0 ? 0 : (kru / total * 100).round();
        final int persenAdmin = total == 0 ? 0 : 100 - persenKru;
        final TransaksiKeuangan? contoh = semua.isEmpty ? null : semua.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PageHeader(
              title: 'Laporan Keuangan',
              subtitle: 'Transaksi & komisi admin 8% · tabel transaksi_keuangan',
              onSearch: (String v) => setState(() => _query = v),
              searchHint: 'Cari ID transaksi, ID pesanan, kategori...',
              trailing: ElevatedButton.icon(
                onPressed: _ekspor,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Ekspor ke Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    color: AppColors.green,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Total Transaksi',
                    value: rupiah(total),
                    caption: '${store.transaksi.length} pesanan selesai',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    color: AppColors.red,
                    icon: Icons.trending_up,
                    label: 'Komisi Admin 8%',
                    value: rupiah(komisi),
                    caption: 'dipotong otomatis',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    color: AppColors.purple,
                    icon: Icons.groups_outlined,
                    label: 'Pendapatan Kru',
                    value: rupiah(kru),
                    caption: '$persenKru% dari total transaksi',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    color: AppColors.blue,
                    icon: Icons.star_outline,
                    label: 'Rating Layanan',
                    value: '${store.rataRating.toStringAsFixed(1).replaceAll('.', ',')} / 5',
                    caption: 'target minimal 4,0',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: CardBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Pembagian Pendapatan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('Setiap transaksi selesai dicatat otomatis & dapat diaudit',
                            style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 18,
                            child: total == 0
                                ? Container(color: AppColors.bg)
                                : Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: persenKru == 0 ? 1 : persenKru,
                                        child: Container(color: AppColors.purple),
                                      ),
                                      if (persenAdmin > 0)
                                        Expanded(
                                          flex: persenAdmin,
                                          child: Container(color: AppColors.red),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            _legend(AppColors.purple, 'Pendapatan kru $persenKru%', rupiah(kru)),
                            const SizedBox(width: 28),
                            _legend(AppColors.red, 'Komisi admin $persenAdmin%', rupiah(komisi)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CardBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Contoh Perhitungan Transparan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          contoh == null
                              ? 'Belum ada transaksi.'
                              : 'Pesanan ${kodePsn(contoh.idPesanan)} · ${store.namaKategori(store.pesananById(contoh.idPesanan)?.idKategori ?? 0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),
                        _hitung('Total bayar pelanggan',
                            contoh == null ? '—' : rupiah(contoh.totalBayar), AppColors.text),
                        const SizedBox(height: 8),
                        _hitung('Komisi (8%)',
                            contoh == null ? '—' : '- ${rupiah(contoh.komisiAdmin)}',
                            AppColors.red),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.green.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _hitung(
                            'Pendapatan bersih kru',
                            contoh == null ? '—' : rupiah(contoh.pendapatanKru),
                            AppColors.green,
                            bold: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Transaksi Terbaru',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SearchInfo(
              query: _query,
              found: data.length,
              total: semua.length,
            ),
            CardBox(
              child: Column(
                children: <Widget>[
                  TableHead(cols: const <MapEntry<String, int>>[
                    MapEntry<String, int>('ID transaksi', 2),
                    MapEntry<String, int>('Pesanan', 2),
                    MapEntry<String, int>('Kategori', 3),
                    MapEntry<String, int>('Total bayar', 2),
                    MapEntry<String, int>('Komisi 8%', 2),
                    MapEntry<String, int>('Pendapatan kru', 2),
                    MapEntry<String, int>('Waktu selesai', 2),
                  ]),
                  if (data.isEmpty) const EmptyRow('Belum ada transaksi.'),
                  for (final TransaksiKeuangan t in (q.isEmpty ? data.take(10) : data))
                    TableRowBox(children: <Widget>[
                      Expanded(
                          flex: 2,
                          child: cellText(kodeTrx(t.idTransaksi),
                              bold: true, color: AppColors.green)),
                      Expanded(flex: 2, child: cellText(kodePsn(t.idPesanan))),
                      Expanded(
                        flex: 3,
                        child: cellText(store.namaKategori(
                            store.pesananById(t.idPesanan)?.idKategori ?? 0)),
                      ),
                      Expanded(flex: 2, child: cellText(rupiah(t.totalBayar), bold: true)),
                      Expanded(
                          flex: 2,
                          child: cellText(rupiah(t.komisiAdmin),
                              bold: true, color: AppColors.red)),
                      Expanded(
                          flex: 2,
                          child: cellText(rupiah(t.pendapatanKru),
                              bold: true, color: AppColors.green)),
                      Expanded(flex: 2, child: cellText(tglWaktu(t.waktuSelesai))),
                    ]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _legend(Color c, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  Widget _hitung(String label, String value, Color color, {bool bold = false}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: bold ? color : AppColors.muted,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
