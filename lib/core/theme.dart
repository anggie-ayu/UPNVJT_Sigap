import 'package:flutter/material.dart';

class AppColors {
  static const Color green = Color(0xFF12A36B);
  static const Color navy = Color(0xFF12263F);
  static const Color navyLight = Color(0xFF1C3657);
  static const Color yellow = Color(0xFFF5B800);
  static const Color purple = Color(0xFF7C5CF2);
  static const Color blue = Color(0xFF2F9BFF);
  static const Color red = Color(0xFFFF5A6A);
  static const Color teal = Color(0xFF14B8A6);
  static const Color amber = Color(0xFFD99100);
  static const Color bg = Color(0xFFF1F5FB);
  static const Color text = Color(0xFF12203A);
  static const Color muted = Color(0xFF7A869A);
  static const Color border = Color(0xFFE3E9F2);
  static const Color field = Color(0xFFF7F9FC);

  static const List<Color> palette = <Color>[green, blue, purple, red, yellow, teal];
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
    scaffoldBackgroundColor: AppColors.bg,
  );
}

// ---------------------------------------------------------------------------
// Formatter
// ---------------------------------------------------------------------------

String rupiah(num v) {
  final bool neg = v < 0;
  final String s = v.round().abs().toString();
  final StringBuffer b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${neg ? '-' : ''}Rp$b';
}

const List<String> _bulanPendek = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];
const List<String> _bulanPanjang = <String>[
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus',
  'September', 'Oktober', 'November', 'Desember'
];
const List<String> _hari = <String>[
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];

String _dua(int n) => n.toString().padLeft(2, '0');

String tglWaktu(DateTime d) =>
    '${d.day} ${_bulanPendek[d.month - 1]} · ${_dua(d.hour)}.${_dua(d.minute)}';

String hariPanjang(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulanPanjang[d.month - 1]} ${d.year}';

String kodePsn(int id) => 'PSN-${id.toString().padLeft(4, '0')}';
String kodeKtg(int id) => 'KTG-${id.toString().padLeft(2, '0')}';
String kodeTrx(int id) => 'TRX-${id.toString().padLeft(4, '0')}';

String maskTelepon(String t) {
  final String s = t.trim();
  if (s.length < 8) return s;
  return '${s.substring(0, 4)} •••• ${s.substring(s.length - 4)}';
}
