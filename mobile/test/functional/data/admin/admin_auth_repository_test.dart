import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/admin/admin_auth_repository.dart';

void main() {
  http.Response jsonResponse(Map<String, dynamic> body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'Content-Type': 'application/json'},
      );

  test('login admin sukses menyimpan JWT dan profil dari backend', () async {
    final repository = AdminAuthRepository(
      allowDemoFallback: false,
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/admin/login');
        expect(jsonDecode(request.body), {
          'username': 'adminhadirin',
          'password': 'admin123',
        });
        return jsonResponse({
          'username': 'adminhadirin',
          'name': 'Administrator',
          'role': 'Admin',
          'token': 'jwt-admin',
          'access_token': 'jwt-admin',
          'expires_in': 86400,
        });
      }),
    );

    final account = await repository.login(
      username: 'adminhadirin',
      password: 'admin123',
    );

    expect(account?.username, 'adminhadirin');
    expect(account?.role, 'Admin');
    expect(account?.expiresIn, 86400);
    expect(repository.currentAccessToken, 'jwt-admin');
    expect(repository.hasRemoteSession, isTrue);
    expect(repository.currentAccount?.isAdmin, isTrue);
  });

  test('kredensial ditolak backend melempar error tanpa fallback', () async {
    final repository = AdminAuthRepository(
      allowDemoFallback: false,
      httpClient: MockClient((_) async {
        return jsonResponse(
          {'detail': 'Username atau password admin salah.', 'code': 'unauthorized'},
          401,
        );
      }),
    );

    expect(
      () => repository.login(username: 'salah', password: 'salah'),
      throwsA(
        isA<AdminRemoteApiException>().having(
          (e) => e.message,
          'message',
          'Username atau password admin salah.',
        ),
      ),
    );
    expect(repository.currentAccessToken, isNull);
  });

  test('loadProfile memakai Bearer token dan membersihkan sesi saat 401', () async {
    final requests = <Uri>[];
    final repository = AdminAuthRepository(
      allowDemoFallback: false,
      httpClient: MockClient((request) async {
        requests.add(request.url);
        if (request.url.path == '/auth/admin/login') {
          return jsonResponse({
            'username': 'adminhadirin',
            'role': 'Admin',
            'access_token': 'jwt-admin',
          });
        }
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return jsonResponse({'detail': 'Token expired'}, 401);
      }),
    );

    await repository.login(username: 'adminhadirin', password: 'admin123');
    final profile = await repository.loadProfile();

    expect(profile, isNull);
    expect(repository.hasRemoteSession, isFalse);
    expect(requests.last.path, '/auth/admin/me');
  });

  test('email dan kata sandi admin dapat diperbarui pada sesi', () async {
    final repository = AdminAuthRepository(
      httpClient: MockClient((_) async => http.Response('', 400)),
    );
    await repository.login(username: 'admin', password: '123');

    repository.updateEmail('admin.baru@hadirin.polinema.ac.id');
    expect(
      repository.currentAccount?.email,
      'admin.baru@hadirin.polinema.ac.id',
    );

    expect(
      repository.changePassword(
        currentPassword: 'salah',
        newPassword: 'rahasia123',
      ),
      isFalse,
    );
    expect(
      repository.changePassword(
        currentPassword: '123',
        newPassword: 'rahasia123',
      ),
      isTrue,
    );
    expect(
      repository.changePassword(
        currentPassword: '123',
        newPassword: 'rahasia456',
      ),
      isFalse,
    );
  });

  test('fallback demo tetap tersedia untuk QA offline', () async {
    final repository = AdminAuthRepository(
      allowDemoFallback: true,
      httpClient: MockClient((_) async => http.Response('', 400)),
    );

    final account = await repository.login(
      username: 'admin',
      password: '123',
    );
    expect(account?.username, 'admin');
    expect(repository.hasRemoteSession, isFalse);
  });
}
