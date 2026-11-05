import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../../models/mhs/student_profile.dart';
import 'dummy_student_auth_repository.dart';
import 'student_attendance.dart';
import 'student_schedule.dart';

class StudentDataService {
  StudentDataService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers {
    final token = studentAuthRepository.currentAccessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── No 2: Api Load Data Mahasiswa ──────────────────────────────────────

  /// Mengambil data profil mahasiswa yang sedang login.
  Future<StudentProfile> loadProfile() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/me');
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return StudentProfile(
          fullName: data['fullName'] ?? 'Mahasiswa Demo',
          studentId: data['nim'] ?? '2341720001',
          email: data['email'] ?? 'demo@student.polinema.ac.id',
          phoneNumber: data['phoneNumber'] ?? '0812 3456 7890',
          role: data['role'] ?? 'Mahasiswa',
        );
      }
    } catch (_) {}
    return const StudentProfile(
      fullName: 'Mahasiswa Demo',
      studentId: '2341720001',
      email: 'ahmad.fauzi@student.polinema.ac.id',
      phoneNumber: '0812 3456 7890',
      role: 'Mahasiswa',
    );
  }

  /// Mengambil daftar jadwal kuliah mahasiswa (opsional filter per hari: 1=Senin, ..., 7=Minggu)
  Future<List<StudentSchedule>> loadSchedules({int? dayOfWeek}) async {
    try {
      final query = dayOfWeek != null ? '?day_of_week=$dayOfWeek' : '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/jadwal$query');
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          return StudentSchedule(
            courseName: m['course_name'] ?? '',
            startTime: m['start_time'] ?? '',
            endTime: m['end_time'] ?? '',
            room: m['room'] ?? '',
            lecturerName: m['lecturer_name'] ?? '',
            dayOfWeek: m['day_of_week'] ?? 1,
            hasAlarm: m['has_alarm'] ?? false,
          );
        }).toList();
      }
    } catch (_) {}
    return dummySchedules
        .where((s) => dayOfWeek == null || s.dayOfWeek == dayOfWeek)
        .toList();
  }

  /// Mengambil rekap kehadiran (hadir, izin, sakit, alfa)
  Future<StudentAttendanceSummary> loadAttendanceSummary() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/presensi/summary');
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return StudentAttendanceSummary(
          hadir: data['hadir'] ?? 12,
          izin: data['izin'] ?? 2,
          sakit: data['sakit'] ?? 1,
          alfa: data['alfa'] ?? 1,
        );
      }
    } catch (_) {}
    return dummyAttendanceSummary;
  }

  /// Mengambil pengingat kelas aktif terdekat
  Future<ClassReminder> loadClassReminder() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/pengingat');
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return ClassReminder(
          message: data['message'] ?? '30 menit lagi!',
          courseName: data['courseName'] ?? 'Pemrograman Web',
          time: data['time'] ?? '08:00',
          room: data['room'] ?? 'Ruang J301',
        );
      }
    } catch (_) {}
    return dummyClassReminder;
  }

  // ── No 3: CRUD Pengajuan Surat Izin / Sakit ─────────────────────────────

  /// [CREATE] Mengajukan surat izin atau sakit baru
  Future<Map<String, dynamic>> submitPengajuan({
    required String jenis,
    required String alasan,
    required String matakuliah,
    required String tanggal,
    String dokumenPath = '',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/pengajuan');
    final res = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'jenis': jenis,
            'alasan': alasan,
            'matakuliah': matakuliah,
            'tanggal': tanggal,
            'dokumen_path': dokumenPath,
          }),
        )
        .timeout(const Duration(seconds: 2));

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal mengirim pengajuan: ${res.statusCode}');
  }

  /// [READ] Mengambil daftar riwayat pengajuan surat
  Future<List<Map<String, dynamic>>> loadPengajuanList() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/pengajuan/list');
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// [UPDATE] Mengubah pengajuan surat yang masih pending
  Future<bool> updatePengajuan({
    required String pengajuanId,
    String? alasan,
    String? matakuliah,
    String? tanggal,
  }) async {
    try {
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/mahasiswa/pengajuan/$pengajuanId');
      final payload = <String, dynamic>{};
      if (alasan != null) payload['alasan'] = alasan;
      if (matakuliah != null) payload['matakuliah'] = matakuliah;
      if (tanggal != null) payload['tanggal'] = tanggal;

      final res = await _client
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// [DELETE] Membatalkan pengajuan surat
  Future<bool> deletePengajuan(String pengajuanId) async {
    try {
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/mahasiswa/pengajuan/$pengajuanId');
      final res = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── No 3: CRUD Data Mahasiswa ───────────────────────────────────────────

  /// [READ] List semua mahasiswa
  Future<List<Map<String, dynamic>>> listMahasiswa({
    String? search,
    String? kelas,
  }) async {
    try {
      final params = <String>[];
      if (search != null && search.isNotEmpty) params.add('search=$search');
      if (kelas != null && kelas.isNotEmpty) params.add('kelas=$kelas');
      final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa$qs');
      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// [CREATE] Tambah data mahasiswa baru
  Future<bool> createMahasiswa({
    required String nim,
    required String namaLengkap,
    required String email,
    String noHp = '',
    String kelas = 'TI-3A',
    String prodi = 'D4-TI',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa');
    final res = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'nim': nim,
            'nama_lengkap': namaLengkap,
            'email': email,
            'no_hp': noHp,
            'kelas': kelas,
            'prodi': prodi,
          }),
        )
        .timeout(const Duration(seconds: 2));
    return res.statusCode == 201;
  }

  /// [UPDATE] Perbarui data mahasiswa
  Future<bool> updateMahasiswa(
    String nim, {
    String? namaLengkap,
    String? email,
    String? noHp,
    String? kelas,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/$nim');
      final payload = <String, dynamic>{};
      if (namaLengkap != null) payload['nama_lengkap'] = namaLengkap;
      if (email != null) payload['email'] = email;
      if (noHp != null) payload['no_hp'] = noHp;
      if (kelas != null) payload['kelas'] = kelas;

      final res = await _client
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// [DELETE] Hapus data mahasiswa
  Future<bool> deleteMahasiswa(String nim) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/$nim');
      final res = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

final studentDataService = StudentDataService();

