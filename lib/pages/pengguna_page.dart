import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class PenggunaPage extends StatefulWidget {
  const PenggunaPage({super.key});

  @override
  State<PenggunaPage> createState() => _PenggunaPageState();
}

class _PenggunaPageState extends State<PenggunaPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _telp = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _krs = TextEditingController();

  String _query = '';
  UserRole? _filter; // null = semua
  UserModel? _editing;
  int _roleIdx = 1; // default Kru, seperti desain

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _telp.dispose();
    _pass.dispose();
    _krs.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _editing = null;
      _roleIdx = 1;
      _nama.clear();
      _email.clear();
      _telp.clear();
      _pass.clear();
      _krs.clear();
    });
    _formKey.currentState?.reset();
  }

  void _edit(UserModel u) {
    setState(() {
      _editing = u;
      _roleIdx = UserRole.values.indexOf(u.role);
      _nama.text = u.namaLengkap;
      _email.text = u.email;
      _telp.text = u.noTelepon;
      _pass.clear();
      _krs.text = u.jadwalKrs ?? '';
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final UserRole role = UserRole.values[_roleIdx];
    final UserModel? edit = _editing;
    final String? err = edit == null
        ? store.tambahUser(
            nama: _nama.text,
            email: _email.text,
            telepon: _telp.text,
            password: _pass.text,
            role: role,
            jadwalKrs: _krs.text,
          )
        : store.ubahUser(
            id: edit.idUser,
            nama: _nama.text,
            email: _email.text,
            telepon: _telp.text,
            role: role,
            jadwalKrs: _krs.text,
            passwordBaru: _pass.text,
          );
    if (err != null) {
      toast(context, err, error: true);
      return;
    }
    toast(context, edit == null ? 'Pengguna berhasil ditambahkan.' : 'Pengguna berhasil diperbarui.');
    _reset();
  }

  Future<void> _hapus(UserModel u) async {
    final bool ok = await showConfirm(
      context,
      title: 'Hapus pengguna?',
      message: 'Akun "${u.namaLengkap}" akan dihapus permanen.',
      confirmLabel: 'Ya, Hapus',
      icon: Icons.delete_outline,
    );
    if (!ok || !mounted) return;
    final String? err = store.hapusUser(u.idUser);
    if (err != null) {
      toast(context, err, error: true);
    } else {
      if (_editing?.idUser == u.idUser) _reset();
      toast(context, 'Pengguna dihapus.');
    }
  }

  void _lihat(UserModel u) {
    showDetail(context, 'Detail Pengguna', <MapEntry<String, String>>[
      MapEntry<String, String>('ID', '${u.idUser}'),
      MapEntry<String, String>('Nama lengkap', u.namaLengkap),
      MapEntry<String, String>('Email', u.email),
      MapEntry<String, String>('No. telepon', u.noTelepon),
      MapEntry<String, String>('Peran', u.role.label),
      MapEntry<String, String>('Jadwal KRS', u.krsTerisi ? u.jadwalKrs! : '—'),
    ]);
  }

  Widget _chip(String label, int count, UserRole? role) {
    final bool selected = _filter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _filter = role),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, Widget? _) {
        final String q = _query.trim().toLowerCase();
        final List<UserModel> data = store.users.where((UserModel u) {
          if (_filter != null && u.role != _filter) return false;
          return q.isEmpty ||
              u.namaLengkap.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.noTelepon.toLowerCase().contains(q) ||
              u.role.label.toLowerCase().contains(q) ||
              (u.jadwalKrs ?? '').toLowerCase().contains(q);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PageHeader(
              title: 'Master Pengguna',
              subtitle: 'Kelola akun pelanggan, kru & admin · tabel users',
              onSearch: (String v) => setState(() => _query = v),
              searchHint: 'Cari nama, email, telepon, peran...',
            ),
            const SizedBox(height: 16),
            Wrap(
              runSpacing: 8,
              children: <Widget>[
                _chip('Semua', store.users.length, null),
                _chip('Pelanggan', store.countRole(UserRole.pelanggan), UserRole.pelanggan),
                _chip('Kru / Helper', store.countRole(UserRole.kru), UserRole.kru),
                _chip('Admin', store.countRole(UserRole.admin), UserRole.admin),
              ],
            ),
            const SizedBox(height: 16),
            SearchInfo(query: _query, found: data.length, total: store.users.length),
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

  Widget _tabel(List<UserModel> data) {
    return CardBox(
      child: Column(
        children: <Widget>[
          TableHead(
            trailing: RowActions.width,
            cols: const <MapEntry<String, int>>[
              MapEntry<String, int>('Pengguna', 4),
              MapEntry<String, int>('No. telepon', 3),
              MapEntry<String, int>('Peran', 2),
              MapEntry<String, int>('Jadwal KRS', 2),
            ],
          ),
          if (data.isEmpty) const EmptyRow('Tidak ada pengguna yang cocok.'),
          for (final UserModel u in data)
            TableRowBox(children: <Widget>[
              Expanded(
                flex: 4,
                child: Row(
                  children: <Widget>[
                    Avatar(
                      name: u.namaLengkap,
                      color: AppColors.palette[u.idUser % AppColors.palette.length],
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cellText(u.namaLengkap, bold: true),
                          cellText(u.email, size: 10, color: AppColors.muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 3, child: cellText(maskTelepon(u.noTelepon))),
              Expanded(flex: 2, child: leftAlign(Pill(u.role.label, roleColor(u.role)))),
              Expanded(
                flex: 2,
                child: u.role == UserRole.kru
                    ? leftAlign(Pill(
                        u.krsTerisi ? 'KRS terisi' : 'KRS kosong',
                        u.krsTerisi ? AppColors.green : AppColors.red,
                      ))
                    : cellText('—', color: AppColors.muted),
              ),
              RowActions(
                onView: () => _lihat(u),
                onEdit: () => _edit(u),
                onDelete: () => _hapus(u),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _form() {
    final bool edit = _editing != null;
    final bool isKru = UserRole.values[_roleIdx] == UserRole.kru;
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
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(edit ? Icons.edit_outlined : Icons.person_add_alt,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(edit ? 'Ubah Pengguna' : 'Tambah Pengguna',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      const Text('Kru hanya bisa didaftarkan oleh Admin',
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
              label: 'Nama lengkap',
              hint: 'Nama lengkap pengguna',
              icon: Icons.person_outline,
              validator: (String? v) => Validators.wajib(v, 'Nama lengkap wajib diisi'),
            ),
            const SizedBox(height: 12),
            AppField(
              controller: _email,
              label: 'Email',
              hint: 'nama@email.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            AppField(
              controller: _telp,
              label: 'No. telepon',
              hint: '08xx xxxx xxxx',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.telepon,
            ),
            const SizedBox(height: 12),
            const Text('Peran (role)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Segmented(
              labels: const <String>['Pelanggan', 'Kru', 'Admin'],
              index: _roleIdx,
              onChanged: (int i) => setState(() => _roleIdx = i),
            ),
            const SizedBox(height: 12),
            AppField(
              controller: _pass,
              label: edit ? 'Kata sandi baru (opsional)' : 'Kata sandi awal',
              hint: 'Disimpan terenkripsi (hash)',
              icon: Icons.lock_outline,
              obscure: true,
              validator: (String? v) {
                if (edit && (v == null || v.isEmpty)) return null;
                return Validators.password(v);
              },
            ),
            const SizedBox(height: 12),
            AppField(
              controller: _krs,
              label: 'Jadwal KRS (khusus Kru)',
              hint: 'Senin 08.00-10.30 ...',
              maxLines: 3,
              enabled: isKru,
              validator: (String? v) =>
                  isKru ? Validators.wajib(v, 'Jadwal KRS wajib diisi untuk kru') : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: PrimaryButton(label: 'Simpan', icon: Icons.check, onPressed: _save),
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
