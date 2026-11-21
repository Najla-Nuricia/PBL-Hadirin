import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mhs/schedule_reminder_service.dart';
import 'package:mobile/data/mhs/student_schedule.dart';

void main() {
  const schedule = StudentSchedule(
    courseName: 'Pemrograman Web',
    startTime: '08:00',
    endTime: '09:40',
    room: 'Ruang J301',
    lecturerName: 'Budi Santoso',
    dayOfWeek: 3, // Rabu
  );

  group('nextReminderTime', () {
    test('menjadwalkan 30 menit sebelum kelas minggu ini', () {
      final result = ScheduleReminderService.nextReminderTime(
        schedule,
        now: DateTime(2026, 11, 23, 7), // Senin
      );
      expect(result, DateTime(2026, 11, 25, 7, 30)); // Rabu
    });

    test('lempar ke minggu depan jika jendela hari ini sudah lewat', () {
      final result = ScheduleReminderService.nextReminderTime(
        schedule,
        now: DateTime(2026, 11, 25, 7, 31), // Rabu, lewat 07:30
      );
      expect(result, DateTime(2026, 12, 2, 7, 30));
    });

    test('null untuk format jam invalid', () {
      const invalid = StudentSchedule(
        courseName: 'Pemrograman Web',
        startTime: '25:99',
        endTime: '09:40',
        room: 'Ruang J301',
        lecturerName: 'Budi Santoso',
        dayOfWeek: 3,
      );
      expect(
        ScheduleReminderService.nextReminderTime(
          invalid,
          now: DateTime(2026, 11, 23, 7),
        ),
        isNull,
      );
    });
  });
}
