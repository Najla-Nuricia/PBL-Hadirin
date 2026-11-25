import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/admin/admin_master_data_service.dart';
import 'package:mobile/data/admin/jadwal.dart';
import 'package:mobile/data/admin/kelas.dart';

void main() {
  group('Serialisasi model master data admin', () {
    test('Ruangan: fromJson menangani timestamp dan toJson tanpa timestamp', () {
      final ruangan = Ruangan.fromAdminApiJson({
        'kode': 'J301',
        'nama': 'Ruang J301',
        'created_at': '2025-01-02T08:00:00+00:00',
        'updated_at': '2025-01-03T08:00:00+00:00',
      });

      expect(ruangan.kode, 'J301');
      expect(ruangan.nama, 'Ruang J301');
      expect(ruangan.createdAt, DateTime.parse('2025-01-02T08:00:00Z'));
      expect(ruangan.updatedAt, DateTime.parse('2025-01-03T08:00:00Z'));
      expect(
        ruangan.toAdminApiJson(),
        {'kode': 'J301', 'nama': 'Ruang J301'},
      );
    });

    test('Dosen: field null yang dihilangkan backend tetap null-safe', () {
      // Backend memakai response_model_exclude_none=True.
      final dosen = Dosen.fromAdminApiJson({
        'nip': '198501012010121001',
        'nama': 'Budi Santoso',
      });

      expect(dosen.nip, '198501012010121001');
      expect(dosen.email, isNull);
      expect(dosen.noHp, isNull);
      expect(dosen.authUserId, isNull);
      expect(dosen.createdAt, isNull);

      final payload = dosen.toAdminApiJson();
      expect(payload, {'nip': dosen.nip, 'nama': dosen.nama});
      expect(payload.containsKey('email'), isFalse);
      expect(payload.containsKey('created_at'), isFalse);
      expect(payload.containsKey('updated_at'), isFalse);
    });

    test('Dosen: payload menyertakan opsional yang terisi saja', () {
      final dosen = Dosen.fromAdminApiJson({
        'nip': '198501012010121001',
        'nama': 'Budi Santoso',
        'email': 'budi@polinema.ac.id',
        'no_hp': '081234567890',
        'auth_user_id': '9f1c2d34-5e6f-4a7b-8c9d-0e1f2a3b4c5d',
      });

      expect(dosen.email, 'budi@polinema.ac.id');
      expect(dosen.noHp, '081234567890');
      expect(dosen.authUserId, isNotNull);
      expect(dosen.toAdminApiJson(), {
        'nip': '198501012010121001',
        'nama': 'Budi Santoso',
        'email': 'budi@polinema.ac.id',
        'no_hp': '081234567890',
      });

      final kosong = Dosen(
        nip: '1',
        nama: 'A',
        email: '  ',
        noHp: '',
      ).toAdminApiJson();
      expect(kosong.containsKey('email'), isFalse);
      expect(kosong.containsKey('no_hp'), isFalse);
    });

    test('Kelas: field turunan opsional dan nilai default null-safe', () {
      final kelas = Kelas.fromAdminApiJson({
        'id': '0b7a1c2d-3e4f-4a5b-8c6d-7e8f9a0b1c2d',
        'nama': 'TI-1A',
        'tingkat': 1,
        'program_studi_kode': 'D4-TI',
        'tahun_ajaran_id': '6c1f0b7e-1a2b-4c3d-9e8f-1234567890ab',
      });

      expect(kelas.kapasitas, 30);
      expect(kelas.status, KelasStatus.aktif);
      expect(kelas.programStudiNama, isNull);
      expect(kelas.tahunAjaranTahun, isNull);
      expect(kelas.programStudiLabel, 'D4-TI');
      expect(kelas.tahunAjaranLabel, kelas.tahunAjaranId);
      expect(kelas.toAdminApiJson(), {
        'nama': 'TI-1A',
        'tingkat': 1,
        'program_studi_kode': 'D4-TI',
        'tahun_ajaran_id': '6c1f0b7e-1a2b-4c3d-9e8f-1234567890ab',
        'kapasitas': 30,
        'status': 'aktif',
      });
    });

    test('Kelas: status non_aktif dan join fields ikut terparsing', () {
      final kelas = Kelas.fromAdminApiJson({
        'id': 'id-1',
        'nama': 'SIB-2C',
        'tingkat': 2,
        'program_studi_kode': 'D4-SIB',
        'tahun_ajaran_id': 'year-1',
        'kapasitas': 28,
        'status': 'non_aktif',
        'program_studi_nama': 'Sistem Informasi Bisnis',
        'tahun_ajaran_tahun': '2024/2025',
        'created_at': '2025-01-02T08:00:00+00:00',
      });

      expect(kelas.status, KelasStatus.nonAktif);
      expect(kelas.status.apiValue, 'non_aktif');
      expect(kelas.programStudiLabel, 'Sistem Informasi Bisnis');
      expect(kelas.tahunAjaranLabel, '2024/2025');
      expect(kelas.createdAt, isNotNull);
      expect(kelas.toAdminApiJson()['status'], 'non_aktif');
      expect(kelas.toAdminApiJson().containsKey('id'), isFalse);
    });

    test('DosenCreateResult membaca initial_password sekali saat create', () {
      final result = DosenCreateResult.fromAdminApiJson({
        'message': 'Dosen berhasil dibuat.',
        'data': {
          'nip': '198501012010121001',
          'nama': 'Budi Santoso',
          'email': null,
        },
        'initial_password': 'dosen123',
      });

      expect(result.initialPassword, 'dosen123');
      expect(result.dosen.nip, '198501012010121001');
      expect(result.dosen.email, isNull);

      final tanpaPassword = DosenCreateResult.fromAdminApiJson({
        'message': 'Dosen berhasil dibuat.',
        'data': {'nip': '1', 'nama': 'A'},
      });
      expect(tanpaPassword.initialPassword, isNull);
    });
  });
}
