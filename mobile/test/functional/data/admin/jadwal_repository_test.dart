import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/admin/jadwal.dart';

void main() {
  MataKuliah mataKuliah(String kode) =>
      JadwalMasterData.mataKuliah.firstWhere((item) => item.kode == kode);
  KelasKuliah kelas(String nama) =>
      JadwalMasterData.kelas.firstWhere((item) => item.nama == nama);
  Ruangan ruangan(String kode) =>
      JadwalMasterData.ruangan.firstWhere((item) => item.kode == kode);
  SesiKuliah sesi(int nomor) => JadwalMasterData.sesi[nomor - 1];
  final budi = JadwalMasterData.dosen[0];
  final deasy = JadwalMasterData.dosen[1];

  JadwalKuliah jadwal({
    String id = 'baru',
    String kodeMataKuliah = 'TI101',
    Dosen? dosen,
    String namaKelas = 'TI-1A',
    String kodeRuangan = 'J301',
    HariKuliah hari = HariKuliah.senin,
    int mulai = 1,
    int selesai = 2,
  }) {
    return JadwalKuliah(
      id: id,
      tahunAjaran: '2026/2027',
      mataKuliah: mataKuliah(kodeMataKuliah),
      dosen: dosen ?? budi,
      programStudi: JadwalMasterData.programStudi.first,
      kelas: kelas(namaKelas),
      ruangan: ruangan(kodeRuangan),
      hari: hari,
      sesiMulai: sesi(mulai),
      sesiSelesai: sesi(selesai),
    );
  }

  late JadwalRepository repository;

  setUp(() {
    repository = JadwalRepository(
      seedData: [
        jadwal(id: 'seed', hari: HariKuliah.rabu, mulai: 3, selesai: 4),
      ],
    );
  });

  test('mata kuliah semester decides periode and tingkat', () {
    expect(mataKuliah('TI501').periode, SemesterPeriode.ganjil);
    expect(mataKuliah('TI501').tingkat, 3);
    expect(mataKuliah('TI202').periode, SemesterPeriode.genap);
    expect(mataKuliah('TI202').tingkat, 1);
  });

  test('filter returns matching schedules sorted by day and session', () {
    repository.add(
      jadwal(id: 'senin', hari: HariKuliah.senin, mulai: 5, selesai: 6),
    );
    repository.add(
      jadwal(
        id: 'senin-pagi',
        hari: HariKuliah.senin,
        kodeRuangan: 'J302',
        dosen: deasy,
        namaKelas: 'TI-1B',
      ),
    );

    final result = repository.filter(
      tahunAjaran: '2026/2027',
      semester: SemesterPeriode.ganjil,
      kelasNama: 'TI-1A',
    );

    expect(result.map((item) => item.id), ['senin', 'seed']);
  });

  test('rejects a room that is already used in an overlapping session', () {
    expect(
      () => repository.add(
        jadwal(
          hari: HariKuliah.rabu,
          mulai: 4,
          selesai: 5,
          dosen: deasy,
          namaKelas: 'TI-1B',
        ),
      ),
      throwsA(
        isA<JadwalConflictException>().having(
          (error) => error.message,
          'message',
          contains('Ruang J301'),
        ),
      ),
    );
  });

  test('rejects a lecturer or class that is already scheduled', () {
    expect(
      () => repository.add(
        jadwal(
          hari: HariKuliah.rabu,
          mulai: 3,
          selesai: 3,
          kodeRuangan: 'J302',
          namaKelas: 'TI-1B',
        ),
      ),
      throwsA(isA<JadwalConflictException>()),
    );
    expect(
      () => repository.add(
        jadwal(
          hari: HariKuliah.rabu,
          mulai: 4,
          selesai: 4,
          kodeRuangan: 'J302',
          dosen: deasy,
        ),
      ),
      throwsA(isA<JadwalConflictException>()),
    );
  });

  test('allows the same slot on another day or in the other semester', () {
    repository.add(
      jadwal(id: 'kamis', hari: HariKuliah.kamis, mulai: 3, selesai: 4),
    );
    repository.add(
      jadwal(
        id: 'genap',
        kodeMataKuliah: 'TI202',
        hari: HariKuliah.rabu,
        mulai: 3,
        selesai: 4,
      ),
    );

    expect(repository.getAll(), hasLength(3));
  });

  test('add notifies listeners only when the schedule is saved', () {
    var notified = 0;
    repository.addListener(() => notified++);

    repository.add(jadwal(id: 'jumat', hari: HariKuliah.jumat));
    expect(notified, 1);

    expect(
      () => repository.add(jadwal(id: 'bentrok', hari: HariKuliah.jumat)),
      throwsA(isA<JadwalConflictException>()),
    );
    expect(notified, 1);
  });
}
