import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dosen/attendance_session.dart';
import '../../models/dosen/attendance_status.dart';
import '../../models/dosen/lecturer_profile.dart';
import '../../models/dosen/student_attendance.dart';
import 'lecturer_dummy_data.dart';
import 'lecturer_profile_preview.dart'; // sesuaikan dengan nama file Anda

/// Sesi kehadiran. Ubah menjadi FutureProvider/AsyncNotifier saat memakai API.
final attendanceSessionProvider = Provider<AttendanceSession>(
  (ref) => LecturerDummyData.session,
);

final lecturerProfileProvider = Provider<LecturerProfile>(
  (ref) => lecturerProfilePreview,
);

/// Filter status daftar kehadiran (null = semua).
class AttendanceFilterNotifier extends Notifier<AttendanceStatus?> {
  @override
  AttendanceStatus? build() => null;

  void select(AttendanceStatus? status) => state = status;
}

final attendanceFilterProvider =
    NotifierProvider<AttendanceFilterNotifier, AttendanceStatus?>(
  AttendanceFilterNotifier.new,
);

final filteredStudentsProvider = Provider<List<StudentAttendance>>((ref) {
  final students = ref.watch(attendanceSessionProvider).students;
  final filter = ref.watch(attendanceFilterProvider);
  if (filter == null) return students;
  return students.where((s) => s.status == filter).toList();
});

final studentByIdProvider = Provider.family<StudentAttendance?, String>((ref, id) {
  for (final s in ref.watch(attendanceSessionProvider).students) {
    if (s.id == id) return s;
  }
  return null;
});

/// Keputusan dosen atas pengajuan izin/sakit.
enum LeaveDecision { accepted, rejected }

class LeaveDecisionNotifier extends Notifier<Map<String, LeaveDecision>> {
  @override
  Map<String, LeaveDecision> build() => {};

  void decide(String studentId, LeaveDecision decision) =>
      state = {...state, studentId: decision};
}

final leaveDecisionProvider =
    NotifierProvider<LeaveDecisionNotifier, Map<String, LeaveDecision>>(
  LeaveDecisionNotifier.new,
);