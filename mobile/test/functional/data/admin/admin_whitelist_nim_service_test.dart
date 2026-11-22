import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/admin/admin_whitelist_nim_service.dart';

void main() {
  http.Response response(Map<String, dynamic> body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'Content-Type': 'application/json'});

  test('list whitelist mengirim token admin dan membaca status registrasi', () async {
    final service = AdminWhitelistNimService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/admin/whitelist-nim');
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return response({
          'data': [
            {
              'nim': '2341720001',
              'nama_mahasiswa': 'Mahasiswa Demo',
              'kelas': 'TI-3A',
              'status': 'Sudah Registrasi',
            },
          ],
          'total': 1,
        });
      }),
    );

    final result = await service.list();

    expect(result.single.nim, '2341720001');
    expect(result.single.sudahRegistrasi, isTrue);
  });

  test('create dan delete whitelist memanggil endpoint yang benar', () async {
    var calls = 0;
    final service = AdminWhitelistNimService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((request) async {
        calls++;
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        if (request.method == 'POST') {
          expect(jsonDecode(request.body)['nim'], '2341720099');
          return response({
            'message': 'ok',
            'data': {
              'nim': '2341720099',
              'nama_mahasiswa': '-',
              'kelas': '-',
              'status': 'Belum Registrasi',
            },
          }, 201);
        }
        expect(request.method, 'DELETE');
        expect(request.url.path, '/admin/whitelist-nim/2341720099');
        return response({'message': 'ok'});
      }),
    );

    await service.create('2341720099');
    await service.delete('2341720099');
    expect(calls, 2);
  });
}
