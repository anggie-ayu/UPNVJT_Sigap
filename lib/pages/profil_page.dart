import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final GlobalKey<FormState> _infoKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passKey = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _telp = TextEditingController();
  final TextEditingController _role = TextEditingController();
  final TextEditingController _passLama = TextEditingController();
  final TextEditingController _passBaru = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isiDariUser();
  }

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _telp.dispose();
    _role.dispose();
    _passLama.dispose();
    _passBaru.dispose();
    super.dispose();
  }

  void _isiDariUser() {
    final UserModel? u = store.currentUser;
    if (u == null) return;
    _nama.text = u.namaLengkap;
    _email.text = u.email;
    _telp.text = u.noTelepon;
    _role.text = u.role.label;
  }

  void _simpanInfo() {
    if (!_infoKey.currentState!.validate()) return;
    final String? err = store.ubahProfil(_nama.text, _email.text, _telp.text);
    toast(context, err ?? 'Profil berhasil diperbarui.', error: err != null);
  }

  void _simpanPassword() {
    if (!_passKey.currentState!.validate()) return;
    final String? err = store.ubahPassword(_passLama.text, _passBaru.text);
    if (err != null) {
      toast(context, err, error: true);
      return;
    }
    _passLama.clear();
    _passBaru.clear();
    _passKey.currentState?.reset();
    toast(context, 'Kata sandi berhasil diperbarui.');
  }

  String _waktuRelatif(DateTime t) {
    final Duration d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return tglWaktu(t);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, Widget? _) {
        final UserModel? u = store.currentUser;
        if (u == null) return const SizedBox.shrink();
        final bool admin = u.role == UserRole.admin;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const PageHeader(
              title: 'Profil Saya',
              subtitle: 'Kelola informasi akun, keamanan & sesi Anda',
            ),
            const SizedBox(height: 20),
            _kartuProfil(u, admin),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Column(
                    children: <Widget>[
                      _infoPribadi(u),
                      const SizedBox(height: 16),
                      _ubahPassword(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: <Widget>[
                      _keamanan(),
                      const SizedBox(height: 16),
                      _aktivitas(),
                      const SizedBox(height: 16),
                      _keluar(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _kartuProfil(UserModel u, bool admin) {
    return CardBox(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 90,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[Color(0xFF123C5A), Color(0xFF12A36B)],
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        top: -30,
                        left: 420,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                              color: AppColors.yellow, shape: BoxShape.circle),
                        ),
                      ),
                      Positioned(
                        top: 30,
                        left: 330,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                              color: AppColors.red, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                bottom: -34,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Avatar(name: u.namaLengkap, color: AppColors.navy, size: 64),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(112, 12, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(u.namaLengkap,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          Pill(u.role.label, roleColor(u.role)),
                          const Pill('Akun aktif', AppColors.green),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        admin
                            ? 'Mengelola pengguna, kategori layanan, pesanan & laporan komisi 8%'
                            : 'Akun ${u.role.label.toLowerCase()} UPNVJT SIGAP',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      toast(context, 'Unggah foto akan dihubungkan ke penyimpanan server.'),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPribadi(UserModel u) {
    return CardBox(
      child: Form(
        key: _infoKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Informasi Pribadi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const Text('Data akun pada tabel users',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: AppField(
                    controller: _nama,
                    label: 'Nama lengkap',
                    icon: Icons.person_outline,
                    validator: (String? v) => Validators.wajib(v, 'Nama lengkap wajib diisi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppField(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: AppField(
                    controller: _telp,
                    label: 'No. telepon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.telepon,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppField(
                    controller: _role,
                    label: 'Peran (tidak dapat diubah)',
                    icon: Icons.shield_outlined,
                    enabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 190,
                  child: PrimaryButton(
                    label: 'Simpan Perubahan',
                    icon: Icons.check,
                    onPressed: _simpanInfo,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: GhostButton(
                    label: 'Batal',
                    onPressed: () {
                      _isiDariUser();
                      _infoKey.currentState?.validate();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ubahPassword() {
    return CardBox(
      child: Form(
        key: _passKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Ubah Kata Sandi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const Text('Kata sandi disimpan terenkripsi (hash) dan tidak pernah ditampilkan',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: AppField(
                    controller: _passLama,
                    label: 'Kata sandi lama',
                    icon: Icons.lock_outline,
                    obscure: true,
                    validator: (String? v) => Validators.wajib(v, 'Kata sandi lama wajib diisi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppField(
                    controller: _passBaru,
                    label: 'Kata sandi baru',
                    hint: 'Min. 8 karakter',
                    icon: Icons.lock_outline,
                    obscure: true,
                    validator: Validators.password,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Perbarui Kata Sandi',
                icon: Icons.lock_outline,
                color: AppColors.navy,
                onPressed: _simpanPassword,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barisKeamanan(IconData icon, Color color, String judul, String sub) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withAlpha(35),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                cellText(judul, bold: true),
                cellText(sub, size: 10, color: AppColors.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keamanan() {
    final DateTime? login = store.lastLogin;
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Keamanan & Akses',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const Text('Sesuai peran Anda',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          _barisKeamanan(Icons.lock_outline, AppColors.green, 'Kata sandi terenkripsi',
              'Disimpan sebagai hash'),
          _barisKeamanan(Icons.shield_outlined, AppColors.purple, 'Akses berbasis peran',
              'Hanya data sesuai peran Anda'),
          _barisKeamanan(Icons.schedule, AppColors.blue, 'Login terakhir',
              login == null ? '—' : tglWaktu(login)),
        ],
      ),
    );
  }

  Widget _aktivitas() {
    final List<ActivityLog> list = store.activities.take(3).toList();
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Aktivitas Terakhir',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const Text('Riwayat aktivitas akun',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Belum ada aktivitas.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ),
          for (final ActivityLog a in list)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.palette[a.colorIndex % AppColors.palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(a.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(_waktuRelatif(a.time),
                            style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _keluar() {
    return CardBox(
      color: AppColors.red.withAlpha(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.logout, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Keluar dari akun',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    Text('Akhiri sesi di perangkat ini',
                        style: TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Keluar (Logout)',
            icon: Icons.logout,
            color: AppColors.red,
            onPressed: () => confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
