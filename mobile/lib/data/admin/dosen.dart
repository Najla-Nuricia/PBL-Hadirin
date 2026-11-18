import 'package:flutter/foundation.dart';

import 'jadwal.dart';

/// In-memory repository untuk Dosen (dummy, sampai backend siap).
class DosenRepository extends ChangeNotifier {
  DosenRepository({List<Dosen>? seedData})
    : _items = List.of(seedData ?? JadwalMasterData.dosen);

  final List<Dosen> _items;

  List<Dosen> getAll() => List.unmodifiable(_items);

  /// Cari satu dosen berdasarkan NIP (null jika tidak ditemukan).
  Dosen? findByNip(String nip) {
    for (final item in _items) {
      if (item.nip == nip) return item;
    }
    return null;
  }

  List<Dosen> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _items
        .where(
          (item) =>
              item.nip.toLowerCase().contains(q) ||
              item.nama.toLowerCase().contains(q) ||
              (item.programStudi ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  /// NIP dosen bersifat unik. [excludeNip] dipakai saat edit.
  bool exists(String nip, {String? excludeNip}) =>
      _items.any((item) => item.nip == nip && item.nip != excludeNip);

  void add(Dosen dosen) {
    _items.insert(0, dosen);
    notifyListeners();
  }

  /// Perbarui dosen; [oldNip] adalah NIP sebelum diedit.
  /// Mengembalikan false bila data lama tidak ditemukan.
  bool update(String oldNip, Dosen dosen) {
    final index = _items.indexWhere((item) => item.nip == oldNip);
    if (index == -1) return false;
    _items[index] = dosen;
    notifyListeners();
    return true;
  }

  /// Hapus dosen berdasarkan NIP.
  bool remove(String nip) {
    final index = _items.indexWhere((item) => item.nip == nip);
    if (index == -1) return false;
    _items.removeAt(index);
    notifyListeners();
    return true;
  }

  /// Kembalikan isi repository ke data awal (dipakai saat pengujian).
  void reset([List<Dosen>? seedData]) {
    _items
      ..clear()
      ..addAll(seedData ?? JadwalMasterData.dosen);
    notifyListeners();
  }
}

/// Singleton repository instance.
final dosenRepository = DosenRepository();
