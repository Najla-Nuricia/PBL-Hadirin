import 'package:flutter/foundation.dart';

enum KelasStatus { aktif, nonAktif }

extension KelasStatusLabel on KelasStatus {
  String get label => switch (this) {
    KelasStatus.aktif => 'Aktif',
    KelasStatus.nonAktif => 'Non-Aktif',
  };
}

class Kelas {
  const Kelas({
    required this.id,
    required this.tahunAjaran,
    required this.programStudi,
    required this.nama,
    required this.kapasitas,
    required this.status,
  });

  final String id;
  final String tahunAjaran; // contoh: 2026/2027
  final String programStudi;
  final String nama; // contoh: TI-3F
  final int kapasitas;
  final KelasStatus status;

  Kelas copyWith({
    String? tahunAjaran,
    String? programStudi,
    String? nama,
    int? kapasitas,
    KelasStatus? status,
  }) {
    return Kelas(
      id: id,
      tahunAjaran: tahunAjaran ?? this.tahunAjaran,
      programStudi: programStudi ?? this.programStudi,
      nama: nama ?? this.nama,
      kapasitas: kapasitas ?? this.kapasitas,
      status: status ?? this.status,
    );
  }
}

/// In-memory repository untuk Kelas (dummy, sampai backend siap).
class KelasRepository extends ChangeNotifier {
  KelasRepository({List<Kelas>? seedData})
    : _items = List.of(seedData ?? _seed);

  // Data awal agar dropdown Kelas tidak kosong.
  static const _seed = [
    Kelas(
      id: 's1',
      tahunAjaran: '2026/2027',
      programStudi: 'D4 Teknik Informatika',
      nama: 'TI-3A',
      kapasitas: 30,
      status: KelasStatus.aktif,
    ),
    Kelas(
      id: 's2',
      tahunAjaran: '2026/2027',
      programStudi: 'D4 Teknik Informatika',
      nama: 'TI-3B',
      kapasitas: 30,
      status: KelasStatus.aktif,
    ),
    Kelas(
      id: 's3',
      tahunAjaran: '2026/2027',
      programStudi: 'D4 Sistem Informasi Bisnis',
      nama: 'SIB-2C',
      kapasitas: 28,
      status: KelasStatus.aktif,
    ),
  ];

  final List<Kelas> _items;

  List<Kelas> getAll() => List.unmodifiable(_items);

  /// Cari satu kelas berdasarkan id (null jika tidak ditemukan).
  Kelas? findById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<Kelas> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _items
        .where(
          (item) =>
              item.nama.toLowerCase().contains(q) ||
              item.programStudi.toLowerCase().contains(q) ||
              item.tahunAjaran.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Nama kelas dianggap sama jika tahun ajaran dan nama sama
  /// (tidak peka huruf besar/kecil). [excludeId] dipakai saat edit.
  bool exists({
    required String tahunAjaran,
    required String nama,
    String? excludeId,
  }) {
    final n = nama.trim().toLowerCase();
    return _items.any(
      (k) =>
          k.id != excludeId &&
          k.tahunAjaran == tahunAjaran &&
          k.nama.toLowerCase() == n,
    );
  }

  void add(Kelas item) {
    _items.insert(0, item);
    notifyListeners();
  }

  /// Perbarui data kelas; mengembalikan false bila id tidak ditemukan.
  bool update(Kelas item) {
    final index = _items.indexWhere((k) => k.id == item.id);
    if (index == -1) return false;
    _items[index] = item;
    notifyListeners();
    return true;
  }

  /// Hapus kelas; mengembalikan false bila id tidak ditemukan.
  bool remove(String id) {
    final index = _items.indexWhere((k) => k.id == id);
    if (index == -1) return false;
    _items.removeAt(index);
    notifyListeners();
    return true;
  }

  String generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Kembalikan isi repository ke data awal (dipakai saat pengujian).
  void reset([List<Kelas>? seedData]) {
    _items
      ..clear()
      ..addAll(seedData ?? _seed);
    notifyListeners();
  }
}

/// Singleton repository instance.
final kelasRepository = KelasRepository();
