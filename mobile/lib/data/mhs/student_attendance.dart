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

enum AttendanceStatus { hadir, izin, sakit, alfa }

class StudentAttendanceRecord {
  const StudentAttendanceRecord({
    required this.date,
    required this.courseName,
    required this.time,
    required this.status,
  });

  final String date;
  final String courseName;
  final String time;
  final AttendanceStatus status;
}

const dummyAttendanceRecords = [
  StudentAttendanceRecord(
    date: '14',
    courseName: 'Pemrograman Web',
    time: '10:05',
    status: AttendanceStatus.hadir,
  ),
  StudentAttendanceRecord(
    date: '13',
    courseName: 'Basis Data',
    time: '10:02',
    status: AttendanceStatus.izin,
  ),
  StudentAttendanceRecord(
    date: '13',
    courseName: 'Interaksi Manusia Komputer',
    time: '13:10',
    status: AttendanceStatus.sakit,
  ),
  StudentAttendanceRecord(
    date: '08',
    courseName: 'Pemrograman Web',
    time: '10:07',
    status: AttendanceStatus.hadir,
  ),
  StudentAttendanceRecord(
    date: '06',
    courseName: 'Proyek Akhir',
    time: '15:12',
    status: AttendanceStatus.alfa,
  ),
];

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
