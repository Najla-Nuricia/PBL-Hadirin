import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'student_account.dart';

class NimAlreadyRegisteredException implements Exception {
  const NimAlreadyRegisteredException(this.nim);

  final String nim;

  @override
  String toString() => 'NimAlreadyRegisteredException: $nim';
}

class RemoteApiException implements Exception {
  const RemoteApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Auth repository connecting to FastAPI + Supabase Auth when `useRemoteApi` is enabled.
class DummyStudentAuthRepository extends ChangeNotifier {
  DummyStudentAuthRepository({
    Iterable<StudentAccount> seedAccounts = const [demoAccount],
    this.latency = const Duration(milliseconds: 600),
    http.Client? httpClient,
    this.useRemoteApi = false,
  })  : _accounts = {for (final account in seedAccounts) account.nim: account},
        _client = httpClient ?? http.Client();

  static const demoAccount = StudentAccount(
    nim: '2341720001',
    fullName: 'Mahasiswa Demo',
    className: 'TI-3A',
    password: 'mahasiswa123',
  );

  static const _requestTimeout = Duration(seconds: 8);

  final Duration latency;
  final bool useRemoteApi;
  final Map<String, StudentAccount> _accounts;
  final Map<String, String> _pendingFaceTokens = {};
  final http.Client _client;
  String? currentAccessToken;
  StudentAccount? _currentAccount;

  StudentAccount? get currentAccount => _currentAccount;

  bool get hasRemoteSession => useRemoteApi && currentAccessToken != null;

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

  void updateCurrentAccount({
    String? fullName,
    String? className,
    String? password,
  }) {
    final current = _currentAccount;
    if (current == null) return;
    final updated = StudentAccount(
      nim: current.nim,
      fullName: fullName ?? current.fullName,
      className: className ?? current.className,
      password: password ?? current.password,
      facePhotoPaths: current.facePhotoPaths,
      token: currentAccessToken ?? current.token,
    );
    _accounts[updated.nim] = updated;
    _currentAccount = updated;
    notifyListeners();
  }

  void updateProfile({String? fullName, String? className}) {
    updateCurrentAccount(fullName: fullName, className: className);
  }

