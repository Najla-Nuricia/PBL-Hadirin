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
  KelasRepository() : _items = List.of(_seed);

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