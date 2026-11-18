import 'package:flutter/foundation.dart';

import 'jadwal.dart';

class RuanganRepository extends ChangeNotifier {
  RuanganRepository({List<Ruangan>? seedData})
    : _items = List.of(seedData ?? JadwalMasterData.ruangan);

  final List<Ruangan> _items;

  List<Ruangan> getAll() => List.unmodifiable(_items);

  /// Cari satu ruangan berdasarkan kode (null jika tidak ditemukan).
  Ruangan? findByKode(String kode) {
    for (final item in _items) {
      if (item.kode == kode) return item;
    }
    return null;
  }

  List<Ruangan> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _items
        .where(
          (item) =>
              item.kode.toLowerCase().contains(q) ||
              item.nama.toLowerCase().contains(q),
        )
        .toList();
  }

  bool exists(String kode) => findByKode(kode) != null;

  void add(Ruangan ruangan) {
    _items.add(ruangan);
    notifyListeners();
  }

  /// Perbarui ruangan; [oldKode] adalah kode sebelum diedit.
  /// Mengembalikan false bila data lama tidak ditemukan.
  bool update(String oldKode, Ruangan ruangan) {
    final index = _items.indexWhere((item) => item.kode == oldKode);
    if (index == -1) return false;
    _items[index] = ruangan;
    notifyListeners();
    return true;
  }

  /// Hapus ruangan berdasarkan kode.
  bool remove(String kode) {
    final index = _items.indexWhere((item) => item.kode == kode);
    if (index == -1) return false;
    _items.removeAt(index);
    notifyListeners();
    return true;
  }

  /// Kembalikan isi repository ke data awal (dipakai saat pengujian).
  void reset([List<Ruangan>? seedData]) {
    _items
      ..clear()
      ..addAll(seedData ?? JadwalMasterData.ruangan);
    notifyListeners();
  }
}

final ruanganRepository = RuanganRepository();