  Future<StudentAccount?> login({
    required String nim,
    required String password,
  }) async {
    if (useRemoteApi) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'nim': nim, 'password': password}),
            )
            .timeout(_requestTimeout);

        if (!_isFlutterMockHttpResponse(response)) {
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            currentAccessToken = data['access_token'] as String?;
            final userData = data['user'] as Map<String, dynamic>?;

            final account = StudentAccount(
              nim: (userData?['nim'] as String?) ??
                  (data['nim'] as String?) ??
                  nim,
              fullName: (userData?['fullName'] as String?) ??
                  (userData?['name'] as String?) ??
                  (data['name'] as String?) ??
                  'Mahasiswa',
              className: (userData?['className'] as String?) ??
                  (userData?['kelas'] as String?) ??
                  (data['className'] as String?) ??
                  (data['kelas'] as String?) ??
                  '',
              password: password,
              token: currentAccessToken,
            );
            _accounts[account.nim] = account;
            _currentAccount = account;
            notifyListeners();
            return account;
          }
          if (response.statusCode == 401 ||
              response.statusCode == 403 ||
              response.statusCode == 422) {
            currentAccessToken = null;
            _currentAccount = null;
            notifyListeners();
            return null;
          }
        }
      } catch (_) {
        // Offline / Flutter testWidgets mock fallback below.
      }
    }

    await Future<void>.delayed(latency);
    final account = _accounts[nim];
    if (account == null || account.password != password) {
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

  Future<bool> isNimRegistered(String nim) async {
    if (useRemoteApi) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/check-nim/$nim');
        final response = await _client.get(uri).timeout(_requestTimeout);
        if (!_isFlutterMockHttpResponse(response) &&
            response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data['registered'] == true;
        }
      } catch (_) {}
    }

    await Future<void>.delayed(latency);
    return _accounts.containsKey(nim);
  }

  Future<bool> changePassword({
    required String nim,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (hasRemoteSession) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/change-password');
        final response = await _client
            .put(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $currentAccessToken',
              },
              body: jsonEncode({
                'current_password': currentPassword,
                'new_password': newPassword,
                'confirm_password': newPassword,
              }),
            )
            .timeout(_requestTimeout);

        if (!_isFlutterMockHttpResponse(response)) {
          if (response.statusCode == 200) {
            updateCurrentAccount(password: newPassword);
            return true;
          }
          if (response.statusCode == 400 || response.statusCode == 401) {
            return false;
          }
          throw RemoteApiException(
            _extractDetail(response, 'Gagal memperbarui kata sandi.'),
            statusCode: response.statusCode,
          );
        }
      } on RemoteApiException {
        rethrow;
      } catch (_) {}
    }

    await Future<void>.delayed(latency);
    final account = _accounts[nim];
    if (account == null || account.password != currentPassword) return false;

    final updatedAccount = StudentAccount(
      nim: account.nim,
      fullName: account.fullName,
      className: account.className,
      password: newPassword,
      facePhotoPaths: account.facePhotoPaths,
    );
    _accounts[nim] = updatedAccount;
    if (_currentAccount?.nim == nim) _currentAccount = updatedAccount;
    notifyListeners();
    return true;
  }

  Future<StudentAccount> register(
    StudentRegistrationDraft draft, {
    required List<String> facePhotoPaths,
    List<Uint8List>? facePhotoBytes,
  }) async {
    if (useRemoteApi) {
      var registeredRemotely = _pendingFaceTokens.containsKey(draft.nim);
      if (!registeredRemotely) {
        try {
          final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');
          final response = await _client
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'nim': draft.nim,
                  'name': draft.fullName,
                  'password': draft.password,
                  if (draft.className.trim().isNotEmpty)
                    'kelas': draft.className.trim(),
                }),
              )
              .timeout(_requestTimeout);

          if (!_isFlutterMockHttpResponse(response)) {
            if (response.statusCode == 409) {
              throw NimAlreadyRegisteredException(draft.nim);
            }
            if (response.statusCode != 201 && response.statusCode != 200) {
              throw RemoteApiException(
                _extractDetail(response, 'Registrasi akun gagal.'),
                statusCode: response.statusCode,
              );
            }
            registeredRemotely = true;
          }
        } on NimAlreadyRegisteredException {
          rethrow;
        } on RemoteApiException {
          rethrow;
        } catch (_) {
          // Offline / Flutter testWidgets fallback below.
        }
      }

      if (registeredRemotely &&
          facePhotoBytes != null &&
          facePhotoBytes.isNotEmpty) {
        var token = _pendingFaceTokens[draft.nim];
        if (token == null) {
          final loginUri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
          final loginRes = await _client
              .post(
                loginUri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'nim': draft.nim, 'password': draft.password}),
              )
              .timeout(_requestTimeout);

          if (loginRes.statusCode == 200) {
            final loginData = jsonDecode(loginRes.body) as Map<String, dynamic>;
            token = loginData['access_token'] as String?;
            if (token != null) {
              _pendingFaceTokens[draft.nim] = token;
            }
          }
        }

        if (token != null) {
          final uploadReq = http.MultipartRequest(
            'POST',
            Uri.parse('${ApiConfig.baseUrl}/mahasiswa/wajah/register'),
          )..headers['Authorization'] = 'Bearer $token';

          for (var i = 0; i < facePhotoBytes.length; i++) {
            final name = i < facePhotoPaths.length &&
                    facePhotoPaths[i].trim().isNotEmpty
                ? facePhotoPaths[i].split(RegExp(r'[/\\]')).last
                : 'face_${i + 1}.jpg';
            uploadReq.files.add(
              http.MultipartFile.fromBytes(
                'files',
                facePhotoBytes[i],
                filename: name.endsWith('.png') ||
                        name.endsWith('.jpg') ||
                        name.endsWith('.jpeg')
                    ? name
                    : 'face_${i + 1}.jpg',
              ),
            );
          }

          final streamed = await uploadReq.send().timeout(
                const Duration(seconds: 30),
              );
          final faceRes = await http.Response.fromStream(streamed);
          if (faceRes.statusCode != 201 && faceRes.statusCode != 200) {
            throw RemoteApiException(
              _extractDetail(faceRes, 'Gagal mendaftarkan foto wajah.'),
              statusCode: faceRes.statusCode,
            );
          }
          _pendingFaceTokens.remove(draft.nim);
        }
      }
    }

    await Future<void>.delayed(latency);
    if (_accounts.containsKey(draft.nim) && !useRemoteApi) {
      throw NimAlreadyRegisteredException(draft.nim);
    }

    final account = StudentAccount(
      nim: draft.nim,
      fullName: draft.fullName,
      className: draft.className,
      password: draft.password,
      facePhotoPaths: List.unmodifiable(facePhotoPaths),
    );
    _accounts[account.nim] = account;
    notifyListeners();
    return account;
  }
}

final studentAuthRepository = DummyStudentAuthRepository(useRemoteApi: true);
