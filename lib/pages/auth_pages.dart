import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../widgets/common.dart';

// ---------------------------------------------------------------------------
// Panel kiri (dipakai login & registrasi)
// ---------------------------------------------------------------------------

class _AuthLeft extends StatelessWidget {
  const _AuthLeft({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _feature(IconData icon, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub,
                    style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF123C5A), Color(0xFF0F8F6A), Color(0xFF12A36B)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(top: -70, right: -40, child: _circle(240, AppColors.yellow)),
            Positioned(bottom: -60, left: -50, child: _circle(210, AppColors.red)),
            Positioned(bottom: 150, right: -40, child: _circle(150, AppColors.purple)),
            Positioned(bottom: 24, right: 110, child: _circle(70, AppColors.blue)),
            SingleChildScrollView(
              padding: const EdgeInsets.all(32),
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
                                color: AppColors.navy,
                                fontWeight: FontWeight.w900,
                                fontSize: 17)),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('UPNVJT SIGAP',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          Text('Layanan bantuan antar mahasiswa',
                              style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 90),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.2)),
                  const SizedBox(height: 14),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withAlpha(215), fontSize: 12, height: 1.5)),
                  const SizedBox(height: 22),
                  _feature(Icons.assignment_outlined, 'Form pemesanan terstruktur',
                      'Kategori, lokasi, waktu & detail dalam satu form'),
                  _feature(Icons.trending_up, 'Tawar-menawar harga ala inDrive',
                      'Tawar, terima, atau tawar ulang dengan kru'),
                  _feature(Icons.account_balance_wallet_outlined, 'Komisi 8% transparan',
                      'Tarif, komisi & pendapatan kru tercatat jelas'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _chip('10 Kru Mahasiswa', AppColors.yellow, AppColors.navy),
                      _chip('Rungkut · Medokan · MERR', Colors.white, AppColors.navy),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, size: 16, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 12, color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController(text: 'sultan@email.com');
  final TextEditingController _pass = TextEditingController(text: 'admin123');
  int _roleIdx = 2; // default Admin (panel desktop khusus admin)
  bool _remember = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final String? err = store.login(_email.text, _pass.text, UserRole.values[_roleIdx]);
    if (err != null) setState(() => _error = err);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: <Widget>[
          const Expanded(
            flex: 5,
            child: _AuthLeft(
              title: 'Pesan bantuan kampus,\ntanpa chat yang tertimbun.',
              subtitle:
                  'Satu platform untuk jastip, pengambilan laundry, cetak dokumen, hingga urus berkas wisuda di sekitar UPN "Veteran" Jawa Timur.',
            ),
          ),
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Pill('SELAMAT DATANG KEMBALI', AppColors.amber),
                        const SizedBox(height: 14),
                        const Text('Masuk ke akun Anda',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text)),
                        const SizedBox(height: 6),
                        const Text(
                          'Gunakan akun UPNVJT SIGAP untuk memesan atau mengerjakan layanan.',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                        const SizedBox(height: 18),
                        const Text('Masuk sebagai',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Segmented(
                          labels: const <String>['Pelanggan', 'Kru / Helper', 'Admin'],
                          index: _roleIdx,
                          onChanged: (int i) => setState(() => _roleIdx = i),
                        ),
                        const SizedBox(height: 14),
                        AppField(
                          controller: _email,
                          label: 'Email',
                          hint: 'nama.mahasiswa@email.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 14),
                        AppField(
                          controller: _pass,
                          label: 'Kata sandi',
                          hint: 'Masukkan kata sandi',
                          icon: Icons.lock_outline,
                          obscure: true,
                          validator: (String? v) =>
                              Validators.wajib(v, 'Kata sandi wajib diisi'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _remember,
                                activeColor: AppColors.green,
                                onChanged: (bool? v) =>
                                    setState(() => _remember = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Ingat saya', style: TextStyle(fontSize: 12)),
                            ),
                            InkWell(
                              onTap: () => toast(context,
                                  'Fitur lupa kata sandi akan dihubungkan ke server.'),
                              child: const Text('Lupa kata sandi?',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.green,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 12),
                          _ErrorBox(_error!),
                        ],
                        const SizedBox(height: 18),
                        PrimaryButton(label: 'Masuk', onPressed: _submit),
                        const SizedBox(height: 14),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              const Text('Belum punya akun? ',
                                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
                              InkWell(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                      builder: (BuildContext _) => const RegisterPage()),
                                ),
                                child: const Text('Daftar sekarang',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.green,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Pendaftaran mandiri hanya untuk pelanggan. Akun kru didaftarkan oleh admin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: AppColors.muted),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: <Widget>[
                              Icon(Icons.lock_outline, size: 16, color: AppColors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kata sandi disimpan terenkripsi (hash). Data pribadi & transaksi hanya dapat diakses sesuai peran Anda.',
                                  style: TextStyle(fontSize: 11, color: AppColors.navy),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Registrasi
// ---------------------------------------------------------------------------

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _telp = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _pass2 = TextEditingController();
  bool _setuju = false;
  String? _error;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _telp.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_setuju) {
      setState(() => _error = 'Anda harus menyetujui syarat layanan & komisi admin 8%.');
      return;
    }
    final String? err = store.register(
      nama: _nama.text,
      email: _email.text,
      telepon: _telp.text,
      password: _pass.text,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    toast(context, 'Pendaftaran berhasil. Akun pelanggan tersimpan di Master Pengguna.');
    Navigator.of(context).pop();
  }

  /// Pendaftaran mandiri hanya untuk Pelanggan (bukan pilihan).
  Widget _kartuPelanggan() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green, width: 1.5),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Pelanggan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Memesan jastip, jasa khusus & layanan lainnya (request sendiri)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: <Widget>[
          const Expanded(
            flex: 4,
            child: _AuthLeft(
              title: 'Gabung jadi bagian\ndari SIGAP.',
              subtitle:
                  'Daftar sebagai pelanggan dan pesan bantuan dalam hitungan langkah. Akun kru didaftarkan langsung oleh admin SIGAP.',
            ),
          ),
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Buat akun baru',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text)),
                        const SizedBox(height: 4),
                        const Text('Daftar sebagai pelanggan, lalu lengkapi data diri.',
                            style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 16),
                        _kartuPelanggan(),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingin menjadi kru/helper? Akun kru hanya dapat didaftarkan oleh admin SIGAP.',
                          style: TextStyle(fontSize: 10, color: AppColors.muted),
                        ),
                        const SizedBox(height: 16),
                        AppField(
                          controller: _nama,
                          label: 'Nama lengkap',
                          hint: 'Masukkan nama lengkap Anda',
                          icon: Icons.person_outline,
                          validator: (String? v) =>
                              Validators.wajib(v, 'Nama lengkap wajib diisi'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: AppField(
                                controller: _email,
                                label: 'Email',
                                hint: 'nama@email.com',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.email,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppField(
                                controller: _telp,
                                label: 'No. telepon',
                                hint: '08xx xxxx xxxx',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: Validators.telepon,
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
                                controller: _pass,
                                label: 'Kata sandi',
                                hint: 'Min. 8 karakter',
                                icon: Icons.lock_outline,
                                obscure: true,
                                validator: Validators.password,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppField(
                                controller: _pass2,
                                label: 'Konfirmasi kata sandi',
                                hint: 'Ulangi kata sandi',
                                icon: Icons.lock_outline,
                                obscure: true,
                                validator: (String? v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Konfirmasi wajib diisi';
                                  }
                                  if (v != _pass.text) return 'Kata sandi tidak sama';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _setuju,
                                activeColor: AppColors.green,
                                onChanged: (bool? v) =>
                                    setState(() => _setuju = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Saya menyetujui syarat layanan & komisi admin 8%',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 12),
                          _ErrorBox(_error!),
                        ],
                        const SizedBox(height: 16),
                        PrimaryButton(label: 'Daftar Sekarang', onPressed: _submit),
                        const SizedBox(height: 12),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              const Text('Sudah punya akun? ',
                                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
                              InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Text('Masuk',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.green,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
