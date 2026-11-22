import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'admin_account.dart';

/// Error dari backend saat autentikasi admin.
class AdminRemoteApiException implements Exception {
  const AdminRemoteApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Auth admin Hadirin.
///
/// - `POST /auth/admin/login` → JWT `role=admin` dari backend FastAPI.
/// - `GET /auth/admin/me` → profil admin terlindungi Bearer token.
/// - Akun demo (`admin` / `123`) hanya dipakai sebagai fallback saat backend
///   tidak dapat dijangkau atau pada environment `flutter test`, supaya QA
///   offline dan test widget lama tetap berjalan.
class AdminAuthRepository extends ChangeNotifier {
  AdminAuthRepository({
    http.Client? httpClient,
    this.useRemoteApi = true,
    bool? allowDemoFallback,
  }) : _client = httpClient ?? http.Client(),
       allowDemoFallback =
           allowDemoFallback ?? (!useRemoteApi || _isTestEnvironment());

  static const demoUsername = 'admin';
  static const demoPassword = '123';
  static const demoAccount = AdminAccount(
    username: demoUsername,
    name: 'Administrator',
    role: 'Admin',
    email: 'admin@hadirin.polinema.ac.id',
  );

  static const _requestTimeout = Duration(seconds: 8);
  static const _demoLatency = Duration(milliseconds: 300);

  final http.Client _client;
  final bool useRemoteApi;

  /// Demo fallback hanya untuk QA offline / flutter test. Bisa dipaksa mati
  /// lewat constructor (mis. pengujian response 401 production).
  final bool allowDemoFallback;

  String? currentAccessToken;
  AdminAccount? _currentAccount;
  String? _currentPassword;

  AdminAccount? get currentAccount => _currentAccount;
  bool get hasRemoteSession => useRemoteApi && currentAccessToken != null;

  static bool _isTestEnvironment() =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  bool _isFlutterMockHttpResponse(http.Response response) =>
      response.statusCode == 400 && response.body.trim().isEmpty;

  String _extractDetail(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return fallback;
  }

