import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'dashboard_page.dart';
import 'kategori_page.dart';
import 'laporan_page.dart';
import 'pengguna_page.dart';
import 'pesanan_page.dart';
import 'profil_page.dart';

enum AppPage { dashboard, kategori, pengguna, pesanan, laporan, profil }

class _NavItem {
  const _NavItem(this.page, this.label, this.icon);
  final AppPage page;
  final String label;
  final IconData icon;
}

const List<_NavItem> _adminNav = <_NavItem>[
  _NavItem(AppPage.dashboard, 'Dashboard', Icons.home_outlined),
  _NavItem(AppPage.kategori, 'Master Kategori', Icons.layers_outlined),
  _NavItem(AppPage.pengguna, 'Master Pengguna', Icons.people_outline),
  _NavItem(AppPage.pesanan, 'Master Pesanan', Icons.inventory_2_outlined),
  _NavItem(AppPage.laporan, 'Laporan Keuangan', Icons.account_balance_wallet_outlined),
  _NavItem(AppPage.profil, 'Profil Saya', Icons.person_outline),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late AppPage _page;

  @override
  void initState() {
    super.initState();
    _page = AppPage.dashboard;
  }

  Widget _body() {
    switch (_page) {
      case AppPage.dashboard:
        return DashboardPage(onLihatSemua: () => setState(() => _page = AppPage.pesanan));
      case AppPage.kategori:
        return const KategoriPage();
      case AppPage.pengguna:
        return const PenggunaPage();
      case AppPage.pesanan:
        return const PesananPage();
      case AppPage.laporan:
        return const LaporanPage();
      case AppPage.profil:
        return const ProfilPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, Widget? _) {
        final UserModel? user = store.currentUser;
        if (user == null) return const SizedBox.shrink();
        const List<_NavItem> items = _adminNav;
        return Scaffold(
          body: Row(
            children: <Widget>[
              _Sidebar(
                items: items,
                current: _page,
                user: user,
                onSelect: (AppPage p) => setState(() => _page = p),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _body(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.current,
    required this.user,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final AppPage current;
  final UserModel user;
  final ValueChanged<AppPage> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: AppColors.navy,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text('S',
                    style: TextStyle(
                        color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 17)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('UPNVJT SIGAP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    const Text('Panel Admin',
                        style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 8),
            child: Text('MENU UTAMA',
                style: TextStyle(
                    color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  for (final _NavItem it in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onSelect(it.page),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: it.page == current ? AppColors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(it.icon, size: 17, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(it.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: it.page == current
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Avatar(name: user.namaLengkap, color: AppColors.yellow, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(user.namaLengkap,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      Text(user.role.label,
                          style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => confirmLogout(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Icon(Icons.logout, size: 16, color: AppColors.red),
                  SizedBox(width: 10),
                  Text('Keluar (Logout)',
                      style: TextStyle(
                          color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
