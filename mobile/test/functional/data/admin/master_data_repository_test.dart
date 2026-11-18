import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/admin/dosen.dart';
import 'package:mobile/data/admin/jadwal.dart';
import 'package:mobile/data/admin/kelas.dart';
import 'package:mobile/data/admin/ruangan.dart';

void main() {
  group('KelasRepository CRUD', () {
    late KelasRepository repo;

    setUp(() => repo = KelasRepository(seedData: []));

    test('create menambahkan data baru', () {
      repo.add(
        const Kelas(
          id: 'k1',
          tahunAjaran: '2026/2027',
          programStudi: 'D4 Teknik Informatika',
          nama: 'TI-3A',
          kapasitas: 30,
          status: KelasStatus.aktif,
        ),
      );

      expect(repo.getAll(), hasLength(1));
      expect(repo.findById('k1')?.nama, 'TI-3A');
      expect(repo.getAll().first.id, 'k1');
    });

    test('read/serch mencari berdasarkan nama, prodi, tahun ajaran', () {
      repo.add(
        const Kelas(
          id: 'k1',
          tahunAjaran: '2026/2027',
          programStudi: 'D4 Teknik Informatika',
          nama: 'TI-3A',
          kapasitas: 30,
          status: KelasStatus.aktif,
        ),
      );
      repo.add(
        const Kelas(
          id: 'k2',
          tahunAjaran: '2025/2026',
          programStudi: 'D4 Sistem Informasi Bisnis',
          nama: 'SIB-2C',
          kapasitas: 28,
          status: KelasStatus.nonAktif,
        ),
      );

      expect(repo.search('ti-3a').single.id, 'k1');
      expect(repo.search('sistem informasi').single.id, 'k2');
      expect(repo.search('2025/2026').single.id, 'k2');
      expect(repo.search(''), hasLength(2));
      expect(repo.findById('tidak-ada'), isNull);
    });

    test('update mengubah data dan false bila id tidak ada', () {
      const awal = Kelas(
        id: 'k1',
        tahunAjaran: '2026/2027',
        programStudi: 'D4 Teknik Informatika',
        nama: 'TI-3A',
        kapasitas: 30,
        status: KelasStatus.aktif,
      );
      repo.add(awal);

      final ok = repo.update(awal.copyWith(nama: 'TI-3B', kapasitas: 40));
      expect(ok, isTrue);
      expect(repo.findById('k1')?.nama, 'TI-3B');
      expect(repo.findById('k1')?.kapasitas, 40);

      expect(repo.update(awal.copyWith(nama: 'TI-9Z')), isTrue);

      final missing = KelasRepository(seedData: []);
      expect(missing.update(awal), isFalse);
    });

    test('remove menghapus data dan false bila id tidak ada', () {
      const awal = Kelas(
        id: 'k1',
        tahunAjaran: '2026/2027',
        programStudi: 'D4 Teknik Informatika',
        nama: 'TI-3A',
        kapasitas: 30,
        status: KelasStatus.aktif,
      );
      repo.add(awal);

      expect(repo.remove('k1'), isTrue);
      expect(repo.getAll(), isEmpty);
      expect(repo.remove('k1'), isFalse);
    });

    test('exists mendeteksi duplikat dan menghormati excludeId', () {
      repo.add(
        const Kelas(
          id: 'k1',
          tahunAjaran: '2026/2027',
          programStudi: 'D4 Teknik Informatika',
          nama: 'TI-3A',
          kapasitas: 30,
          status: KelasStatus.aktif,
        ),
      );

      expect(repo.exists(tahunAjaran: '2026/2027', nama: 'ti-3a'), isTrue);
      expect(
        repo.exists(tahunAjaran: '2026/2027', nama: 'TI-3A', excludeId: 'k1'),
        isFalse,
      );
      expect(repo.exists(tahunAjaran: '2025/2026', nama: 'TI-3A'), isFalse);
    });

    test('notifyListeners dipanggil pada setiap perubahan', () {
      var notified = 0;
      repo.addListener(() => notified++);

      repo.add(
        const Kelas(
          id: 'k1',
          tahunAjaran: '2026/2027',
          programStudi: 'D4 Teknik Informatika',
          nama: 'TI-3A',
          kapasitas: 30,
          status: KelasStatus.aktif,
        ),
      );
      repo.update(
        const Kelas(
          id: 'k1',
          tahunAjaran: '2026/2027',
          programStudi: 'D4 Teknik Informatika',
          nama: 'TI-3B',
          kapasitas: 30,
          status: KelasStatus.aktif,
        ),
      );
      repo.remove('k1');

      expect(notified, 3);
    });
  });

  group('RuanganRepository CRUD', () {
    late RuanganRepository repo;

    setUp(() => repo = RuanganRepository(seedData: []));

    test('create + read', () {
      repo.add(const Ruangan(kode: 'LPR1', nama: 'Lab Pemrograman 1'));

      expect(repo.getAll(), hasLength(1));
      expect(repo.findByKode('LPR1')?.nama, 'Lab Pemrograman 1');
      expect(repo.findByKode('XXX'), isNull);
    });

    test('search berdasarkan kode dan nama', () {
      repo.add(const Ruangan(kode: 'LPR1', nama: 'Lab Pemrograman 1'));
      repo.add(const Ruangan(kode: 'J301', nama: 'Ruang Kuliah 301'));

      expect(repo.search('lpr').single.kode, 'LPR1');
      expect(repo.search('kuliah').single.kode, 'J301');
      expect(repo.search('  '), hasLength(2));
    });

    test('update berdasarkan kode lama', () {
      repo.add(const Ruangan(kode: 'LPR1', nama: 'Lab Pemrograman 1'));

      final ok = repo.update(
        'LPR1',
        const Ruangan(kode: 'LPR2', nama: 'Lab Pemrograman 2', kapasitas: 40),
      );

      expect(ok, isTrue);
      expect(repo.findByKode('LPR1'), isNull);
      expect(repo.findByKode('LPR2')?.kapasitas, 40);
      expect(
        repo.update('TIDAK-ADA', const Ruangan(kode: 'X', nama: 'X')),
        isFalse,
      );
    });

    test('remove berdasarkan kode', () {
      repo.add(const Ruangan(kode: 'LPR1', nama: 'Lab Pemrograman 1'));

      expect(repo.remove('LPR1'), isTrue);
      expect(repo.getAll(), isEmpty);
      expect(repo.remove('LPR1'), isFalse);
    });

    test('exists mendeteksi kode duplikat', () {
      repo.add(const Ruangan(kode: 'LPR1', nama: 'Lab Pemrograman 1'));

      expect(repo.exists('LPR1'), isTrue);
      expect(repo.exists('lpr1'), isFalse); // kode bersifat case-sensitive
      expect(repo.exists('J301'), isFalse);
    });
  });

  group('DosenRepository CRUD', () {
    late DosenRepository repo;

    setUp(() => repo = DosenRepository(seedData: []));

    test('create + read', () {
      repo.add(const Dosen(nip: '198001', nama: 'Dr. Ani'));

      expect(repo.getAll(), hasLength(1));
      expect(repo.findByNip('198001')?.nama, 'Dr. Ani');
      expect(repo.findByNip('000000'), isNull);
    });

    test('search berdasarkan nip, nama, dan program studi', () {
      repo.add(
        const Dosen(
          nip: '198001',
          nama: 'Dr. Ani',
          programStudi: 'D4 Teknik Informatika',
        ),
      );
      repo.add(
        const Dosen(
          nip: '198002',
          nama: 'Budi, M.Kom',
          programStudi: 'D4 Sistem Informasi Bisnis',
        ),
      );

      expect(repo.search('198001').single.nama, 'Dr. Ani');
      expect(repo.search('budi').single.nip, '198002');
      expect(repo.search('teknik informatika').single.nip, '198001');
      expect(repo.search(''), hasLength(2));
    });

    test('update berdasarkan nip lama', () {
      final awal = const Dosen(nip: '198001', nama: 'Dr. Ani');
      repo.add(awal);

      final ok = repo.update(
        '198001',
        awal.copyWith(nama: 'Dr. Ani Suryani', status: DosenStatus.nonAktif),
      );

      expect(ok, isTrue);
      expect(repo.findByNip('198001')?.nama, 'Dr. Ani Suryani');
      expect(repo.findByNip('198001')?.status, DosenStatus.nonAktif);
      expect(repo.update('000000', awal), isFalse);
    });

    test('remove berdasarkan nip', () {
      repo.add(const Dosen(nip: '198001', nama: 'Dr. Ani'));

      expect(repo.remove('198001'), isTrue);
      expect(repo.getAll(), isEmpty);
      expect(repo.remove('198001'), isFalse);
    });

    test('exists mendeteksi nip duplikat dan menghormati excludeNip', () {
      repo.add(const Dosen(nip: '198001', nama: 'Dr. Ani'));

      expect(repo.exists('198001'), isTrue);
      expect(repo.exists('198001', excludeNip: '198001'), isFalse);
      expect(repo.exists('198002'), isFalse);
    });

    test('status dosen memiliki label yang benar', () {
      expect(DosenStatus.aktif.label, 'Aktif');
      expect(DosenStatus.nonAktif.label, 'Non-Aktif');
      expect(KelasStatus.aktif.label, 'Aktif');
      expect(KelasStatus.nonAktif.label, 'Non-Aktif');
    });
  });
}
