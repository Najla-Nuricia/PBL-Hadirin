// lib/models/dosen/attendance_status.dart
enum AttendanceStatus {
  hadir('Hadir'),
  izin('Izin'),
  sakit('Sakit'),
  alfa('Alfa');

  const AttendanceStatus(this.label);
  final String label;

  /// Izin & sakit perlu ditinjau dosen (Terima / Tolak).
  bool get needsReview => this == izin || this == sakit;
}