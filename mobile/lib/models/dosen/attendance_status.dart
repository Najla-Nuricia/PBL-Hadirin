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

/// Status dari API backend (snake_case/lowercase) ke enum Flutter.
AttendanceStatus attendanceStatusFromApi(String raw) => switch (raw.toLowerCase()) {
  'hadir' => AttendanceStatus.hadir,
  'izin' => AttendanceStatus.izin,
  'sakit' => AttendanceStatus.sakit,
  _ => AttendanceStatus.alfa,
};