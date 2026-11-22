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
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AdminRemoteApiException(
        'Sesi admin tidak ditemukan. Silakan masuk ulang.',
        statusCode: 401,
      );
    }

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

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AdminRemoteApiException(
          'Sesi login berakhir. Silakan masuk ulang.',
          statusCode: response.statusCode,
        );
      }

      throw AdminRemoteApiException(
        _extractDetail(response, 'Gagal memuat jadwal admin.'),
        statusCode: response.statusCode,
      );
    } on AdminRemoteApiException {
      rethrow;
    } catch (_) {
      throw AdminRemoteApiException(
        'Gagal terhubung ke server backend di ${ApiConfig.baseUrl}. '
        'Pastikan server backend sedang aktif.',
      );
    }
  }

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
