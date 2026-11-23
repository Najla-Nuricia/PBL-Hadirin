import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'admin_auth_repository.dart';
import 'jadwal.dart';
import 'tahun_ajaran.dart';

/// Client API untuk CRUD master data admin.
///
/// Endpoint backend memakai satu sumber data untuk halaman admin dan modul
/// lain yang membaca tahun ajaran/mata kuliah.
class AdminMasterDataService {
  AdminMasterDataService({
    http.Client? httpClient,
    String? Function()? tokenProvider,
  }) : _client = httpClient ?? http.Client(),
       _tokenProvider =
           tokenProvider ?? (() => adminAuthRepository.currentAccessToken);

  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final String? Function() _tokenProvider;

  Future<List<TahunAjaran>> listTahunAjaran({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _send(
      () => _client.get(
        _uri('/admin/tahun-ajaran', query),
        headers: _authHeaders(),
      ),
    );
    final data = _listData(response);
    return data.map(_tahunFromJson).toList(growable: false);
  }

  Future<TahunAjaran> createTahunAjaran({
    required String tahun,
    required TahunAjaranStatus status,
    required bool semesterGanjil,
    required bool semesterGenap,
    required DateTime? tanggalMulai,
    required DateTime? tanggalSelesai,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/admin/tahun-ajaran'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'tahun': tahun.trim(),
          'status': _statusValue(status),
          'semester_ganjil': semesterGanjil,
          'semester_genap': semesterGenap,
          'tanggal_mulai': _dateValue(tanggalMulai),
          'tanggal_selesai': _dateValue(tanggalSelesai),
        }),
      ),
      expectedStatus: 201,
    );
    return _tahunFromJson(_objectData(response));
  }

  Future<TahunAjaran> updateTahunAjaran({
    required String id,
    required String tahun,
    required TahunAjaranStatus status,
    required bool semesterGanjil,
    required bool semesterGenap,
    required DateTime? tanggalMulai,
    required DateTime? tanggalSelesai,
  }) async {
    final response = await _send(
      () => _client.put(
        _uri('/admin/tahun-ajaran/${Uri.encodeComponent(id)}'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'tahun': tahun.trim(),
          'status': _statusValue(status),
          'semester_ganjil': semesterGanjil,
          'semester_genap': semesterGenap,
          'tanggal_mulai': _dateValue(tanggalMulai),
          'tanggal_selesai': _dateValue(tanggalSelesai),
        }),
      ),
    );
    return _tahunFromJson(_objectData(response));
  }

  Future<void> deleteTahunAjaran(String id) async {
    await _send(
      () => _client.delete(
        _uri('/admin/tahun-ajaran/${Uri.encodeComponent(id)}'),
        headers: _authHeaders(),
      ),
    );
  }

  Future<List<MataKuliah>> listMataKuliah({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _send(
      () => _client.get(
        _uri('/admin/mata-kuliah', query),
        headers: _authHeaders(),
      ),
    );
    final data = _listData(response);
    return data.map(_mataKuliahFromJson).toList(growable: false);
  }

  Future<MataKuliah> createMataKuliah({
    required String kode,
    required String nama,
    required int semester,
    required int sks,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/admin/mata-kuliah'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'kode': kode.trim(),
          'nama': nama.trim(),
          'semester': semester,
          'sks': sks,
        }),
      ),
      expectedStatus: 201,
    );
    return _mataKuliahFromJson(_objectData(response));
  }

  Future<MataKuliah> updateMataKuliah({
    required String originalKode,
    required String kode,
    required String nama,
    required int semester,
    required int sks,
  }) async {
    final response = await _send(
      () => _client.put(
        _uri('/admin/mata-kuliah/${Uri.encodeComponent(originalKode)}'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'kode': kode.trim(),
          'nama': nama.trim(),
          'semester': semester,
          'sks': sks,
        }),
      ),
    );
    return _mataKuliahFromJson(_objectData(response));
  }

  Future<void> deleteMataKuliah(String kode) async {
    await _send(
      () => _client.delete(
        _uri('/admin/mata-kuliah/${Uri.encodeComponent(kode)}'),
        headers: _authHeaders(),
      ),
    );
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  Map<String, String> _authHeaders() {
    final token = _requireToken();
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, String> _jsonHeaders() => {
    ..._authHeaders(),
    'Content-Type': 'application/json',
  };

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

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    int expectedStatus = 200,
  }) async {
    try {
      final response = await request().timeout(_timeout);
      if (response.statusCode == expectedStatus) return response;
      throw _errorFrom(response);
    } on AdminRemoteApiException {
      rethrow;
    } catch (_) {
      throw AdminRemoteApiException(
        'Gagal terhubung ke server backend di ${ApiConfig.baseUrl}. '
        'Pastikan server backend sedang aktif.',
      );
    }
  }

  AdminRemoteApiException _errorFrom(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return AdminRemoteApiException(
        'Sesi login berakhir. Silakan masuk ulang.',
        statusCode: response.statusCode,
      );
    }
    return AdminRemoteApiException(
      _extractDetail(response, 'Operasi master data gagal.'),
      statusCode: response.statusCode,
    );
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

  List<Map<String, dynamic>> _listData(http.Response response) {
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) {
      throw const AdminRemoteApiException(
        'Respons backend tidak berisi daftar master data.',
      );
    }
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Map<String, dynamic> _objectData(http.Response response) {
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const AdminRemoteApiException(
        'Respons backend tidak berisi data master.',
      );
    }
    return data;
  }

  TahunAjaran _tahunFromJson(Map<String, dynamic> json) {
    return TahunAjaran(
      id: _string(json['id']),
      tahun: _string(json['tahun']),
      status: _string(json['status']).toLowerCase() == 'aktif'
          ? TahunAjaranStatus.aktif
          : TahunAjaranStatus.nonAktif,
      semesterGanjil: json['semester_ganjil'] == true,
      semesterGenap: json['semester_genap'] == true,
      tanggalMulai: _date(json['tanggal_mulai']),
      tanggalSelesai: _date(json['tanggal_selesai']),
    );
  }

  MataKuliah _mataKuliahFromJson(Map<String, dynamic> json) {
    return MataKuliah(
      id: _string(json['kode']),
      kode: _string(json['kode']),
      nama: _string(json['nama']),
      semester: _integer(json['semester']),
      sks: _integer(json['sks']),
    );
  }

  static String _statusValue(TahunAjaranStatus status) =>
      status == TahunAjaranStatus.aktif ? 'aktif' : 'non_aktif';

  static String? _dateValue(DateTime? value) =>
      value?.toIso8601String().split('T').first;

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(_string(value)) ?? 0;
}

final adminMasterDataService = AdminMasterDataService();
