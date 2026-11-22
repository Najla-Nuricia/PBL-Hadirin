import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/admin/admin_auth_repository.dart';
import 'package:mobile/data/admin/admin_jadwal_service.dart';
import 'package:mobile/data/admin/jadwal.dart';

void main() {
  Map<String, dynamic> jadwalJson() => {
    'id': 'jadwal-1',
    'tahun_ajaran_id': 'ta-1',
    'tahun_ajaran': '2026/2027',
    'semester': 'ganjil',
    'hari': 'senin',
    'sesi_mulai': 2,
    'sesi_selesai': 3,
    'jam_mulai': '07:50',
    'jam_selesai': '09:30',
    'mata_kuliah_kode': 'TI501',
    'matkul_nama': 'Pemrograman Web Lanjut',
    'sks': 3,
    'dosen_nip': '198501012010121001',
    'dosen_nama': 'Budi Santoso, S.T., M.T.',
    'program_studi_kode': 'D4-TI',
    'prodi_nama': 'D4 Teknik Informatika',
    'kelas_id': 'kelas-1',
    'kelas_nama': 'TI-3A',
    'kelas_tingkat': 3,
    'ruangan_kode': 'J301',
    'ruangan_nama': 'Ruang J301',
  };

  http.Response jsonResponse(Map<String, dynamic> body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'Content-Type': 'application/json'},
      );

  test(
    'listJadwal memanggil GET /admin/jadwal dengan filter dan Bearer token',
    () async {
      late Uri requestedUri;
      final service = AdminJadwalService(
        tokenProvider: () => 'jwt-admin',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          expect(request.method, 'GET');
          expect(request.headers['Authorization'], 'Bearer jwt-admin');
          return jsonResponse({
            'data': [jadwalJson()],
            'total': 1,
            'filters': {
              'tahun_ajaran': '2026/2027',
              'semester': 'ganjil',
              'tingkat': 3,
              'kelas': 'TI-3A',
            },
          });
        }),
      );

      final result = await service.listJadwal(
        tahunAjaran: '2026/2027',
        semester: SemesterPeriode.ganjil,
        tingkat: 3,
        kelas: 'TI-3A',
      );

      expect(requestedUri.path, '/admin/jadwal');
      expect(requestedUri.queryParameters, {
        'tahun_ajaran': '2026/2027',
        'semester': 'ganjil',
        'tingkat': '3',
        'kelas': 'TI-3A',
      });
      expect(result, hasLength(1));

      final jadwal = result.single;
      expect(jadwal.id, 'jadwal-1');
      expect(jadwal.tahunAjaran, '2026/2027');
      expect(jadwal.semester, SemesterPeriode.ganjil);
      expect(jadwal.mataKuliah.kode, 'TI501');
      expect(jadwal.mataKuliah.nama, 'Pemrograman Web Lanjut');
      expect(jadwal.mataKuliah.sks, 3);
      expect(jadwal.dosen.nama, 'Budi Santoso, S.T., M.T.');
      expect(jadwal.kelas.nama, 'TI-3A');
      expect(jadwal.kelas.tingkat, 3);
      expect(jadwal.ruangan.nama, 'Ruang J301');
      expect(jadwal.hari, HariKuliah.senin);
      expect(jadwal.rentangWaktu, '07:50 – 09:30');
    },
  );

  test('listJadwal tanpa token menolak permintaan', () async {
    final service = AdminJadwalService(
      tokenProvider: () => null,
      httpClient: MockClient((_) async {
        fail('Request tidak boleh dikirim tanpa token admin.');
      }),
    );

    expect(
      () => service.listJadwal(
        tahunAjaran: '2026/2027',
        semester: SemesterPeriode.ganjil,
        tingkat: 3,
        kelas: 'TI-3A',
      ),
      throwsA(
        isA<AdminRemoteApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });

  test('listJadwal meneruskan detail error backend', () async {
    final service = AdminJadwalService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((_) async {
        return jsonResponse({
          'detail': 'Sesi login berakhir. Silakan masuk ulang.',
          'code': 'unauthorized',
        }, 401);
      }),
    );

    expect(
      () => service.listJadwal(
        tahunAjaran: '2026/2027',
        semester: SemesterPeriode.ganjil,
        tingkat: 3,
        kelas: 'TI-3A',
      ),
      throwsA(
        isA<AdminRemoteApiException>().having(
          (e) => e.message,
          'message',
          'Sesi login berakhir. Silakan masuk ulang.',
        ),
      ),
    );
  });
}
