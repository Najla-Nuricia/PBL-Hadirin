import 'attendance_summary.dart';
import 'lecturer_profile.dart';

/// Satu jadwal dosen dari `GET /dosen/dashboard`.
class DosenJadwalItem {
  const DosenJadwalItem({
    required this.jadwalId,
    this.kelasId = '',
    this.courseCode,
    this.courseName,
    this.kelas,
    this.hari,
    this.startTime = '',
    this.endTime = '',
    this.room,
    this.jumlahMahasiswa = 0,
    this.jumlahSesi = 0,
    this.hariIni = false,
    this.summary = const AttendanceSummary(),
  });

  factory DosenJadwalItem.fromJson(Map<String, dynamic> json) {
    return DosenJadwalItem(
      jadwalId: (json['jadwal_id'] as String?) ?? '',
      kelasId: (json['kelas_id'] as String?) ?? '',
      courseCode: json['course_code'] as String?,
      courseName: json['course_name'] as String?,
      kelas: json['kelas'] as String?,
      hari: json['hari'] as String?,
      startTime: (json['start_time'] as String?) ?? '',
      endTime: (json['end_time'] as String?) ?? '',
      room: json['room'] as String?,
      jumlahMahasiswa: (json['jumlah_mahasiswa'] as num?)?.toInt() ?? 0,
      jumlahSesi: (json['jumlah_sesi'] as num?)?.toInt() ?? 0,
      hariIni: (json['hari_ini'] as bool?) ?? false,
      summary: AttendanceSummary.fromJson(
        json['ringkasan_kehadiran'] as Map<String, dynamic>?,
      ),
    );
  }

  final String jadwalId;
  final String kelasId;
  final String? courseCode;
  final String? courseName;
  final String? kelas;
  final String? hari;
  final String startTime;
  final String endTime;
  final String? room;
  final int jumlahMahasiswa;
  final int jumlahSesi;
  final bool hariIni;
  final AttendanceSummary summary;

  String get courseLabel => courseName ?? courseCode ?? 'Mata kuliah';

  bool matches({required String kelas, required String mataKuliah}) {
    bool same(String? a, String b) =>
        (a ?? '').trim().toLowerCase() == b.trim().toLowerCase();
    return same(this.kelas, kelas) && same(courseName, mataKuliah);
  }
}

/// Respons `GET /dosen/dashboard`.
class DosenDashboard {
  const DosenDashboard({
    required this.dosen,
    required this.tanggal,
    required this.summary,
    required this.jadwal,
    required this.kelas,
    this.hari,
    this.totalKelas = 0,
    this.totalJadwal = 0,
    this.totalMahasiswa = 0,
    this.isDemo = false,
  });

  factory DosenDashboard.fromJson(Map<String, dynamic> json) {
    final dosenJson = json['dosen'];
    return DosenDashboard(
      dosen: dosenJson is Map<String, dynamic>
          ? LecturerProfile.fromJson(dosenJson)
          : const LecturerProfile(
              fullName: 'Dosen',
              staffId: '',
              email: '',
              phoneNumber: '',
              role: 'Dosen',
            ),
      tanggal: (json['tanggal'] as String?) ?? '',
      hari: json['hari'] as String?,
      summary: AttendanceSummary.fromJson(
        json['ringkasan_kehadiran'] as Map<String, dynamic>?,
      ),
      jadwal: (json['jadwal'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DosenJadwalItem.fromJson)
          .toList(growable: false),
      kelas: (json['kelas'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      totalKelas: (json['total_kelas'] as num?)?.toInt() ?? 0,
      totalJadwal: (json['total_jadwal'] as num?)?.toInt() ?? 0,
      totalMahasiswa: (json['total_mahasiswa'] as num?)?.toInt() ?? 0,
    );
  }

  final LecturerProfile dosen;
  final String tanggal;
  final String? hari;
  final AttendanceSummary summary;
  final List<DosenJadwalItem> jadwal;
  final List<Map<String, dynamic>> kelas;
  final int totalKelas;
  final int totalJadwal;
  final int totalMahasiswa;

  /// True saat memakai data contoh karena data backend belum tersedia.
  final bool isDemo;

  List<String> get kelasOptions => jadwal
      .map((j) => j.kelas)
      .whereType<String>()
      .where((k) => k.trim().isNotEmpty)
      .toSet()
      .toList();

  List<String> get mataKuliahOptions => jadwal
      .map((j) => j.courseName)
      .whereType<String>()
      .where((k) => k.trim().isNotEmpty)
      .toSet()
      .toList();

  DosenJadwalItem? findJadwal({required String kelas, required String mataKuliah}) {
    for (final item in jadwal) {
      if (item.matches(kelas: kelas, mataKuliah: mataKuliah)) return item;
    }
    return null;
  }
}
