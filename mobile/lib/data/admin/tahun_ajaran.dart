/// Status tahun ajaran.
enum TahunAjaranStatus { aktif, nonAktif }

extension TahunAjaranStatusLabel on TahunAjaranStatus {
  String get label => switch (this) {
    TahunAjaranStatus.aktif => 'Aktif',
    TahunAjaranStatus.nonAktif => 'Non-Aktif',
  };
}

/// Model semester yang tersedia dalam satu tahun ajaran.
class SemesterInfo {
  const SemesterInfo({
    required this.namaGanjil,
    required this.periodGanjil,
    required this.namaGenap,
    required this.periodGenap,
  });

  final String namaGanjil;
  final String periodGanjil;
  final String namaGenap;
  final String periodGenap;
}

const defaultSemesterInfo = SemesterInfo(
  namaGanjil: 'Ganjil',
  periodGanjil: 'September – Januari',
  namaGenap: 'Genap',
  periodGenap: 'Februari – Agustus',
);

/// Model data Tahun Ajaran.
class TahunAjaran {
  const TahunAjaran({
    required this.id,
    required this.tahun,
    required this.status,
    required this.semesterGanjil,
    required this.semesterGenap,
    this.tanggalMulai,
    this.tanggalSelesai,
  });

  final String id;

  /// Format: "2026/2027"
  final String tahun;

  final TahunAjaranStatus status;
  final bool semesterGanjil;
  final bool semesterGenap;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;

  /// Label subtitle untuk list, e.g. "Ganjil & Genap"
  String get semesterLabel {
    if (semesterGanjil && semesterGenap) return 'Ganjil & Genap';
    if (semesterGanjil) return 'Ganjil';
    if (semesterGenap) return 'Genap';
    return '-';
  }

  TahunAjaran copyWith({
    String? tahun,
    TahunAjaranStatus? status,
    bool? semesterGanjil,
    bool? semesterGenap,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
  }) {
    return TahunAjaran(
      id: id,
      tahun: tahun ?? this.tahun,
      status: status ?? this.status,
      semesterGanjil: semesterGanjil ?? this.semesterGanjil,
      semesterGenap: semesterGenap ?? this.semesterGenap,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
    );
  }
}

/// In-memory repository untuk Tahun Ajaran (dummy, sampai backend siap).
class TahunAjaranRepository {
  TahunAjaranRepository() : _items = List.of(_seedData);

  static final _seedData = [
    TahunAjaran(
      id: '1',
      tahun: '2026/2027',
      status: TahunAjaranStatus.aktif,
      semesterGanjil: true,
      semesterGenap: true,
      tanggalMulai: DateTime(2026, 9, 1),
      tanggalSelesai: DateTime(2027, 8, 31),
    ),
    TahunAjaran(
      id: '2',
      tahun: '2025/2026',
      status: TahunAjaranStatus.nonAktif,
      semesterGanjil: true,
      semesterGenap: true,
      tanggalMulai: DateTime(2025, 9, 1),
      tanggalSelesai: DateTime(2026, 8, 31),
    ),
    TahunAjaran(
      id: '3',
      tahun: '2024/2025',
      status: TahunAjaranStatus.nonAktif,
      semesterGanjil: true,
      semesterGenap: true,
      tanggalMulai: DateTime(2024, 9, 1),
      tanggalSelesai: DateTime(2025, 8, 31),
    ),
    TahunAjaran(
      id: '4',
      tahun: '2023/2024',
      status: TahunAjaranStatus.nonAktif,
      semesterGanjil: true,
      semesterGenap: true,
      tanggalMulai: DateTime(2023, 9, 1),
      tanggalSelesai: DateTime(2024, 8, 31),
    ),
  ];

  final List<TahunAjaran> _items;

  List<TahunAjaran> getAll() => List.unmodifiable(_items);

  List<TahunAjaran> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return _items.where((t) => t.tahun.toLowerCase().contains(q)).toList();
  }

  void add(TahunAjaran item) {
    // Jika status aktif, nonaktifkan yang lain
    if (item.status == TahunAjaranStatus.aktif) {
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(status: TahunAjaranStatus.nonAktif);
      }
    }
    _items.insert(0, item);
  }

  String generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}

/// Singleton repository instance.
final tahunAjaranRepository = TahunAjaranRepository();
