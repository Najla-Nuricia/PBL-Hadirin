// lib/models/dosen/attendance_session.dart
import 'attendance_summary.dart';
import 'student_attendance.dart';

class AttendanceSession {
  const AttendanceSession({
    required this.className,
    required this.date,
    required this.students,
    this.courseName,
    this.jadwalId,
    this.isOpen = false,
    this.summary,
    this.isDemo = false,
  });

  /// Respons `GET /dosen/jadwal/{jadwal_id}/kehadiran`.
  factory AttendanceSession.fromApiJson(Map<String, dynamic> json) {
    final students = (json['students'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(StudentAttendance.fromJson)
        .toList(growable: false);
    return AttendanceSession(
      jadwalId: json['jadwal_id'] as String?,
      courseName: json['courseName'] as String?,
      className: (json['className'] as String?) ?? '',
      date: DateTime.tryParse((json['date'] as String?) ?? '') ?? DateTime.now(),
      isOpen: (json['is_open'] as bool?) ?? false,
      summary: AttendanceSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      students: students,
      isDemo: false,
    );
  }

  final String className;
  final String? courseName;
  final String? jadwalId;
  final DateTime date;
  final bool isOpen;
  final List<StudentAttendance> students;
  final AttendanceSummary? summary;

  /// True saat memakai data contoh karena data backend belum tersedia.
  final bool isDemo;

  /// Ringkasan sesi (dari backend atau dihitung ulang saat mode demo).
  AttendanceSummary get ringkasan => summary ?? AttendanceSummary.fromStudents(students);

  int get total => students.length;
}
