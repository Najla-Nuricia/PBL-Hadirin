import 'attendance_status.dart';
import 'student_attendance.dart';

/// Ringkasan kehadiran dari field `ringkasan_kehadiran`/`summary` backend.
class AttendanceSummary {
  const AttendanceSummary({
    this.hadir = 0,
    this.izin = 0,
    this.sakit = 0,
    this.alfa = 0,
    this.total = 0,
    this.persentaseKehadiran = 0,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AttendanceSummary();
    return AttendanceSummary(
      hadir: (json['hadir'] as num?)?.toInt() ?? 0,
      izin: (json['izin'] as num?)?.toInt() ?? 0,
      sakit: (json['sakit'] as num?)?.toInt() ?? 0,
      alfa: (json['alfa'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      persentaseKehadiran:
          (json['persentase_kehadiran'] as num?)?.toInt() ?? 0,
    );
  }

  /// Hitung ringkasan dari daftar mahasiswa (dipakai mode demo/offline).
  factory AttendanceSummary.fromStudents(List<StudentAttendance> students) {
    var hadir = 0;
    var izin = 0;
    var sakit = 0;
    var alfa = 0;
    for (final student in students) {
      switch (student.status) {
        case AttendanceStatus.hadir:
          hadir++;
        case AttendanceStatus.izin:
          izin++;
        case AttendanceStatus.sakit:
          sakit++;
        case AttendanceStatus.alfa:
          alfa++;
      }
    }
    final total = students.length;
    return AttendanceSummary(
      hadir: hadir,
      izin: izin,
      sakit: sakit,
      alfa: alfa,
      total: total,
      persentaseKehadiran: total == 0 ? 0 : (hadir * 100 ~/ total),
    );
  }

  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;
  final int total;
  final int persentaseKehadiran;
}
