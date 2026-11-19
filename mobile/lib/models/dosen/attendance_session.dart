// lib/models/dosen/attendance_session.dart
import 'student_attendance.dart';

class AttendanceSession {
  const AttendanceSession({
    required this.className,
    required this.date,
    required this.students,
  });

  final String className;
  final DateTime date;
  final List<StudentAttendance> students;

  int get total => students.length;
}