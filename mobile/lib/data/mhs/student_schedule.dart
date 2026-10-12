/// Model untuk jadwal kelas mahasiswa.
class StudentSchedule {
  const StudentSchedule({
    required this.courseName,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.lecturerName,
    required this.dayOfWeek,
    this.hasAlarm = false,
  });

  final String courseName;
  final String startTime;
  final String endTime;
  final String room;
  final String lecturerName;

  /// 1 = Senin, 2 = Selasa, ... 7 = Minggu
  final int dayOfWeek;
  final bool hasAlarm;

  StudentSchedule copyWith({bool? hasAlarm}) => StudentSchedule(
    courseName: courseName,
    startTime: startTime,
    endTime: endTime,
    room: room,
    lecturerName: lecturerName,
    dayOfWeek: dayOfWeek,
    hasAlarm: hasAlarm ?? this.hasAlarm,
  );
}

/// Data dummy jadwal kelas untuk demo.
const dummySchedules = [
  StudentSchedule(
    courseName: 'Pemrograman Web',
    startTime: '08:00',
    endTime: '09:40',
    room: 'Ruang J301',
    lecturerName: 'Budi Santoso, S.T., M.T.',
    dayOfWeek: 3, // Rabu
    hasAlarm: true,
  ),
  StudentSchedule(
    courseName: 'Basis Data',
    startTime: '10:00',
    endTime: '11:40',
    room: 'Ruang J302',
    lecturerName: 'R. Ardinawati, M.Kom.',
    dayOfWeek: 3,
    hasAlarm: false,
  ),
  StudentSchedule(
    courseName: 'Interaksi Manusia Komputer',
    startTime: '13:00',
    endTime: '14:40',
    room: 'Ruang J201',
    lecturerName: 'Rizky Putra, M.T.',
    dayOfWeek: 3,
    hasAlarm: false,
  ),
  StudentSchedule(
    courseName: 'Proyek Akhir',
    startTime: '15:00',
    endTime: '16:40',
    room: 'Ruang J301',
    lecturerName: 'Dewi Canyono, S.T., M.Eng.',
    dayOfWeek: 3,
    hasAlarm: false,
  ),
];
