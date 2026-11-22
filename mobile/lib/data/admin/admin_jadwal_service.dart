import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'admin_auth_repository.dart';
import 'jadwal.dart';

/// Service jadwal admin dari backend FastAPI.
///
/// `GET /admin/jadwal` membutuhkan Bearer token admin dan mendukung filter
/// tahun ajaran, semester, tingkat, serta kelas.
class AdminJadwalService {
  AdminJadwalService({
    http.Client? httpClient,
    String? Function()? tokenProvider,
  }) : _client = httpClient ?? http.Client(),
       _tokenProvider =
           tokenProvider ?? (() => adminAuthRepository.currentAccessToken);

  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final String? Function() _tokenProvider;

  Future<List<JadwalKuliah>> listJadwal({
    required String tahunAjaran,
    required SemesterPeriode semester,
    required int tingkat,
    required String kelas,
  }) async {
    final token = _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/jadwal').replace(
      queryParameters: {
        'tahun_ajaran': tahunAjaran,
        'semester': semester.name,
        'tingkat': '$tingkat',
        'kelas': kelas,
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return (decoded['data'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(JadwalKuliah.fromAdminApiJson)
            .toList(growable: false);
      }

      throw _errorFrom(response, 'Gagal memuat jadwal admin.');
    } on AdminRemoteApiException {
      rethrow;
    } catch (_) {
      throw _connectionError();
    }
  }

  Future<JadwalKuliah> createJadwal({
    required String tahunAjaran,
    required String kelas,
    required String mataKuliahKode,
    required String dosenNip,
    required String ruanganKode,
    required HariKuliah hari,
    required int sesiMulai,
    required int sesiSelesai,
    required SemesterPeriode semester,
  }) async {
    final token = _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/jadwal');

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'tahun_ajaran': tahunAjaran,
              'kelas': kelas,
              'mata_kuliah_kode': mataKuliahKode,
              'dosen_nip': dosenNip,
              'ruangan_kode': ruanganKode,
              'hari': hari.name,
              'sesi_mulai': sesiMulai,
              'sesi_selesai': sesiSelesai,
              'semester': semester.name,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          return JadwalKuliah.fromAdminApiJson(data);
        }
        throw const AdminRemoteApiException(
          'Respons backend tidak berisi data jadwal.',
        );
      }

      throw _errorFrom(response, 'Gagal menyimpan jadwal admin.');
    } on AdminRemoteApiException {
      rethrow;
    } catch (_) {
      throw _connectionError();
    }
  }

  String _requireToken() {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AdminRemoteApiException(
        'Sesi admin tidak ditemukan. Silakan masuk ulang.',
        statusCode: 401,
      );
    }
    return token;
  }

  AdminRemoteApiException _errorFrom(http.Response response, String fallback) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return AdminRemoteApiException(
        'Sesi login berakhir. Silakan masuk ulang.',
        statusCode: response.statusCode,
      );
    }
    return AdminRemoteApiException(
      _extractDetail(response, fallback),
      statusCode: response.statusCode,
    );
  }

  AdminRemoteApiException _connectionError() => AdminRemoteApiException(
    'Gagal terhubung ke server backend di ${ApiConfig.baseUrl}. '
    'Pastikan server backend sedang aktif.',
  );

  String _extractDetail(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return fallback;
  }
}

final adminJadwalService = AdminJadwalService();
