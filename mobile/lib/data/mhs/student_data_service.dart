import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../../models/mhs/student_profile.dart';
import 'dummy_student_auth_repository.dart';
import 'student_attendance.dart';
import 'student_schedule.dart';

class StudentDataService {
  StudentDataService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  static const _timeout = Duration(seconds: 8);
  final http.Client _client;

  Map<String, String> get _headers {
    final token = studentAuthRepository.currentAccessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> get _authOnlyHeaders {
    final token = studentAuthRepository.currentAccessToken;
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  bool get _hasRemoteSession => studentAuthRepository.hasRemoteSession;

  String _extractError(http.Response res, String fallback) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return '$fallback (${res.statusCode})';
  }

  // ── Profil Mahasiswa ────────────────────────────────────────────────────

  Future<StudentProfile> loadProfile() async {
    if (_hasRemoteSession) {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/me');
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final fullName = (data['fullName'] as String?) ??
            (data['nama_lengkap'] as String?) ??
            '';
        final className = (data['className'] as String?) ??
            (data['kelas'] as String?) ??
            '';
        studentAuthRepository.updateCurrentAccount(
          fullName: fullName.isNotEmpty ? fullName : null,
          className: className.isNotEmpty ? className : null,
        );
        return StudentProfile(
          fullName: fullName,
          studentId: (data['nim'] as String?) ?? '',
          email: (data['email'] as String?) ?? '',
          phoneNumber: (data['phoneNumber'] as String?) ??
              (data['no_hp'] as String?) ??
              '',
          role: (data['role'] as String?) ?? 'Mahasiswa',
          className: className,
        );
      }
      if (res.statusCode == 401) {
        throw Exception('Sesi login berakhir. Silakan masuk ulang.');
      }
    }

    final acc = studentAuthRepository.currentAccount;
    return StudentProfile(
      fullName: acc?.fullName ?? 'Mahasiswa Demo',
      studentId: acc?.nim ?? '2341720001',
      email: '',
      phoneNumber: '',
      role: 'Mahasiswa',
      className: acc?.className ?? '',
    );
  }

