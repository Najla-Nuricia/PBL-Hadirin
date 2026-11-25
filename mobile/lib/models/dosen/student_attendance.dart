// lib/models/dosen/student_attendance.dart
import 'attendance_status.dart';

class SupportingDocument {
  const SupportingDocument({
    required this.fileName,
    this.sizeLabel = '',
    this.previewUrl,
    this.path,
  });

  factory SupportingDocument.fromJson(Map<String, dynamic> json) {
    return SupportingDocument(
      fileName: (json['fileName'] as String?) ?? '',
      path: json['path'] as String?,
    );
  }

  final String fileName;
  final String sizeLabel;
  final String? previewUrl;

  /// Path dokumen dari backend (`dokumen_path` pengajuan).
  final String? path;
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

  factory StudentAttendance.fromJson(Map<String, dynamic> json) {
    final document = json['document'];
    return StudentAttendance(
      nim: (json['nim'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      className: (json['className'] as String?) ?? '',
      status: attendanceStatusFromApi((json['status'] as String?) ?? 'alfa'),
      checkInTime: json['checkInTime'] as String?,
      note: json['note'] as String?,
      document: document is Map<String, dynamic>
          ? SupportingDocument.fromJson(document)
          : null,
    );
  }

  final String nim;
  final String name;
  final String className;
  final AttendanceStatus status;
  final String? checkInTime;
  final String? note;
  final SupportingDocument? document;

  String get id => nim;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
