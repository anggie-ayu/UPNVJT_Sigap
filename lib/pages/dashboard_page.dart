import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onLihatSemua});

  final VoidCallback onLihatSemua;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, Widget? _) {
        final DateTime now = DateTime.now();

        final List<KategoriLayanan> cats = <KategoriLayanan>[...store.kategori]
          ..sort((KategoriLayanan a, KategoriLayanan b) =>
              store.countKategori(b.idKategori).compareTo(store.countKategori(a.idKategori)));
        final int maxCat = cats.isEmpty ? 0 : store.countKategori(cats.first.idKategori);

        final List<Pesanan> terbaru = <Pesanan>[...store.pesanan]
          ..sort((Pesanan a, Pesanan b) => b.idPesanan.compareTo(a.idPesanan));
        final List<Pesanan> cocok =
            terbaru.where((Pesanan p) => store.pesananCocok(p, _query)).toList();
        final List<Pesanan> lima = cocok.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PageHeader(
              title: 'Dashboard Admin',
              subtitle: 'Ringkasan operasional UPNVJT SIGAP · ${hariPanjang(now)}',
              onSearch: (String v) => setState(() => _query = v),
              searchHint: 'Cari pesanan: ID, pelanggan, kru, lokasi...',
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: StatCard(
                    color: AppColors.green,
                    icon: Icons.inventory_2_outlined,
                    label: 'Total Pesanan',
                    value: '${store.pesanan.length}',
                    caption: '${store.kategori.length} kategori layanan',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    color: AppColors.blue,
                    icon: Icons.schedule,
                    label: 'Pesanan Aktif',
                    value: '${store.pesananAktif}',
                    caption: '${store.countStatus(StatusPesanan.menunggu)} menunggu helper',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    color: AppColors.purple,
                    icon: Icons.groups_outlined,
                    label: 'Kru Terdaftar',
                    value: '${store.countRole(UserRole.kru)}',
                    caption: '${store.kruKrsTerisi} dengan jadwal KRS terisi',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    color: AppColors.red,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Komisi Admin 8%',
                    value: rupiah(store.totalKomisi),
                    caption: 'dari ${rupiah(store.totalTransaksi)} transaksi selesai',
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
                        const Text('Pesanan per Kategori Layanan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('Total ${store.pesanan.length} pesanan',
                            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(height: 14),
                        if (cats.isEmpty) const EmptyRow('Belum ada kategori.'),
                        for (final KategoriLayanan k in cats)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: <Widget>[
                                SizedBox(
                                  width: 140,
                                  child: cellText(k.namaKategori),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      height: 10,
                                      color: AppColors.bg,
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: maxCat == 0
                                            ? 0
                                            : store.countKategori(k.idKategori) / maxCat,
                                        child: Container(
                                          color: AppColors.palette[
                                              k.warnaIndex % AppColors.palette.length],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${store.countKategori(k.idKategori)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
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
                        const Text('Status Pesanan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('Alur: Menunggu → Diambil → Dikerjakan → Selesai',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(height: 14),
                        for (final StatusPesanan s in StatusPesanan.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: statusColor(s), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: cellText(s.label)),
                                Text('${store.countStatus(s)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor(s))),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (store.pesanan.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 8,
                              child: Row(
                                children: <Widget>[
                                  for (final StatusPesanan s in StatusPesanan.values)
                                    if (store.countStatus(s) > 0)
                                      Expanded(
                                        flex: store.countStatus(s),
                                        child: Container(color: statusColor(s)),
                                      ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text('Pesanan Terbaru',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                      TextButton(
                        onPressed: widget.onLihatSemua,
                        child: const Text('Lihat semua',
                            style: TextStyle(
                                color: AppColors.green, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SearchInfo(
                    query: _query,
                    found: cocok.length,
                    total: store.pesanan.length,
                    catatan: cocok.length > 5 ? ' · menampilkan 5 teratas' : '',
                  ),
                  TableHead(cols: <MapEntry<String, int>>[
                    const MapEntry<String, int>('ID', 1),
                    const MapEntry<String, int>('Pelanggan', 2),
                    const MapEntry<String, int>('Kategori', 2),
                    const MapEntry<String, int>('Jemput → Antar', 3),
                    const MapEntry<String, int>('Kru', 2),
                    const MapEntry<String, int>('Status', 2),
                    const MapEntry<String, int>('Estimasi', 1),
                  ]),
                  if (lima.isEmpty) const EmptyRow('Belum ada pesanan.'),
                  for (final Pesanan p in lima)
                    TableRowBox(children: <Widget>[
                      Expanded(
                          flex: 1,
                          child: cellText(kodePsn(p.idPesanan),
                              bold: true, color: AppColors.green)),
                      Expanded(
                          flex: 2,
                          child: cellText(store.namaUser(p.idPelanggan), bold: true)),
                      Expanded(flex: 2, child: cellText(store.namaKategori(p.idKategori))),
                      Expanded(
                          flex: 3,
                          child: cellText('${p.lokasiJemput} → ${p.lokasiAntar}')),
                      Expanded(flex: 2, child: cellText(store.namaUser(p.idKru))),
                      Expanded(
                        flex: 2,
                        child: leftAlign(
                            Pill(p.statusPesanan.label, statusColor(p.statusPesanan))),
                      ),
                      Expanded(flex: 1, child: cellText(rupiah(p.estimasiBiaya), bold: true)),
                    ]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
