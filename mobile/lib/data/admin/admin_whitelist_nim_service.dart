import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'admin_auth_repository.dart';
import 'whitelist_nim.dart';

class AdminWhitelistNimService {
  AdminWhitelistNimService({
    http.Client? httpClient,
    String? Function()? tokenProvider,
  }) : _client = httpClient ?? http.Client(),
       _tokenProvider =
           tokenProvider ?? (() => adminAuthRepository.currentAccessToken);

  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final String? Function() _tokenProvider;

  Future<List<WhitelistNim>> list({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _send(
      () => _client.get(_uri('/admin/whitelist-nim', query), headers: _headers()),
    );
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) {
      throw const AdminRemoteApiException(
        'Respons backend tidak berisi daftar whitelist NIM.',
      );
    }
    return data.whereType<Map<String, dynamic>>().map(_fromJson).toList();
  }

  Future<WhitelistNim> create(String nim) async {
    final response = await _send(
      () => _client.post(
        _uri('/admin/whitelist-nim'),
        headers: _jsonHeaders(),
        body: jsonEncode({'nim': nim.trim()}),
      ),
      expectedStatus: 201,
    );
    return _fromResponse(response);
  }

  Future<WhitelistNim> update({
    required String oldNim,
    required String nim,
  }) async {
    final response = await _send(
      () => _client.put(
        _uri('/admin/whitelist-nim/${Uri.encodeComponent(oldNim)}'),
        headers: _jsonHeaders(),
        body: jsonEncode({'nim': nim.trim()}),
      ),
    );
    return _fromResponse(response);
  }

  Future<void> delete(String nim) async {
    await _send(
      () => _client.delete(
        _uri('/admin/whitelist-nim/${Uri.encodeComponent(nim)}'),
        headers: _headers(),
      ),
    );
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  Map<String, String> _headers() => {'Authorization': 'Bearer ${_token()}'};

  Map<String, String> _jsonHeaders() => {
    ..._headers(),
    'Content-Type': 'application/json',
  };

  String _token() {
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
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AdminRemoteApiException(
          'Sesi login berakhir. Silakan masuk ulang.',
          statusCode: response.statusCode,
        );
      }
      throw AdminRemoteApiException(
        _detail(response, 'Operasi whitelist NIM gagal.'),
        statusCode: response.statusCode,
      );
    } on AdminRemoteApiException {
      rethrow;
    } catch (_) {
      throw AdminRemoteApiException(
        'Gagal terhubung ke server backend di ${ApiConfig.baseUrl}.',
      );
    }
  }

  WhitelistNim _fromResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const AdminRemoteApiException(
        'Respons backend tidak berisi data whitelist NIM.',
      );
    }
    return _fromJson(data);
  }

  WhitelistNim _fromJson(Map<String, dynamic> json) => WhitelistNim(
    nim: '${json['nim'] ?? ''}',
    namaMahasiswa: '${json['nama_mahasiswa'] ?? '-'}',
    kelas: '${json['kelas'] ?? '-'}',
    status: '${json['status'] ?? 'Belum Registrasi'}',
  );

  String _detail(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return fallback;
  }
}

final adminWhitelistNimService = AdminWhitelistNimService();
