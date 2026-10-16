import 'package:flutter/material.dart';

import '../core/export_excel.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

const List<IconData> kategoriIcons = <IconData>[
  Icons.restaurant_menu,
  Icons.local_laundry_service_outlined,
  Icons.print_outlined,
  Icons.description_outlined,
  Icons.inventory_2_outlined,
  Icons.star_outline,
];

/// Ikon kategori. Kategori "Lainnya" selalu memakai ikon titik tiga.
IconData kategoriIcon(KategoriLayanan k) {
  if (k.lainnya) return Icons.more_horiz;
  return kategoriIcons[(k.idKategori - 1) % kategoriIcons.length];
}

Color statusColor(StatusPesanan s) {
  switch (s) {
    case StatusPesanan.menunggu:
      return AppColors.amber;
    case StatusPesanan.diambil:
      return AppColors.blue;
    case StatusPesanan.dikerjakan:
      return AppColors.purple;
    case StatusPesanan.selesai:
      return AppColors.green;
    case StatusPesanan.dibatalkan:
      return AppColors.red;
  }
}

Color roleColor(UserRole r) {
  switch (r) {
    case UserRole.pelanggan:
      return AppColors.green;
    case UserRole.kru:
      return AppColors.blue;
    case UserRole.admin:
      return AppColors.purple;
  }
}

void toast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.red : AppColors.navy,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
}

String csvFrom(List<List<String>> rows) {
  return rows
      .map((List<String> r) =>
          r.map((String c) => '"${c.replaceAll('"', '""')}"').join(','))
      .join('\n');
}

Widget cellText(String s,
    {bool bold = false, Color color = AppColors.text, double size = 12}) {
  return Text(
    s,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: size,
      color: color,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    ),
  );
}

Widget leftAlign(Widget w) => Align(alignment: Alignment.centerLeft, child: w);

class Validators {
  static String? wajib(String? v, [String pesan = 'Wajib diisi']) =>
      (v == null || v.trim().isEmpty) ? pesan : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    final RegExp re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v.trim())) return 'Format email tidak valid';
    return null;
  }

  static String? telepon(String? v) {
    if (v == null || v.trim().isEmpty) return 'No. telepon wajib diisi';
    final String d = v.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^[0-9+]{9,15}$').hasMatch(d)) return 'No. telepon tidak valid';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Minimal 8 karakter';
    return null;
  }
}

// ---------------------------------------------------------------------------
// Widget dasar
// ---------------------------------------------------------------------------

class CardBox extends StatelessWidget {
  const CardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, this.color, {super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, required this.color, this.size = 32});

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  static OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  // Kolom kata sandi: true = disembunyikan (titik-titik).
  bool _sembunyi = true;

  @override
  Widget build(BuildContext context) {
    final AppField w = widget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          w.label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: w.controller,
          obscureText: w.obscure && _sembunyi,
          validator: w.validator,
          maxLines: w.obscure ? 1 : w.maxLines,
          enabled: w.enabled,
          keyboardType: w.keyboardType,
          onChanged: w.onChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.text),
          decoration: InputDecoration(
            hintText: w.hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
            isDense: true,
            filled: true,
            fillColor: w.enabled ? AppColors.field : const Color(0xFFEEF1F6),
            prefixIcon:
                w.icon == null ? null : Icon(w.icon, size: 18, color: AppColors.muted),
            suffixIcon: w.obscure
                ? IconButton(
                    tooltip: _sembunyi ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _sembunyi
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    onPressed: () => setState(() => _sembunyi = !_sembunyi),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: AppField._border(AppColors.border),
            enabledBorder: AppField._border(AppColors.border),
            disabledBorder: AppField._border(AppColors.border),
            focusedBorder: AppField._border(AppColors.green),
            errorBorder: AppField._border(AppColors.red),
            focusedErrorBorder: AppField._border(AppColors.red),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.green,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[Icon(icon, size: 17), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.muted,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        child: Text(label),
      ),
    );
  }
}

class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i == index ? AppColors.green : AppColors.muted,
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

class MiniAction extends StatelessWidget {
  const MiniAction({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      ),
    );
  }
}

class RowActions extends StatelessWidget {
  const RowActions({super.key, this.onView, this.onEdit, this.onDelete, this.onNego});

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Tombol "Negosiasi harga" (khusus Master Pesanan).
  final VoidCallback? onNego;

  static const double width = 110;
  static const double widthNego = 144;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: onNego != null ? widthNego : width,
      child: Row(
        children: <Widget>[
          if (onView != null)
            MiniAction(icon: Icons.visibility_outlined, color: AppColors.blue, onTap: onView!, tooltip: 'Lihat'),
          if (onNego != null)
            MiniAction(icon: Icons.forum_outlined, color: AppColors.amber, onTap: onNego!, tooltip: 'Negosiasi harga'),
          if (onEdit != null)
            MiniAction(icon: Icons.edit_outlined, color: AppColors.purple, onTap: onEdit!, tooltip: 'Ubah'),
          if (onDelete != null)
            MiniAction(icon: Icons.delete_outline, color: AppColors.red, onTap: onDelete!, tooltip: 'Hapus'),
        ],
      ),
    );
  }
}

