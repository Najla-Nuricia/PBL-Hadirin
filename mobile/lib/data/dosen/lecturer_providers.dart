import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dosen/attendance_session.dart';
import '../../models/dosen/attendance_status.dart';
import '../../models/dosen/dosen_dashboard.dart';
import '../../models/dosen/lecturer_profile.dart';
import '../../models/dosen/matkul_option.dart';
import '../../models/dosen/student_attendance.dart';
import 'dosen_data_service.dart';
import 'lecturer_dummy_data.dart';
import 'lecturer_profile_preview.dart';

/// Ringkasan kehadiran + jadwal dosen (`GET /dosen/dashboard`).
final dosenDashboardProvider = FutureProvider<DosenDashboard>((ref) {
  return dosenDataService.loadDashboard();
});

/// Opsi mata kuliah dari backend, bergantung pada kelas + tanggal.
final dosenMatkulProvider =
    FutureProvider.family<List<MatkulOption>, ({String kelasId, DateTime tanggal})>(
  (ref, query) {
    return dosenDataService.loadMatkulOptions(
      kelasId: query.kelasId,
      tanggal: query.tanggal,
    );
  },
);

/// Jadwal & tanggal yang dipilih di halaman Cek Daftar Presensi.
class AttendanceQuery {
  const AttendanceQuery({required this.jadwalId, this.tanggal});

  final String jadwalId;
  final DateTime? tanggal;

  @override
  bool operator ==(Object other) =>
      other is AttendanceQuery &&
      other.jadwalId == jadwalId &&
      other.tanggal == tanggal;

  @override
  int get hashCode => Object.hash(jadwalId, tanggal);
}

class AttendanceQueryNotifier extends Notifier<AttendanceQuery?> {
  @override
  AttendanceQuery? build() => null;

  void select(AttendanceQuery query) => state = query;

  void clear() => state = null;
}

final attendanceQueryProvider =
    NotifierProvider<AttendanceQueryNotifier, AttendanceQuery?>(
  AttendanceQueryNotifier.new,
);

/// Daftar hadir mahasiswa (`GET /dosen/jadwal/{jadwal_id}/kehadiran`).
final attendanceSessionProvider = FutureProvider<AttendanceSession>((ref) {
  final query = ref.watch(attendanceQueryProvider);
  if (query == null) return LecturerDummyData.session;
  return dosenDataService.loadKehadiran(query.jadwalId, tanggal: query.tanggal);
});

final lecturerProfileProvider = Provider<LecturerProfile>((ref) {
  return currentLecturerProfile();
});

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
  final students =
      ref.watch(attendanceSessionProvider).value?.students ??
      const <StudentAttendance>[];
  final filter = ref.watch(attendanceFilterProvider);
  if (filter == null) return students;
  return students.where((s) => s.status == filter).toList();
});

final studentByIdProvider = Provider.family<StudentAttendance?, String>((ref, id) {
  final students =
      ref.watch(attendanceSessionProvider).value?.students ??
      const <StudentAttendance>[];
  for (final s in students) {
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
