/// Model untuk rekap kehadiran mahasiswa.
class StudentAttendanceSummary {
  const StudentAttendanceSummary({
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alfa,
  });

  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;
}

/// Dummy data rekap kehadiran.
const dummyAttendanceSummary = StudentAttendanceSummary(
  hadir: 12,
  izin: 2,
  sakit: 1,
  alfa: 1,
);

/// Model untuk notifikasi/pengingat kelas.
class ClassReminder {
  const ClassReminder({
    required this.message,
    required this.courseName,
    required this.time,
    required this.room,
  });

  final String message;
  final String courseName;
  final String time;
  final String room;
}

/// Dummy pengingat kelas aktif.
const dummyClassReminder = ClassReminder(
  message: '30 menit lagi!',
  courseName: 'Pemrograman Web',
  time: '08:00',
  room: 'Ruang J301',
);
