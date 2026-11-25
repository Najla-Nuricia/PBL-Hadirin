import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/admin/admin_auth_repository.dart';
import 'package:mobile/data/admin/admin_master_data_service.dart';
import 'package:mobile/data/admin/kelas.dart';

void main() {
  http.Response jsonResponse(Map<String, dynamic> body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'Content-Type': 'application/json'},
      );

  const ruanganJson = {
    'kode': 'J301',
    'nama': 'Ruang J301',
    'created_at': '2025-01-02T08:00:00+00:00',
    'updated_at': '2025-01-02T08:00:00+00:00',
  };

  const dosenJson = {
    'nip': '198501012010121001',
    'nama': 'Budi Santoso',
  };

  const kelasJson = {
    'id': '0b7a1c2d-3e4f-4a5b-8c6d-7e8f9a0b1c2d',
    'nama': 'TI-1A',
    'tingkat': 1,
    'program_studi_kode': 'D4-TI',
    'tahun_ajaran_id': '6c1f0b7e-1a2b-4c3d-9e8f-1234567890ab',
    'kapasitas': 30,
    'status': 'aktif',
    'program_studi_nama': 'Teknik Informatika',
    'tahun_ajaran_tahun': '2024/2025',
  };

  group('CRUD Ruangan via /admin/ruangan', () {
    test('list mengirim search, token, dan mem-parsing total', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/admin/ruangan');
          expect(request.url.queryParameters['search'], 'J301');
          expect(request.headers['Authorization'], 'Bearer jwt-admin');
          return jsonResponse({'data': [ruanganJson], 'total': 1});
        }),
      );

      final items = await service.listRuangan(search: ' J301 ');
      expect(items, hasLength(1));
      expect(items.single.kode, 'J301');
      expect(items.single.createdAt, isNotNull);
    });

    test('detail mengembalikan objek langsung tanpa wrapper data', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/admin/ruangan/J301');
          return jsonResponse(ruanganJson);
        }),
      );

      final item = await service.getRuangan('J301');
      expect(item.nama, 'Ruang J301');
    });

    test('create/post dan update/put tidak mengirim timestamp', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(
            body.keys.toSet(),
            {'kode', 'nama'},
          );
          expect(body.containsKey('created_at'), isFalse);
          expect(body.containsKey('updated_at'), isFalse);
          expect(request.headers['Content-Type'], 'application/json');
          if (request.method == 'POST') {
            expect(request.url.path, '/admin/ruangan');
            expect(body['kode'], 'J301');
            return jsonResponse({
              'message': 'Ruangan berhasil dibuat.',
              'data': ruanganJson,
            }, 201);
          }
          expect(request.method, 'PUT');
          expect(request.url.path, '/admin/ruangan/J301');
          expect(body['kode'], 'J302');
          expect(body['nama'], 'Ruang J301 (Lab Jaringan)');
          return jsonResponse({
            'message': 'Ruangan berhasil diperbarui.',
            'data': {...ruanganJson, 'kode': 'J302'},
          });
        }),
      );

      final created = await service.createRuangan(
        kode: 'J301',
        nama: 'Ruang J301',
      );
      final updated = await service.updateRuangan(
        kodeLama: 'J301',
        kode: 'J302',
        nama: 'Ruang J301 (Lab Jaringan)',
      );
      expect(created.kode, 'J301');
      expect(updated.kode, 'J302');
    });

    test('delete mengembalikan message backend', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/admin/ruangan/J301');
          return jsonResponse({'message': 'Ruangan berhasil dihapus.'});
        }),
      );

      expect(
        await service.deleteRuangan('J301'),
        'Ruangan berhasil dihapus.',
      );
    });
  });

  group('CRUD Dosen via /admin/dosen', () {
    test('list mem-parsing field null yang dihilangkan backend', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/admin/dosen');
          expect(request.url.queryParameters['search'], 'Budi');
          return jsonResponse({'data': [dosenJson], 'total': 1});
        }),
      );

      final items = await service.listDosen(search: 'Budi');
      expect(items.single.nip, '198501012010121001');
      expect(items.single.email, isNull);
      expect(items.single.noHp, isNull);
      expect(items.single.authUserId, isNull);
    });

    test('create menghilangkan email/no_hp kosong dan membaca initial_password',
        () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/admin/dosen');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {
            'nip': '198501012010121001',
            'nama': 'Budi Santoso',
          });
          expect(body.containsKey('email'), isFalse);
          expect(body.containsKey('no_hp'), isFalse);
          expect(body.containsKey('created_at'), isFalse);
          return jsonResponse({
            'message': 'Dosen berhasil dibuat.',
            'data': dosenJson,
            'initial_password': 'dosen123',
          }, 201);
        }),
      );

      final result = await service.createDosen(
        nip: '198501012010121001',
        nama: 'Budi Santoso',
        email: '   ',
        noHp: '',
      );
      expect(result.initialPassword, 'dosen123');
      expect(result.dosen.nama, 'Budi Santoso');
    });

    test('update mengirim nip di body dan response tanpa initial_password',
        () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/admin/dosen/198501012010121001');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['nip'], '198501012010121001');
          expect(body['email'], 'budi@polinema.ac.id');
          expect(body.containsKey('initial_password'), isFalse);
          return jsonResponse({
            'message': 'Dosen berhasil diperbarui.',
            'data': {...dosenJson, 'email': 'budi@polinema.ac.id'},
          });
        }),
      );

      final dosen = await service.updateDosen(
        nip: '198501012010121001',
        nama: 'Budi Santoso',
        email: ' budi@polinema.ac.id ',
      );
      expect(dosen.email, 'budi@polinema.ac.id');
    });

    test('delete meneruskan detail conflict backend', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((_) async => jsonResponse({
              'detail': 'Dosen masih digunakan oleh jadwal.',
              'code': 'CONFLICT',
            }, 409)),
      );

      expect(
        () => service.deleteDosen('198501012010121001'),
        throwsA(
          isA<AdminRemoteApiException>()
              .having((error) => error.statusCode, 'statusCode', 409)
              .having(
                (error) => error.message,
                'message',
                'Dosen masih digunakan oleh jadwal.',
              ),
        ),
      );
    });
  });

  group('CRUD Kelas via /admin/kelas', () {
    test('list mengirim semua filter opsional', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/admin/kelas');
          final query = request.url.queryParameters;
          expect(query['search'], 'TI-1A');
          expect(query['program_studi_kode'], 'D4-TI');
          expect(query['tahun_ajaran_id'], kelasJson['tahun_ajaran_id']);
          expect(query['status'], 'non_aktif');
          return jsonResponse({'data': [kelasJson], 'total': 1});
        }),
      );

      final items = await service.listKelasMaster(
        search: 'TI-1A',
        programStudiKode: 'D4-TI',
        tahunAjaranId: kelasJson['tahun_ajaran_id'] as String,
        status: KelasStatus.nonAktif,
      );
      expect(items.single.nama, 'TI-1A');
      expect(items.single.programStudiNama, 'Teknik Informatika');
    });

    test('create dan update mengirim payload sesuai kontrak backend', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {
            'nama': 'TI-1A',
            'tingkat': 1,
            'program_studi_kode': 'D4-TI',
            'tahun_ajaran_id': '6c1f0b7e-1a2b-4c3d-9e8f-1234567890ab',
            'kapasitas': 30,
            'status': 'aktif',
          });
          expect(body.containsKey('id'), isFalse);
          expect(body.containsKey('created_at'), isFalse);
          if (request.method == 'POST') {
            return jsonResponse({
              'message': 'Kelas berhasil dibuat.',
              'data': kelasJson,
            }, 201);
          }
          expect(request.method, 'PUT');
          expect(request.url.path, '/admin/kelas/${kelasJson['id']}');
          return jsonResponse({
            'message': 'Kelas berhasil diperbarui.',
            'data': kelasJson,
          });
        }),
      );

      final created = await service.createKelas(
        nama: 'TI-1A',
        tingkat: 1,
        programStudiKode: 'D4-TI',
        tahunAjaranId: '6c1f0b7e-1a2b-4c3d-9e8f-1234567890ab',
      );
      final updated = await service.updateKelas(
        id: kelasJson['id'] as String,
        nama: 'TI-1A',
        tingkat: 1,
        programStudiKode: 'D4-TI',
        tahunAjaranId: '6c1f0b7e-1a2b-4c3d-9e8f-1234567890ab',
      );
      expect(created.id, kelasJson['id']);
      expect(updated.id, kelasJson['id']);
    });

    test('delete meneruskan detail 404 ke UI', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((_) async => jsonResponse({
              'detail': 'Kelas tidak ditemukan.',
              'code': 'NOT_FOUND',
            }, 404)),
      );

      expect(
        () => service.deleteKelas('missing-id'),
        throwsA(
          isA<AdminRemoteApiException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having(
                (error) => error.message,
                'message',
                'Kelas tidak ditemukan.',
              ),
        ),
      );
    });
  });

  group('Penanganan error umum', () {
    test('detail 401/403 dan 422 ditampilkan, bukan pesan generik', () async {
      for (final status in [401, 403, 422, 502]) {
        final detail = 'Error spesifik $status dari backend.';
        final service = AdminMasterDataService(
          tokenProvider: () => 'jwt-admin',
          httpClient: MockClient(
            (_) async => jsonResponse({'detail': detail, 'code': 'ERR'}, status),
          ),
        );
        expect(
          () => service.listRuangan(),
          throwsA(
            isA<AdminRemoteApiException>()
                .having((error) => error.statusCode, 'statusCode', status)
                .having((error) => error.message, 'message', detail),
          ),
        );
      }
    });

    test('request tanpa token ditolak sebelum menghubungi backend', () async {
      final service = AdminMasterDataService(
        tokenProvider: () => null,
        httpClient: MockClient((_) async {
          fail('Request tidak boleh dikirim tanpa token admin.');
        }),
      );

      expect(
        () => service.listDosen(),
        throwsA(
          isA<AdminRemoteApiException>()
              .having((error) => error.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