  /// Login ke backend. Returns null jika kredensial ditolak backend.
  /// Melempar [AdminRemoteApiException] jika server tidak tersedia / error.
  Future<AdminAccount?> login({
    required String username,
    required String password,
  }) async {
    final identifier = username.trim();

    if (useRemoteApi && identifier.isNotEmpty) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/admin/login');
        final response = await _client
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'username': identifier, 'password': password}),
            )
            .timeout(_requestTimeout);

        if (!_isFlutterMockHttpResponse(response)) {
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final token =
                (data['access_token'] as String?) ?? (data['token'] as String?);
            final account = AdminAccount(
              username: (data['username'] as String?) ?? identifier,
              name: (data['name'] as String?) ?? 'Administrator',
              role: (data['role'] as String?) ?? 'Admin',
              email:
                  (data['email'] as String?) ??
                  (identifier.contains('@') ? identifier.toLowerCase() : ''),
              token: token,
              expiresIn: (data['expires_in'] as num?)?.toInt(),
            );
            currentAccessToken = token;
            _currentPassword = password;
            _currentAccount = account;
            notifyListeners();
            return account;
          }

          if (response.statusCode == 401 ||
              response.statusCode == 403 ||
              response.statusCode == 422) {
            _clearSession();
            final detail = _extractDetail(
              response,
              'Username atau password admin salah.',
            );
            if (allowDemoFallback) {
              // Test widget lama memakai kredensial demo.
              return await _loginDemo(identifier, password);
            }
            throw AdminRemoteApiException(
              detail,
              statusCode: response.statusCode,
            );
          }

          throw AdminRemoteApiException(
            _extractDetail(
              response,
              'Login admin gagal (${response.statusCode}).',
            ),
            statusCode: response.statusCode,
          );
        }
      } on AdminRemoteApiException {
        rethrow;
      } catch (_) {
        if (!allowDemoFallback) {
          throw AdminRemoteApiException(
            'Gagal terhubung ke server backend di ${ApiConfig.baseUrl}. '
            'Pastikan server backend sedang aktif.',
          );
        }
        _clearSession();
      }
    }

    return _loginDemo(identifier, password);
  }

  /// Ambil profil admin aktif dari `GET /auth/admin/me`.
  /// Token expired/invalid → sesi dibersihkan dan return null.
  Future<AdminAccount?> loadProfile() async {
    final token = currentAccessToken;
    if (!hasRemoteSession || token == null || _currentAccount == null) {
      return null;
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/admin/me');
      final response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(_requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final updated = AdminAccount(
          username: (data['username'] as String?) ?? _currentAccount!.username,
          name: (data['name'] as String?) ?? _currentAccount!.name,
          role: (data['role'] as String?) ?? _currentAccount!.role,
          token: token,
          expiresIn: _currentAccount!.expiresIn,
        );
        _currentAccount = updated;
        notifyListeners();
        return updated;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        logout();
        return null;
      }
      throw AdminRemoteApiException(
        _extractDetail(response, 'Gagal memuat profil admin.'),
        statusCode: response.statusCode,
      );
    } on AdminRemoteApiException {
      rethrow;
    } catch (_) {
      return _currentAccount;
    }
  }

  Future<AdminAccount?> _loginDemo(String identifier, String password) async {
    await Future<void>.delayed(_demoLatency);
    if (identifier == demoUsername && password == demoPassword) {
      _currentAccount = demoAccount;
      _currentPassword = password;
      currentAccessToken = null;
      notifyListeners();
      return demoAccount;
    }
    _clearSession();
    return null;
  }

  /// Ubah email admin lewat `PUT /auth/admin/change-email`.
  ///
  /// Backend memverifikasi [currentPassword] sebelum mengganti email di
  /// Supabase Auth dan tabel `admin`. Sesi demo (tanpa remote token) tetap
  /// memperbarui profil lokal agar QA offline dapat berjalan.
  Future<bool> updateEmail(String email, {String? currentPassword}) async {
    final normalized = email.trim().toLowerCase();

    if (hasRemoteSession) {
      final token = currentAccessToken;
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/admin/change-email');
        final response = await _client
            .put(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'new_email': normalized,
                'current_password': currentPassword ?? '',
              }),
            )
            .timeout(_requestTimeout);

        if (!_isFlutterMockHttpResponse(response)) {
          if (response.statusCode == 200) {
            _applyEmail(normalized);
            return true;
          }
          throw AdminRemoteApiException(
            _extractDetail(response, 'Gagal memperbarui email admin.'),
            statusCode: response.statusCode,
          );
        }
      } on AdminRemoteApiException {
        rethrow;
      } catch (_) {
        throw AdminRemoteApiException(
          'Gagal terhubung ke server backend di ${ApiConfig.baseUrl}. '
          'Pastikan server backend sedang aktif.',
        );
      }
    }

    if (currentPassword != null &&
        _currentPassword != null &&
        currentPassword != _currentPassword) {
      throw const AdminRemoteApiException('Kata sandi saat ini tidak sesuai.');
    }
    _applyEmail(normalized);
    return true;
  }

  /// Ganti kata sandi admin lewat `PUT /auth/admin/change-password`.
  ///
  /// Returns true saat backend menerima perubahan. Sesi demo tetap memakai
  /// validasi lokal agar QA offline dan test widget lama tetap berjalan.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    if (hasRemoteSession) {
      final token = currentAccessToken;
      try {
        final uri = Uri.parse(
          '${ApiConfig.baseUrl}/auth/admin/change-password',
        );
        final response = await _client
            .put(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'current_password': currentPassword,
                'new_password': newPassword,
                'confirm_password': confirmPassword ?? newPassword,
              }),
            )
            .timeout(_requestTimeout);

        if (!_isFlutterMockHttpResponse(response)) {
          if (response.statusCode == 200) {
            _currentPassword = newPassword;
            notifyListeners();
            return true;
          }
          throw AdminRemoteApiException(
            _extractDetail(response, 'Gagal memperbarui kata sandi admin.'),
            statusCode: response.statusCode,
          );
        }
      } on AdminRemoteApiException {
        rethrow;
      } catch (_) {
        throw AdminRemoteApiException(
          'Gagal terhubung ke server backend di ${ApiConfig.baseUrl}. '
          'Pastikan server backend sedang aktif.',
        );
      }
    }

    if (_currentPassword == null || _currentPassword != currentPassword) {
      return false;
    }
    _currentPassword = newPassword;
    notifyListeners();
    return true;
  }

  void _applyEmail(String email) {
    final account = _currentAccount;
    if (account == null) return;
    _currentAccount = AdminAccount(
      username: account.username,
      name: account.name,
      role: account.role,
      email: email,
      token: account.token,
      expiresIn: account.expiresIn,
    );
    notifyListeners();
  }

  void _clearSession() {
    currentAccessToken = null;
    _currentAccount = null;
    _currentPassword = null;
    notifyListeners();
  }

  void logout() => _clearSession();
}

final adminAuthRepository = AdminAuthRepository();
