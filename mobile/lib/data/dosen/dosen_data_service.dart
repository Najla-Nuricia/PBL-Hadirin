import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../../models/dosen/attendance_session.dart';
import '../../models/dosen/attendance_status.dart';
import '../../models/dosen/attendance_summary.dart';
import '../../models/dosen/dosen_dashboard.dart';
import '../../models/dosen/lecturer_profile.dart';
import 'dummy_lecturer_auth_repository.dart';
import 'lecturer_dummy_data.dart';

/// Data dosen dari backend FastAPI: dashboard (ringkasan) & daftar kehadiran.
class DosenDataService {
  DosenDataService({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  static const _timeout = Duration(seconds: 8);
  final http.Client _client;

  Map<String, String> get _headers {
    final token = lecturerAuthRepository.currentAccessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String _extractError(http.Response res, String fallback) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return '$fallback (${res.statusCode})';
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// `GET /dosen/dashboard` — ringkasan kehadiran, kelas, dan jadwal dosen.
  Future<DosenDashboard> loadDashboard() async {
    if (lecturerAuthRepository.hasRemoteSession) {
      final uri = Uri.parse('${ApiConfig.baseUrl}/dosen/dashboard');
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final dashboard = DosenDashboard.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
        // Belum ada jadwal tersimpan → tampilkan data contoh.
        if (dashboard.jadwal.isNotEmpty) return dashboard;
        return _demoDashboard();
      }
      if (res.statusCode == 401) {
        throw Exception('Sesi login berakhir. Silakan masuk ulang.');
      }
      throw Exception(_extractError(res, 'Gagal memuat ringkasan kehadiran'));
    }
    return _demoDashboard();
  }

  /// `GET /dosen/jadwal/{jadwal_id}/kehadiran?tanggal=...`
  Future<AttendanceSession> loadKehadiran(
    String jadwalId, {
    DateTime? tanggal,
  }) async {
    if (lecturerAuthRepository.hasRemoteSession) {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/dosen/jadwal/${Uri.encodeComponent(jadwalId)}/kehadiran',
      ).replace(
        queryParameters: tanggal == null ? null : {'tanggal': _isoDate(tanggal)},
      );
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final session = AttendanceSession.fromApiJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
        // Belum ada mahasiswa / belum ada yang absen → kartu ringkas saja.
        if (session.students.isEmpty ||
            session.students.every((s) => s.status == AttendanceStatus.alfa)) {
          return AttendanceSession(
            jadwalId: session.jadwalId,
            courseName: session.courseName,
            className: session.className,
            date: session.date,
            isOpen: session.isOpen,
            summary: session.summary,
            students: const [],
            isDemo: true,
          );
        }
        return session;
      }
      if (res.statusCode == 401) {
        throw Exception('Sesi login berakhir. Silakan masuk ulang.');
      }
      // 404 (belum ada sesi) / 422 (jadwal contoh) → kartu ringkas saja.
      if (res.statusCode == 404 || res.statusCode == 422) {
        return LecturerDummyData.emptySession;
      }
      throw Exception(_extractError(res, 'Gagal memuat daftar kehadiran'));
    }
    return LecturerDummyData.session;
  }

  DosenDashboard _demoDashboard() {
    final session = LecturerDummyData.session;
    return DosenDashboard(
      dosen: const LecturerProfile(
        fullName: 'Dr. Andi Pratama, S.T., M.Kom.',
        staffId: '1985061520121003',
        email: 'dosen@hadirin.id',
        phoneNumber: '0812 3456 7890',
        role: 'Dosen',
      ),
      tanggal: _isoDate(session.date),
      summary: AttendanceSummary.fromStudents(session.students),
      totalMahasiswa: session.students.length,
      isDemo: true,
      jadwal: const [
        DosenJadwalItem(
          jadwalId: 'demo',
          courseName: 'Basis Data',
          kelas: 'TI-3A',
          hari: 'senin',
          startTime: '08:00',
          endTime: '10:30',
        ),
      ],
      kelas: const [],
    );
  }
}

final dosenDataService = DosenDataService();
