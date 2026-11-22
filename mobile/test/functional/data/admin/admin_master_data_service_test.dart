import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/admin/admin_master_data_service.dart';
import 'package:mobile/data/admin/admin_auth_repository.dart';
import 'package:mobile/data/admin/tahun_ajaran.dart';

void main() {
  http.Response jsonResponse(Map<String, dynamic> body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'Content-Type': 'application/json'},
      );

  test('listTahunAjaran membaca data dari API dengan token admin', () async {
    final service = AdminMasterDataService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/admin/tahun-ajaran');
        expect(request.url.queryParameters['search'], '2026');
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return jsonResponse({
          'data': [
            {
              'id': 'year-1',
              'tahun': '2026/2027',
              'status': 'aktif',
              'semester_ganjil': true,
              'semester_genap': true,
              'tanggal_mulai': '2026-09-01',
              'tanggal_selesai': '2027-08-31',
            },
          ],
          'total': 1,
        });
      }),
    );

    final result = await service.listTahunAjaran(search: '2026');

    expect(result, hasLength(1));
    expect(result.single.id, 'year-1');
    expect(result.single.status, TahunAjaranStatus.aktif);
    expect(result.single.tanggalMulai, DateTime(2026, 9, 1));
  });

  test('create dan update mata kuliah mengirim payload backend', () async {
    var requestCount = 0;
    final service = AdminMasterDataService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['kode'], requestCount == 0 ? 'TI101' : 'TI102');
        expect(body['nama'], 'Basis Data');
        expect(body['semester'], 3);
        expect(body['sks'], 3);
        requestCount++;
        return jsonResponse({
          'message': 'ok',
          'data': {
            'kode': requestCount == 1 ? 'TI101' : 'TI102',
            'nama': 'Basis Data',
            'semester': 3,
            'sks': 3,
          },
        }, requestCount == 1 ? 201 : 200);
      }),
    );

    final created = await service.createMataKuliah(
      kode: 'TI101',
      nama: 'Basis Data',
      semester: 3,
      sks: 3,
    );
    final updated = await service.updateMataKuliah(
      originalKode: 'TI101',
      kode: 'TI102',
      nama: 'Basis Data',
      semester: 3,
      sks: 3,
    );

    expect(created.kode, 'TI101');
    expect(updated.kode, 'TI102');
  });

  test('delete meneruskan detail conflict dari backend', () async {
    final service = AdminMasterDataService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((_) async {
        return jsonResponse({
          'detail': 'Mata kuliah masih digunakan oleh jadwal.',
        }, 409);
      }),
    );

    expect(
      () => service.deleteMataKuliah('TI101'),
      throwsA(
        isA<AdminRemoteApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.message,
              'message',
              'Mata kuliah masih digunakan oleh jadwal.',
            ),
      ),
    );
  });

  test('request tanpa token ditolak sebelum menghubungi backend', () async {
    final service = AdminMasterDataService(
      tokenProvider: () => null,
      httpClient: MockClient((_) async {
        fail('Request tidak boleh dikirim tanpa token admin.');
      }),
    );

    expect(
      () => service.listMataKuliah(),
      throwsA(
        isA<AdminRemoteApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}
