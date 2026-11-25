// Model Ruangan kini menjadi bagian dari model master data bersama di
// jadwal.dart, lengkap dengan fromJson/toJson untuk API /admin.
export 'jadwal.dart' show Ruangan;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'jadwal.dart';

class RuanganQrItem {
  const RuanganQrItem({
    required this.kode,
    required this.nama,
    required this.qrToken,
    this.title = '',
    this.instruksi = '',
  });

  final String kode;
  final String nama;
  final String qrToken;
  final String title;
  final String instruksi;

  factory RuanganQrItem.fromRuangan(Ruangan r) => RuanganQrItem(
        kode: r.kode,
        nama: r.nama,
        qrToken: 'HADIRIN:ROOM:${r.kode.toUpperCase()}',
        title: 'KARTU PRESENSI PINTU: ${r.nama} (${r.kode})',
        instruksi:
            'Pindai QR ini pada pintu ruangan sebelum masuk kelas untuk membuka verifikasi presensi wajah Hadirin.',
      );

  factory RuanganQrItem.fromJson(Map<String, dynamic> json) {
    final kode = (json['kode'] as String?)?.trim().toUpperCase() ?? '';
    final nama = (json['nama'] as String?)?.trim() ?? 'Ruangan $kode';
    final token = (json['qr_token'] as String?)?.trim() ?? 'HADIRIN:ROOM:$kode';
    return RuanganQrItem(
      kode: kode,
      nama: nama,
      qrToken: token,
      title: (json['title'] as String?) ?? 'KARTU PRESENSI PINTU: $nama ($kode)',
      instruksi: (json['instruksi'] as String?) ??
          'Pindai QR ini pada pintu ruangan sebelum masuk kelas untuk membuka verifikasi presensi wajah Hadirin.',
    );
  }
}

class RuanganRepository extends ChangeNotifier {
  RuanganRepository({List<Ruangan>? seedData})
      : _items = List.of(seedData ?? JadwalMasterData.ruangan);

  final List<Ruangan> _items;

  List<Ruangan> getAll() => List.unmodifiable(_items);

  bool exists(String kode) =>
      _items.any((item) => item.kode.toLowerCase() == kode.toLowerCase());

  void add(Ruangan ruangan) {
    _items.add(ruangan);
    notifyListeners();
  }

  List<RuanganQrItem> getLocalQrList({String? query}) {
    final trimmed = (query ?? '').trim().toLowerCase();
    final items = _items.map((r) => RuanganQrItem.fromRuangan(r));
    if (trimmed.isEmpty) return items.toList();
    return items
        .where(
          (item) =>
              item.kode.toLowerCase().contains(trimmed) ||
              item.nama.toLowerCase().contains(trimmed) ||
              item.qrToken.toLowerCase().contains(trimmed),
        )
        .toList();
  }

  Future<List<RuanganQrItem>> fetchQrList({String? query}) async {
    try {
      final qs = (query != null && query.trim().isNotEmpty)
          ? '?search=${Uri.encodeQueryComponent(query.trim())}'
          : '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/admin/ruangan/qr-statis$qs');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final list = decoded['data'] as List<dynamic>? ?? const [];
        if (list.isNotEmpty) {
          return list
              .map((item) => RuanganQrItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return getLocalQrList(query: query);
  }
}

final ruanganRepository = RuanganRepository();