  Future<StudentProfile> updateMyProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? className,
  }) async {
    if (!_hasRemoteSession) {
      return StudentProfile(
        fullName: fullName,
        studentId: studentAuthRepository.currentAccount?.nim ?? '',
        email: email,
        phoneNumber: phoneNumber,
        role: 'Mahasiswa',
        className: className ?? '',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/me');
    final body = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      if (className != null && className.trim().isNotEmpty)
        'className': className.trim(),
    };
    final res = await _client
        .put(uri, headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final data =
          (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      final updatedName = (data['fullName'] as String?) ?? fullName;
      final updatedClass = (data['className'] as String?) ?? className ?? '';
      studentAuthRepository.updateCurrentAccount(
        fullName: updatedName,
        className: updatedClass.isNotEmpty ? updatedClass : null,
      );
      return StudentProfile(
        fullName: updatedName,
        studentId: (data['nim'] as String?) ?? '',
        email: (data['email'] as String?) ?? email,
        phoneNumber: (data['phoneNumber'] as String?) ?? phoneNumber,
        role: (data['role'] as String?) ?? 'Mahasiswa',
        className: updatedClass,
      );
    }
    throw Exception(_extractError(res, 'Gagal memperbarui profil'));
  }

  // ── Jadwal & Pengingat ──────────────────────────────────────────────────

  Future<List<StudentSchedule>> loadSchedules({int? dayOfWeek}) async {
    if (_hasRemoteSession) {
      final query = dayOfWeek != null ? '?day_of_week=$dayOfWeek' : '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/jadwal$query');
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map<String, dynamic>
            ? (decoded['data'] as List<dynamic>? ?? const [])
            : (decoded as List<dynamic>);
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          return StudentSchedule(
            courseName: (m['courseName'] as String?) ??
                (m['matkul_nama'] as String?) ??
                (m['course_name'] as String?) ??
                '',
            startTime: (m['jam_mulai'] as String?) ??
                (m['start_time'] as String?) ??
                '',
            endTime: (m['jam_selesai'] as String?) ??
                (m['end_time'] as String?) ??
                '',
            room: (m['ruangan_nama'] as String?) ??
                (m['room'] as String?) ??
                '-',
            lecturerName: (m['dosen_nama'] as String?) ??
                (m['lecturer_name'] as String?) ??
                '-',
            dayOfWeek: (m['day_of_week'] as int?) ?? 1,
            hasAlarm: (m['has_alarm'] as bool?) ?? false,
          );
        }).toList();
      }
      throw Exception(_extractError(res, 'Gagal memuat jadwal kuliah'));
    }

    return dummySchedules
        .where((s) => dayOfWeek == null || s.dayOfWeek == dayOfWeek)
        .toList();
  }

  Future<StudentAttendanceSummary> loadAttendanceSummary() async {
    if (_hasRemoteSession) {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/presensi/summary');
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return StudentAttendanceSummary(
          hadir: (data['hadir'] as int?) ?? 0,
          izin: (data['izin'] as int?) ?? 0,
          sakit: (data['sakit'] as int?) ?? 0,
          alfa: (data['alfa'] as int?) ?? 0,
        );
      }
      throw Exception(_extractError(res, 'Gagal memuat rekap presensi'));
    }
    return dummyAttendanceSummary;
  }

  Future<List<StudentAttendanceRecord>> loadAttendanceHistory({
    String? status,
  }) async {
    if (_hasRemoteSession) {
      final query = (status != null && status.isNotEmpty) ? '?status=$status' : '';
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/mahasiswa/presensi/riwayat$query');
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final list = decoded['data'] as List<dynamic>? ?? const [];
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final rawDate = (m['tanggal'] as String?) ?? (m['date'] as String?) ?? '-';
          final parsedDay = rawDate.contains('-') && rawDate.length >= 10
              ? rawDate.split('-').last
              : rawDate;
          return StudentAttendanceRecord(
            date: parsedDay,
            courseName: (m['courseName'] as String?) ??
                (m['matkul_nama'] as String?) ??
                '-',
            time: (m['time'] as String?) ?? (m['jam_masuk'] as String?) ?? '-',
            status: _parseStatus((m['status'] as String?) ?? 'alfa'),
          );
        }).toList();
      }
      throw Exception(_extractError(res, 'Gagal memuat riwayat presensi'));
    }

    return dummyAttendanceRecords;
  }

  AttendanceStatus _parseStatus(String raw) => switch (raw.toLowerCase()) {
        'hadir' => AttendanceStatus.hadir,
        'izin' => AttendanceStatus.izin,
        'sakit' => AttendanceStatus.sakit,
        _ => AttendanceStatus.alfa,
      };

  Future<ClassReminder?> loadClassReminder() async {
    if (_hasRemoteSession) {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/pengingat');
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>?;
        if (data == null) return null;
        return ClassReminder(
          message: (data['message'] as String?) ??
              (data['status_label'] as String?) ??
              'Jadwal Berikutnya',
          courseName: (data['courseName'] as String?) ??
              (data['matkul_nama'] as String?) ??
              '',
          time: (data['time'] as String?) ?? '',
          room: (data['room'] as String?) ??
              (data['ruangan_nama'] as String?) ??
              '-',
        );
      }
      return null;
    }
    return dummyClassReminder;
  }

  // ── Presensi (QR / Face / Sesi Aktif) ───────────────────────────────────

  Future<List<Map<String, dynamic>>> loadActiveSessions() async {
    if (!_hasRemoteSession) return const [];
    final uri = Uri.parse('${ApiConfig.baseUrl}/attendance/sesi-aktif');
    final res = await _client.get(uri, headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final list = decoded['data'] as List<dynamic>? ?? const [];
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception(_extractError(res, 'Gagal memuat sesi presensi aktif'));
  }

  Future<Map<String, dynamic>> getFaceStatus() async {
    if (!_hasRemoteSession) {
      return {'is_registered': false, 'active_samples': 0, 'threshold': 0.5};
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/wajah/status');
    final res = await _client.get(uri, headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(res, 'Gagal memuat status data wajah'));
  }

  Future<Map<String, dynamic>> submitQrAttendance({
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    if (!_hasRemoteSession && studentAuthRepository.useRemoteApi) {
      throw Exception(
        'Sesi login server belum aktif. Pastikan backend aktif di ${ApiConfig.baseUrl} lalu masuk ulang.',
      );
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/attendance/qr');
    final res = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'qr_token': qrToken,
            'latitude': latitude,
            'longitude': longitude,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(res, 'Presensi QR gagal'));
  }

  Future<Map<String, dynamic>> submitFaceAttendance({
    required Uint8List imageBytes,
    String filename = 'probe.jpg',
    String? sesiPresensiId,
    String? qrToken,
    double? latitude,
    double? longitude,
  }) async {
    if (!_hasRemoteSession && studentAuthRepository.useRemoteApi) {
      throw Exception(
        'Sesi login server belum aktif. Pastikan backend aktif di ${ApiConfig.baseUrl} lalu masuk ulang.',
      );
    }
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/attendance/face'),
    )..headers.addAll(_authOnlyHeaders);

    if (sesiPresensiId != null && sesiPresensiId.isNotEmpty) {
      req.fields['sesi_presensi_id'] = sesiPresensiId;
    }
    if (qrToken != null && qrToken.isNotEmpty) {
      req.fields['qr_token'] = qrToken;
    }
    if (latitude != null && longitude != null) {
      req.fields['latitude'] = latitude.toString();
      req.fields['longitude'] = longitude.toString();
    }
    req.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
    );

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(res, 'Verifikasi wajah presensi gagal'));
  }

  // ── Pengajuan Surat Izin / Sakit ────────────────────────────────────────

  Future<Map<String, dynamic>> submitPengajuan({
    required String jenis,
    required String alasan,
    required String matakuliah,
    required String tanggal,
    String dokumenPath = '',
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    if (!_hasRemoteSession && studentAuthRepository.useRemoteApi) {
      throw Exception(
        'Sesi login server belum aktif. Pastikan backend aktif di ${ApiConfig.baseUrl} lalu masuk ulang.',
      );
    }
    if (fileBytes != null && fileBytes.isNotEmpty) {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/mahasiswa/pengajuan/upload'),
      )..headers.addAll(_authOnlyHeaders);

      req.fields['jenis'] = jenis;
      req.fields['alasan'] = alasan;
      req.fields['matakuliah'] = matakuliah;
      req.fields['tanggal'] = tanggal;
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: (fileName != null && fileName.isNotEmpty)
              ? fileName
              : 'surat_izin.pdf',
        ),
      );

      final streamed = await req.send().timeout(const Duration(seconds: 20));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw Exception(_extractError(res, 'Gagal mengunggah surat'));
    }

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
            if (dokumenPath.isNotEmpty) 'dokumen_path': dokumenPath,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(res, 'Gagal mengirim pengajuan'));
  }

  Future<List<Map<String, dynamic>>> loadPengajuanList() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/pengajuan');
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map<String, dynamic>
            ? (decoded['data'] as List<dynamic>? ?? const [])
            : (decoded as List<dynamic>);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

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
          .put(uri, headers: _headers, body: jsonEncode(payload))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePengajuan(String pengajuanId) async {
    try {
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/mahasiswa/pengajuan/$pengajuanId');
      final res =
          await _client.delete(uri, headers: _headers).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── CRUD Data Mahasiswa ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listMahasiswa({
    String? search,
    String? kelas,
  }) async {
    try {
      final params = <String>[];
      if (search != null && search.isNotEmpty) {
        params.add('search=${Uri.encodeQueryComponent(search)}');
      }
      if (kelas != null && kelas.isNotEmpty) {
        params.add('kelas=${Uri.encodeQueryComponent(kelas)}');
      }
      final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa$qs');
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map<String, dynamic>
            ? (decoded['data'] as List<dynamic>? ?? const [])
            : (decoded as List<dynamic>);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

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
            if (email.isNotEmpty) 'email': email,
            if (noHp.isNotEmpty) 'no_hp': noHp,
            'kelas': kelas,
            'prodi': prodi,
          }),
        )
        .timeout(_timeout);
    return res.statusCode == 201;
  }

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
          .put(uri, headers: _headers, body: jsonEncode(payload))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMahasiswa(String nim) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mahasiswa/$nim');
      final res =
          await _client.delete(uri, headers: _headers).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

final studentDataService = StudentDataService();
