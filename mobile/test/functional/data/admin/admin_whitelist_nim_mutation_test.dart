import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/admin/admin_auth_repository.dart';
import 'package:mobile/data/admin/admin_whitelist_nim_service.dart';

void main() {
  http.Response jsonResponse(Map<String, dynamic> body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'Content-Type': 'application/json'},
      );

  test('list mengirim search ke backend dan membaca hasil pencarian', () async {
    late Uri requestedUri;
    final service = AdminWhitelistNimService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((request) async {
        requestedUri = request.url;
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return jsonResponse({
          'data': [
            {
              'nim': '2341720001',
              'nama_mahasiswa': 'Mahasiswa Demo',
              'kelas': 'TI-3A',
              'status': 'Belum Registrasi',
            },
          ],
          'total': 1,
        });
      }),
    );

    final result = await service.list(search: '  234172  ');

    expect(requestedUri.path, '/admin/whitelist-nim');
    expect(requestedUri.queryParameters['search'], '234172');
    expect(result, hasLength(1));
    expect(result.single.namaMahasiswa, 'Mahasiswa Demo');
    expect(result.single.sudahRegistrasi, isFalse);
  });

  test('update mengirim PUT ke NIM lama dengan NIM baru', () async {
    late http.Request capturedRequest;
    final service = AdminWhitelistNimService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((request) async {
        capturedRequest = request;
        return jsonResponse({
          'message': 'Whitelist NIM berhasil diperbarui.',
          'data': {
            'nim': '2341720002',
            'nama_mahasiswa': '-',
            'kelas': '-',
            'status': 'Belum Registrasi',
          },
        });
      }),
    );

    final updated = await service.update(
      oldNim: '2341720001',
      nim: '  2341720002  ',
    );

    expect(capturedRequest.method, 'PUT');
    expect(capturedRequest.url.path, '/admin/whitelist-nim/2341720001');
    expect(jsonDecode(capturedRequest.body), {'nim': '2341720002'});
    expect(updated.nim, '2341720002');
    expect(updated.sudahRegistrasi, isFalse);
  });

  test('create meneruskan detail conflict dari backend', () async {
    final service = AdminWhitelistNimService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((_) async {
        return jsonResponse({
          'detail': "NIM '2341720001' sudah ada di whitelist.",
          'code': 'conflict',
        }, 409);
      }),
    );

    expect(
      () => service.create('2341720001'),
      throwsA(
        isA<AdminRemoteApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.message,
              'message',
              "NIM '2341720001' sudah ada di whitelist.",
            ),
      ),
    );
  });
}
