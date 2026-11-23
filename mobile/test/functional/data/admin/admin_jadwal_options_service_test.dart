import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/admin/admin_jadwal_options_service.dart';
import 'package:mobile/data/admin/admin_master_data_service.dart';

void main() {
  http.Response jsonResponse(Map<String, dynamic> body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'Content-Type': 'application/json'},
  );

  test('load mengambil seluruh pilihan form dari endpoint backend', () async {
    final paths = <String>[];
    final masterData = AdminMasterDataService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return switch (request.url.path) {
          '/admin/tahun-ajaran' => jsonResponse({
            'data': [
              {
                'id': 'ta-1',
                'tahun': '2026/2027',
                'status': 'aktif',
                'semester_ganjil': true,
                'semester_genap': true,
              },
            ],
            'total': 1,
          }),
          '/admin/mata-kuliah' => jsonResponse({
            'data': [
              {
                'kode': 'TI201',
                'nama': 'Struktur Data',
                'semester': 3,
                'sks': 3,
              },
            ],
            'total': 1,
          }),
          '/admin/dosen' => jsonResponse({
            'data': [
              {
                'nip': '199002202015041003',
                'nama': 'Rizky Pratama',
                'email': 'rizky@polinema.ac.id',
              },
            ],
            'total': 1,
          }),
          '/admin/program-studi' => jsonResponse({
            'data': [
              {'kode': 'D4-TI', 'nama': 'D4 Teknik Informatika'},
            ],
            'total': 1,
          }),
          '/admin/ruangan' => jsonResponse({
            'data': [
              {'kode': 'J302', 'nama': 'Ruang J302'},
            ],
            'total': 1,
          }),
          '/admin/sesi-kuliah' => jsonResponse({
            'data': [
              {'nomor': 2, 'jam_mulai': '07:50', 'jam_selesai': '08:40'},
              {'nomor': 1, 'jam_mulai': '07:00', 'jam_selesai': '07:50'},
            ],
            'total': 2,
          }),
          _ => fail('Endpoint tak terduga: ${request.url.path}'),
        };
      }),
    );
    final service = AdminJadwalOptionsService(masterData: masterData);

    final options = await service.load();

    expect(
      paths,
      containsAll([
        '/admin/tahun-ajaran',
        '/admin/mata-kuliah',
        '/admin/dosen',
        '/admin/program-studi',
        '/admin/ruangan',
        '/admin/sesi-kuliah',
      ]),
    );
    expect(options.tahunAjaran.single.tahun, '2026/2027');
    expect(options.mataKuliah.single.kode, 'TI201');
    expect(options.dosen.single.nip, '199002202015041003');
    expect(options.programStudi.single.kode, 'D4-TI');
    expect(options.ruangan.single.kode, 'J302');
    expect(options.sesi.map((item) => item.nomor), [1, 2]);
    expect(options.sesi.first.jamMulai, '07:00');
    expect(options.kelas, isEmpty);
  });

  test('loadKelas memfilter kelas berdasarkan tahun ajaran', () async {
    late Uri requestedUri;
    final masterData = AdminMasterDataService(
      tokenProvider: () => 'jwt-admin',
      httpClient: MockClient((request) async {
        requestedUri = request.url;
        return jsonResponse({
          'data': [
            {
              'id': 'kelas-1',
              'nama': 'TI-3A',
              'tingkat': 3,
              'program_studi_kode': 'D4-TI',
              'tahun_ajaran_id': 'ta-1',
            },
          ],
          'total': 1,
        });
      }),
    );
    final service = AdminJadwalOptionsService(masterData: masterData);

    final kelas = await service.loadKelas('2026/2027');

    expect(requestedUri.path, '/kelas');
    expect(requestedUri.queryParameters['tahun_ajaran'], '2026/2027');
    expect(kelas.single.nama, 'TI-3A');
    expect(kelas.single.tingkat, 3);
    expect(kelas.single.programStudiKode, 'D4-TI');
  });
}
