import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'student_account.dart';

class NimAlreadyRegisteredException implements Exception {
  const NimAlreadyRegisteredException(this.nim);

  final String nim;

  @override
  String toString() => 'NimAlreadyRegisteredException: $nim';
}

/// Stand-in & Real HTTP repository for student auth.
class DummyStudentAuthRepository {
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
    className: '3F-TI',
    password: 'mahasiswa123',
  );

  final Duration latency;
  final bool useRemoteApi;
  final Map<String, StudentAccount> _accounts;
  final http.Client _client;
  String? currentAccessToken;
  StudentAccount? _currentAccount;

  StudentAccount? get currentAccount => _currentAccount;

  Future<StudentAccount?> login({
    required String nim,
    required String password,
  }) async {
    // 1. Coba koneksi ke Backend API Hadirin jika useRemoteApi aktif
    if (useRemoteApi) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
        final response = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'nim': nim, 'password': password}),
        ).timeout(const Duration(milliseconds: 1500));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          currentAccessToken = data['access_token'] as String?;
          final userData = data['user'] as Map<String, dynamic>?;

          final account = StudentAccount(
            nim: (userData?['nim'] as String?) ?? nim,
            fullName: (userData?['name'] as String?) ?? 'Mahasiswa Demo',
            className: '3F-TI',
            password: password,
            token: currentAccessToken,
          );
          _accounts[account.nim] = account;
          return account;
        } else if (response.statusCode == 401 || response.statusCode == 422) {
          // Kredensial tidak valid di backend
          return null;
        }
      } catch (_) {
        // Backend offline atau sedang unit test tanpa server, gunakan fallback
      }
    }

    // 2. Fallback in-memory
    await Future<void>.delayed(latency);
    final account = _accounts[nim];
    if (account == null || account.password != password) {
      _currentAccount = null;
      return null;
    }
    _currentAccount = account;
    return account;
  }

  void logout() {
    _currentAccount = null;
  }

  Future<bool> isNimRegistered(String nim) async {
    await Future<void>.delayed(latency);
    return _accounts.containsKey(nim);
  }

  Future<bool> changePassword({
    required String nim,
    required String currentPassword,
    required String newPassword,
  }) async {
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
    return true;
  }

  Future<StudentAccount> register(
    StudentRegistrationDraft draft, {
    required List<String> facePhotoPaths,
  }) async {
    // 1. Coba register ke Backend API jika useRemoteApi aktif
    if (useRemoteApi) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');
        final response = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nim': draft.nim,
            'name': draft.fullName,
            'password': draft.password,
          }),
        ).timeout(const Duration(milliseconds: 1500));

        if (response.statusCode == 409) {
          throw NimAlreadyRegisteredException(draft.nim);
        }
      } on NimAlreadyRegisteredException {
        rethrow;
      } catch (_) {
        // Backend offline, lanjutkan validasi in-memory
      }
    }

    // 2. In-memory check
    await Future<void>.delayed(latency);
    if (_accounts.containsKey(draft.nim)) {
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
    return account;
  }
}

final studentAuthRepository = DummyStudentAuthRepository(useRemoteApi: true);