/// Info hasil pencarian ("3 dari 12 data cocok dengan ..."). Tidak tampil
/// bila kolom cari kosong, sehingga tampilan normal tidak berubah.
class SearchInfo extends StatelessWidget {
  const SearchInfo({
    super.key,
    required this.query,
    required this.found,
    required this.total,
    this.catatan = '',
  });

  final String query;
  final int found;
  final int total;
  final String catatan;

  @override
  Widget build(BuildContext context) {
    final String q = query.trim();
    if (q.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$found dari $total data cocok dengan "$q"$catatan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class TableHead extends StatelessWidget {
  const TableHead({super.key, required this.cols, this.trailing = 0});

  final List<MapEntry<String, int>> cols;
  final double trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          for (final MapEntry<String, int> c in cols)
            Expanded(
              flex: c.value,
              child: Text(
                c.key.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
            ),
          if (trailing > 0) SizedBox(width: trailing),
        ],
      ),
    );
  }
}

class TableRowBox extends StatelessWidget {
  const TableRowBox({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: children),
    );
  }
}

class EmptyRow extends StatelessWidget {
  const EmptyRow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(60),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class PageHeader extends StatefulWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onSearch,
    this.searchHint = 'Cari data...',
    this.trailing,
  });

  final String title;
  final String subtitle;

  /// Bila null, kolom cari disembunyikan (halaman tanpa data untuk dicari).
  final ValueChanged<String>? onSearch;

  /// Petunjuk kolom cari: sebutkan kolom/data apa saja yang dicari di tab ini.
  final String searchHint;
  final Widget? trailing;

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  final TextEditingController _cari = TextEditingController();

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  static OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  Widget _kolomCari(ValueChanged<String> onSearch) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: _cari,
        onChanged: (String v) {
          setState(() {});
          onSearch(v);
        },
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.muted),
          suffixIcon: _cari.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 16, color: AppColors.muted),
                  onPressed: () {
                    _cari.clear();
                    setState(() {});
                    onSearch('');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: _border(AppColors.border),
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.green),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ValueChanged<String>? onSearch = widget.onSearch;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (onSearch != null) ...<Widget>[
          _kolomCari(onSearch),
          const SizedBox(width: 10),
        ],
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => toast(
              context,
              '${store.countStatus(StatusPesanan.menunggu)} pesanan menunggu helper · '
              '${store.jumlahTawaranMenunggu} tawaran harga menunggu keputusan.'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_none, size: 19, color: AppColors.text),
          ),
        ),
        if (widget.trailing != null) ...<Widget>[
          const SizedBox(width: 10),
          widget.trailing!,
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog
// ---------------------------------------------------------------------------

Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.logout,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.red.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.red, size: 22),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
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
                        label: confirmLabel,
                        color: AppColors.red,
                        onPressed: () => Navigator.of(ctx).pop(true),
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
  return result ?? false;
}

Future<void> showDetail(
  BuildContext context,
  String title,
  List<MapEntry<String, String>> items,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        for (final MapEntry<String, String> e in items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  width: 130,
                                  child: Text(e.key,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.muted)),
                                ),
                                Expanded(
                                  child: Text(e.value,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 110,
                    child: PrimaryButton(
                      label: 'Tutup',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> confirmLogout(BuildContext context) async {
  final bool ok = await showConfirm(
    context,
    title: 'Keluar dari akun?',
    message:
        'Sesi Anda akan diakhiri. Anda perlu masuk kembali untuk memesan, mengerjakan pesanan, atau mengelola data.',
    confirmLabel: 'Ya, Keluar',
  );
  if (ok) store.logout();
}

/// Ekspor data ke berkas Excel (.xlsx) lalu tampilkan lokasi file-nya.
Future<void> eksporKeExcel(
  BuildContext context, {
  required String namaDasar,
  required String namaSheet,
  required List<String> header,
  required List<List<Object?>> baris,
  List<double>? lebarKolom,
}) async {
  try {
    final HasilEkspor hasil = await simpanExcel(
      namaDasar: namaDasar,
      namaSheet: namaSheet,
      header: header,
      baris: baris,
      lebarKolom: lebarKolom,
    );
    if (!context.mounted) return;
    await showDetail(context, 'Ekspor Excel berhasil', <MapEntry<String, String>>[
      MapEntry<String, String>('Nama file', hasil.namaFile),
      MapEntry<String, String>('Lokasi', hasil.folder),
      MapEntry<String, String>('Jumlah data', '${baris.length} baris'),
    ]);
  } catch (e) {
    if (!context.mounted) return;
    toast(context, 'Gagal mengekspor ke Excel: $e', error: true);
  }
}
