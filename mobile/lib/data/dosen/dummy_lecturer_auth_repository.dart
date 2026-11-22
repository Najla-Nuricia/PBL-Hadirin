import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'lecturer_account.dart';

class EmailAlreadyRegisteredException implements Exception {
  const EmailAlreadyRegisteredException(this.email);

  final String email;

  @override
  String toString() => 'EmailAlreadyRegisteredException: $email';
}

class WrongPasswordException implements Exception {
  const WrongPasswordException();

  @override
  String toString() => 'WrongPasswordException';
}

class LecturerRemoteApiException implements Exception {
  const LecturerRemoteApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Auth dosen: `POST /auth/dosen/login` bila `useRemoteApi` aktif,
/// dengan fallback akun demo untuk prototype/QA saat backend tidak tersedia.
class DummyLecturerAuthRepository extends ChangeNotifier {
  DummyLecturerAuthRepository({
    Iterable<LecturerAccount> seedAccounts = const [demoAccount],
    this.latency = const Duration(milliseconds: 600),
    http.Client? httpClient,
    this.useRemoteApi = false,
  }) : _accounts = {
          for (final account in seedAccounts) _key(account.email): account,
        },
        _client = httpClient ?? http.Client();

  static const demoAccount = LecturerAccount(
    staffId: '1985061520121003',
    fullName: 'Dr. Andi Pratama, S.T., M.Kom.',
    email: 'dosen@hadirin.id',
    password: 'dosen123',
    phoneNumber: '0812 3456 7890',
  );

  static const _requestTimeout = Duration(seconds: 8);

  final Duration latency;
  final bool useRemoteApi;
  final Map<String, LecturerAccount> _accounts;
  final http.Client _client;

  String? currentAccessToken;
  LecturerAccount? _currentAccount;

  LecturerAccount? get currentAccount => _currentAccount;

  bool get hasRemoteSession => useRemoteApi && currentAccessToken != null;

  static String _key(String email) => email.trim().toLowerCase();

  bool _isFlutterMockHttpResponse(http.Response response) =>
      response.statusCode == 400 && response.body.trim().isEmpty;

  String _extractDetail(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
      }
    } catch (_) {}
    return fallback;
  }

  Future<LecturerAccount?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _key(email);

    if (useRemoteApi) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/dosen/login');
        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': normalizedEmail, 'password': password}),
            )
            .timeout(_requestTimeout);

        if (!_isFlutterMockHttpResponse(response)) {
          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final token = (data['access_token'] as String?) ??
                (data['token'] as String?);
            final account = LecturerAccount(
              staffId: (data['staffId'] as String?) ??
                  (data['nip'] as String?) ??
                  '',
              fullName: (data['fullName'] as String?) ?? 'Dosen',
              email: (data['email'] as String?) ?? normalizedEmail,
              password: password,
              phoneNumber: (data['phoneNumber'] as String?) ?? '',
              role: (data['role'] as String?) ?? 'Dosen',
              token: token,
            );
            currentAccessToken = token;
            _accounts[normalizedEmail] = account;
            _currentAccount = account;
            notifyListeners();
            return account;
          }

          // Kredensial ditolak backend: coba akun demo agar QA offline tetap jalan.
          if (response.statusCode == 401 ||
              response.statusCode == 403 ||
              response.statusCode == 422) {
            currentAccessToken = null;
            _currentAccount = null;
          } else {
            throw LecturerRemoteApiException(
              _extractDetail(response, 'Login dosen gagal (${response.statusCode}).'),
              statusCode: response.statusCode,
            );
          }
        }
      } on LecturerRemoteApiException {
        rethrow;
      } catch (_) {
        // Backend tidak terjangkau → lanjut ke akun demo.
        currentAccessToken = null;
        _currentAccount = null;
      }
    }

    await Future<void>.delayed(latency);
    final account = _accounts[normalizedEmail];
    if (account == null || account.password != password) {
      currentAccessToken = null;
      _currentAccount = null;
      notifyListeners();
      return null;
    }
    _currentAccount = account;
    notifyListeners();
    return account;
  }

  void logout() {
    currentAccessToken = null;
    _currentAccount = null;
    notifyListeners();
  }

  Future<bool> isEmailRegistered(String email) async {
    await Future<void>.delayed(latency);
    return _accounts.containsKey(_key(email));
  }

  Future<LecturerAccount> register(LecturerRegistrationDraft draft) async {
    await Future<void>.delayed(latency);
    final key = _key(draft.email);
    if (_accounts.containsKey(key)) {
      throw EmailAlreadyRegisteredException(draft.email);
    }

    final account = LecturerAccount(
      staffId: draft.staffId,
      fullName: draft.fullName,
      email: draft.email.trim(),
      password: draft.password,
    );
    _accounts[key] = account;
    return account;
  }

  Future<LecturerAccount> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(latency);
    final key = _key(email);
    final account = _accounts[key];
    if (account == null || account.password != currentPassword) {
      throw const WrongPasswordException();
    }

    final updated = account.copyWith(password: newPassword);
    _accounts[key] = updated;
    return updated;
  }
}

final lecturerAuthRepository = DummyLecturerAuthRepository(useRemoteApi: true);
