import 'package:flutter/foundation.dart';

import 'jadwal.dart';

/// Repository lokal untuk master mata kuliah admin.
/// Dapat diganti dengan datasource API tanpa mengubah halaman CRUD.
class MataKuliahRepository extends ChangeNotifier {
  MataKuliahRepository()
    : _items = [
        for (var index = 0; index < JadwalMasterData.mataKuliah.length; index++)
          _withId(JadwalMasterData.mataKuliah[index], index + 1),
      ];

  final List<MataKuliah> _items;

  static MataKuliah _withId(MataKuliah item, int number) {
    return MataKuliah(
      id: 'mk-$number',
      kode: item.kode,
      nama: item.nama,
      semester: item.semester,
      sks: item.sks,
      programStudiKode: item.programStudiKode,
      status: item.status,
    );
  }

  List<MataKuliah> getAll() => List.unmodifiable(_items);

  List<MataKuliah> getActive() => List.unmodifiable(
    _items.where((item) => item.status == MataKuliahStatus.aktif),
  );

  List<MataKuliah> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return getAll();
    return _items
        .where(
          (item) =>
              item.kode.toLowerCase().contains(normalized) ||
              item.nama.toLowerCase().contains(normalized) ||
              item.programStudiKode.toLowerCase().contains(normalized),
        )
        .toList();
  }

  MataKuliah? findById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool codeExists(String kode, {String? excludingId}) {
    final normalized = kode.trim().toLowerCase();
    return _items.any(
      (item) =>
          item.id != excludingId &&
          item.kode.trim().toLowerCase() == normalized,
    );
  }

  void add(MataKuliah item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void update(MataKuliah item) {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) return;
    _items[index] = item;
    notifyListeners();
  }

  void delete(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  String generateId() => 'mk-${DateTime.now().microsecondsSinceEpoch}';
}

final mataKuliahRepository = MataKuliahRepository();
