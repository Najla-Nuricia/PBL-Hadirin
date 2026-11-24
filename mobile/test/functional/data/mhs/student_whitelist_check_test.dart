import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';

void main() {
  const nim = '2341720099';

  DummyStudentAuthRepository repositoryWithCheck(Map<String, dynamic> body) =>
      DummyStudentAuthRepository(
        useRemoteApi: true,
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/auth/check-nim/$nim');
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'Content-Type': 'application/json'},
          );
        }),
      );

  test(
    'NIM yang belum di-whitelist tidak boleh melanjutkan registrasi',
    () async {
      final repository = repositoryWithCheck({
        'nim': nim,
        'whitelisted': false,
        'registered': false,
        'can_register': false,
        'status': 'belum_whitelist',
      });

      final result = await repository.checkNim(nim);

      expect(result.whitelisted, isFalse);
      expect(result.registered, isFalse);
      expect(result.canRegister, isFalse);
    },
  );

  test('NIM yang sudah terdaftar tidak boleh registrasi ulang', () async {
    final repository = repositoryWithCheck({
      'nim': nim,
      'whitelisted': true,
      'registered': true,
      'can_register': false,
      'status': 'sudah_terdaftar',
    });

    final result = await repository.checkNim(nim);

    expect(result.whitelisted, isTrue);
    expect(result.registered, isTrue);
    expect(result.canRegister, isFalse);
  });

  test('NIM yang di-whitelist dan belum terdaftar boleh registrasi', () async {
    final repository = repositoryWithCheck({
      'nim': nim,
      'whitelisted': true,
      'registered': false,
      'can_register': true,
      'status': 'siap_registrasi',
    });

    final result = await repository.checkNim(nim);

    expect(result.whitelisted, isTrue);
    expect(result.registered, isFalse);
    expect(result.canRegister, isTrue);
    expect(await repository.isNimAllowedToRegister(nim), isTrue);
  });
}
