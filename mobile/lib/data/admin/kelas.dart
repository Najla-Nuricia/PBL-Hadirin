// lib/data/admin/kelas.dart
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
}

/// In-memory repository untuk Kelas (dummy, sampai backend siap).
class KelasRepository {
  final List<Kelas> _items = [];

  List<Kelas> getAll() => List.unmodifiable(_items);

  /// Nama kelas dianggap sama jika tahun ajaran dan nama sama
  /// (tidak peka huruf besar/kecil).
  bool exists({required String tahunAjaran, required String nama}) {
    final n = nama.trim().toLowerCase();
    return _items.any(
      (k) => k.tahunAjaran == tahunAjaran && k.nama.toLowerCase() == n,
    );
  }

  void add(Kelas item) => _items.insert(0, item);

  String generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}

/// Singleton repository instance.
final kelasRepository = KelasRepository();