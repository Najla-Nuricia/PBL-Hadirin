// lib/models/dosen/student_attendance.dart
import 'attendance_status.dart';

class SupportingDocument {
  const SupportingDocument({
    required this.fileName,
    required this.sizeLabel,
    this.previewUrl,
  });

  final String fileName;
  final String sizeLabel;
  final String? previewUrl;
}

class StudentAttendance {
  const StudentAttendance({
    required this.nim,
    required this.name,
    required this.className,
    required this.status,
    this.checkInTime,
    this.note,
    this.document,
  });

  final String nim;
  final String name;
  final String className;
  final AttendanceStatus status;
  final String? checkInTime;
  final String? note;
  final SupportingDocument? document;

  String get id => nim;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}