import 'dart:io';

import 'package:excel/excel.dart' as xl;

/// Hasil ekspor: lokasi berkas yang berhasil disimpan.
class HasilEkspor {
  const HasilEkspor(this.path, this.namaFile, this.folder);

  final String path;
  final String namaFile;
  final String folder;
}

String _dua(int n) => n.toString().padLeft(2, '0');

/// Contoh: 20261015_143005 (dipakai pada nama file agar tidak menimpa file lama).
String stempelWaktuFile(DateTime d) =>
    '${d.year}${_dua(d.month)}${_dua(d.day)}_${_dua(d.hour)}${_dua(d.minute)}${_dua(d.second)}';

/// Contoh: 2026-10-15 14:30 (dipakai untuk kolom tanggal di Excel).
String formatWaktuExcel(DateTime d) =>
    '${d.year}-${_dua(d.month)}-${_dua(d.day)} ${_dua(d.hour)}:${_dua(d.minute)}';

/// Folder tujuan: folder Downloads/Unduhan pengguna; bila tidak ada, folder sementara.
Directory _folderTujuan() {
  final Map<String, String> env = Platform.environment;
  final String? home = Platform.isWindows ? env['USERPROFILE'] : env['HOME'];
  if (home != null && home.isNotEmpty) {
    final Directory unduhan = Directory('$home${Platform.pathSeparator}Downloads');
    if (unduhan.existsSync()) return unduhan;
  }
  return Directory.systemTemp;
}

xl.CellValue _nilai(Object? v) {
  if (v is int) return xl.IntCellValue(v);
  if (v is double) return xl.DoubleCellValue(v);
  return xl.TextCellValue(v == null ? '' : '$v');
}

/// Membuat berkas .xlsx berisi satu sheet (baris pertama = judul kolom tebal)
/// lalu menyimpannya ke folder Downloads. Angka disimpan sebagai angka
/// sehingga bisa dijumlah/diurutkan langsung di Excel.
Future<HasilEkspor> simpanExcel({
  required String namaDasar,
  required String namaSheet,
  required List<String> header,
  required List<List<Object?>> baris,
  List<double>? lebarKolom,
}) async {
  final xl.Excel excel = xl.Excel.createExcel();
  excel.rename('Sheet1', namaSheet);
  final xl.Sheet sheet = excel[namaSheet];

  sheet.appendRow(<xl.CellValue?>[
    for (final String h in header) xl.TextCellValue(h),
  ]);
  for (final List<Object?> r in baris) {
    sheet.appendRow(<xl.CellValue?>[
      for (final Object? v in r) _nilai(v),
    ]);
  }

  for (int c = 0; c < header.length; c++) {
    sheet
        .cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
        .cellStyle = xl.CellStyle(bold: true);
    final double lebar =
        (lebarKolom != null && c < lebarKolom.length) ? lebarKolom[c] : 20;
    sheet.setColumnWidth(c, lebar);
  }

  final List<int>? bytes = excel.encode();
  if (bytes == null) {
    throw Exception('berkas Excel gagal dibuat');
  }

  final Directory folder = _folderTujuan();
  final String namaFile = '${namaDasar}_${stempelWaktuFile(DateTime.now())}.xlsx';
  final String path = '${folder.path}${Platform.pathSeparator}$namaFile';
  await File(path).writeAsBytes(bytes, flush: true);
  return HasilEkspor(path, namaFile, folder.path);
}
