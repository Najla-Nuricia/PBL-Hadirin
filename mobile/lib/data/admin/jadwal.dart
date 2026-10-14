import 'package:flutter/foundation.dart';

import 'tahun_ajaran.dart';

enum SemesterPeriode { ganjil, genap }

extension SemesterPeriodeLabel on SemesterPeriode {
  String get label => switch (this) {
    SemesterPeriode.ganjil => defaultSemesterInfo.namaGanjil,
    SemesterPeriode.genap => defaultSemesterInfo.namaGenap,
  };
}

enum HariKuliah { senin, selasa, rabu, kamis, jumat, sabtu }

extension HariKuliahLabel on HariKuliah {
  String get label => switch (this) {
    HariKuliah.senin => 'Senin',
    HariKuliah.selasa => 'Selasa',
    HariKuliah.rabu => 'Rabu',
    HariKuliah.kamis => 'Kamis',
    HariKuliah.jumat => 'Jumat',
    HariKuliah.sabtu => 'Sabtu',
  };
}

class MataKuliah {
  const MataKuliah({
    required this.kode,
    required this.nama,
    required this.semester,
    required this.sks,
  });

  final String kode;
  final String nama;

  /// Semester kurikulum (1–8); ganjil/genap dan tingkat diturunkan dari sini.
  final int semester;
  final int sks;

  SemesterPeriode get periode =>
      semester.isOdd ? SemesterPeriode.ganjil : SemesterPeriode.genap;

  int get tingkat => (semester + 1) ~/ 2;
}

class Dosen {
  const Dosen({required this.nip, required this.nama});

  final String nip;
  final String nama;
}

class ProgramStudi {
  const ProgramStudi({required this.kode, required this.nama});

  final String kode;
  final String nama;
}

class KelasKuliah {
  const KelasKuliah({
    required this.nama,
    required this.tingkat,
    required this.programStudiKode,
  });

  /// Contoh: "TI-3A"
  final String nama;
  final int tingkat;
  final String programStudiKode;
}

class Ruangan {
  const Ruangan({required this.kode, required this.nama});

  final String kode;
  final String nama;
}

class SesiKuliah {
  const SesiKuliah({
    required this.nomor,
    required this.jamMulai,
    required this.jamSelesai,
  });

  final int nomor;

  /// Format "HH:mm"
  final String jamMulai;
  final String jamSelesai;
}

class JadwalKuliah {
  const JadwalKuliah({
    required this.id,
    required this.tahunAjaran,
    required this.mataKuliah,
    required this.dosen,
    required this.programStudi,
    required this.kelas,
    required this.ruangan,
    required this.hari,
    required this.sesiMulai,
    required this.sesiSelesai,
    this.isAktif = true,
  });

  final String id;

  /// Format: "2026/2027"
  final String tahunAjaran;
  final MataKuliah mataKuliah;
  final Dosen dosen;
  final ProgramStudi programStudi;
  final KelasKuliah kelas;
  final Ruangan ruangan;
  final HariKuliah hari;
  final SesiKuliah sesiMulai;
  final SesiKuliah sesiSelesai;
  final bool isAktif;

  SemesterPeriode get semester => mataKuliah.periode;

  String get rentangWaktu =>
      '${sesiMulai.jamMulai} – ${sesiSelesai.jamSelesai}';

  bool overlapsWith(JadwalKuliah other) {
    return tahunAjaran == other.tahunAjaran &&
        semester == other.semester &&
        hari == other.hari &&
        sesiMulai.nomor <= other.sesiSelesai.nomor &&
        other.sesiMulai.nomor <= sesiSelesai.nomor;
  }

  JadwalKuliah copyWith({bool? isAktif}) {
    return JadwalKuliah(
      id: id,
      tahunAjaran: tahunAjaran,
      mataKuliah: mataKuliah,
      dosen: dosen,
      programStudi: programStudi,
      kelas: kelas,
      ruangan: ruangan,
      hari: hari,
      sesiMulai: sesiMulai,
      sesiSelesai: sesiSelesai,
      isAktif: isAktif ?? this.isAktif,
    );
  }
}

/// Data master dummy untuk pilihan form jadwal, sampai backend siap.
abstract final class JadwalMasterData {
  static const programStudi = [
    ProgramStudi(kode: 'D4-TI', nama: 'D4 Teknik Informatika'),
    ProgramStudi(kode: 'D2-PPLS', nama: 'D2 Pengembangan Piranti Lunak Situs'),
  ];

  static const mataKuliah = [
    MataKuliah(kode: 'TI101', nama: 'Matematika Dasar', semester: 1, sks: 2),
    MataKuliah(
      kode: 'TI102',
      nama: 'Algoritma dan Pemrograman',
      semester: 1,
      sks: 3,
    ),
    MataKuliah(kode: 'TI201', nama: 'Struktur Data', semester: 2, sks: 3),
    MataKuliah(kode: 'TI202', nama: 'Basis Data', semester: 2, sks: 3),
    MataKuliah(
      kode: 'TI301',
      nama: 'Pemrograman Berorientasi Objek',
      semester: 3,
      sks: 3,
    ),
    MataKuliah(kode: 'TI302', nama: 'Desain Antarmuka', semester: 3, sks: 2),
    MataKuliah(kode: 'TI401', nama: 'Pemrograman Web', semester: 4, sks: 3),
    MataKuliah(kode: 'TI402', nama: 'Sistem Operasi', semester: 4, sks: 2),
    MataKuliah(
      kode: 'TI501',
      nama: 'Pemrograman Web Lanjut',
      semester: 5,
      sks: 3,
    ),
    MataKuliah(kode: 'TI502', nama: 'Basis Data Lanjut', semester: 5, sks: 3),
    MataKuliah(kode: 'TI503', nama: 'Jaringan Komputer', semester: 5, sks: 3),
    MataKuliah(
      kode: 'TI504',
      nama: 'Proyek Perangkat Lunak',
      semester: 5,
      sks: 4,
    ),
    MataKuliah(kode: 'TI505', nama: 'Kecerdasan Buatan', semester: 5, sks: 2),
    MataKuliah(kode: 'TI601', nama: 'Pemrograman Mobile', semester: 6, sks: 3),
    MataKuliah(kode: 'TI602', nama: 'Keamanan Informasi', semester: 6, sks: 2),
  ];

  static const dosen = [
    Dosen(nip: '198501012010121001', nama: 'Budi Santoso, S.T., M.T.'),
    Dosen(nip: '198703152012122002', nama: 'Deasy Sandhya, S.Kom., M.Kom.'),
    Dosen(nip: '199002202015041003', nama: 'Rizky Pratama, S.Kom., M.T.'),
    Dosen(nip: '198811112014032004', nama: 'Sandhya Putri, S.T., M.Cs.'),
    Dosen(nip: '197905052005011005', nama: 'Ahmad Fauzi, S.Kom., M.Kom.'),
  ];

  static const kelas = [
    KelasKuliah(nama: 'TI-1A', tingkat: 1, programStudiKode: 'D4-TI'),
    KelasKuliah(nama: 'TI-1B', tingkat: 1, programStudiKode: 'D4-TI'),
    KelasKuliah(nama: 'TI-2A', tingkat: 2, programStudiKode: 'D4-TI'),
    KelasKuliah(nama: 'TI-2B', tingkat: 2, programStudiKode: 'D4-TI'),
    KelasKuliah(nama: 'TI-3A', tingkat: 3, programStudiKode: 'D4-TI'),
    KelasKuliah(nama: 'TI-3B', tingkat: 3, programStudiKode: 'D4-TI'),
    KelasKuliah(nama: 'TI-4A', tingkat: 4, programStudiKode: 'D4-TI'),
    KelasKuliah(nama: 'PPLS-1A', tingkat: 1, programStudiKode: 'D2-PPLS'),
    KelasKuliah(nama: 'PPLS-2A', tingkat: 2, programStudiKode: 'D2-PPLS'),
  ];

  static const ruangan = [
    Ruangan(kode: 'J301', nama: 'Ruang J301'),
    Ruangan(kode: 'J302', nama: 'Ruang J302'),
    Ruangan(kode: 'RT01', nama: 'RT01'),
    Ruangan(kode: 'RT02', nama: 'RT02'),
    Ruangan(kode: 'LPR1', nama: 'LPR1'),
    Ruangan(kode: 'LPR2', nama: 'LPR2'),
    Ruangan(kode: 'LPR3', nama: 'LPR3'),
  ];

  static const sesi = [
    SesiKuliah(nomor: 1, jamMulai: '07:00', jamSelesai: '07:50'),
    SesiKuliah(nomor: 2, jamMulai: '07:50', jamSelesai: '08:40'),
    SesiKuliah(nomor: 3, jamMulai: '08:40', jamSelesai: '09:30'),
    SesiKuliah(nomor: 4, jamMulai: '09:40', jamSelesai: '10:30'),
    SesiKuliah(nomor: 5, jamMulai: '10:30', jamSelesai: '11:20'),
    SesiKuliah(nomor: 6, jamMulai: '11:20', jamSelesai: '12:10'),
    SesiKuliah(nomor: 7, jamMulai: '12:50', jamSelesai: '13:40'),
    SesiKuliah(nomor: 8, jamMulai: '13:40', jamSelesai: '14:30'),
    SesiKuliah(nomor: 9, jamMulai: '14:30', jamSelesai: '15:20'),
    SesiKuliah(nomor: 10, jamMulai: '15:30', jamSelesai: '16:20'),
    SesiKuliah(nomor: 11, jamMulai: '16:20', jamSelesai: '17:10'),
    SesiKuliah(nomor: 12, jamMulai: '17:10', jamSelesai: '18:00'),
  ];

  static List<int> get tingkat =>
      {for (final item in kelas) item.tingkat}.toList()..sort();

  static List<KelasKuliah> kelasByTingkat(int tingkat) =>
      kelas.where((item) => item.tingkat == tingkat).toList();

  static List<KelasKuliah> kelasByProgramStudi(String programStudiKode) =>
      kelas.where((item) => item.programStudiKode == programStudiKode).toList();
}

class JadwalConflictException implements Exception {
  const JadwalConflictException(this.message);

  final String message;

  @override
  String toString() => 'JadwalConflictException: $message';
}

/// In-memory repository untuk jadwal kuliah (dummy, sampai backend siap).
class JadwalRepository extends ChangeNotifier {
  JadwalRepository({List<JadwalKuliah>? seedData})
    : _items = List.of(seedData ?? _buildSeedData());

  final List<JadwalKuliah> _items;
  var _nextId = 1000;

  List<JadwalKuliah> getAll() => List.unmodifiable(_items);

  List<JadwalKuliah> filter({
    required String tahunAjaran,
    required SemesterPeriode semester,
    required String kelasNama,
  }) {
    final result = _items
        .where(
          (item) =>
              item.tahunAjaran == tahunAjaran &&
              item.semester == semester &&
              item.kelas.nama == kelasNama,
        )
        .toList();
    result.sort((a, b) {
      final byDay = a.hari.index.compareTo(b.hari.index);
      return byDay != 0
          ? byDay
          : a.sesiMulai.nomor.compareTo(b.sesiMulai.nomor);
    });
    return result;
  }

  /// Throws [JadwalConflictException] when the room, lecturer, or class is
  /// already booked in an overlapping session.
  void add(JadwalKuliah jadwal) {
    for (final existing in _items) {
      if (!existing.overlapsWith(jadwal)) continue;
      final waktu =
          '${existing.hari.label}, ${existing.rentangWaktu} '
          '(${existing.mataKuliah.nama})';
      if (existing.ruangan.kode == jadwal.ruangan.kode) {
        throw JadwalConflictException(
          '${jadwal.ruangan.nama} sudah dipakai pada $waktu.',
        );
      }
      if (existing.dosen.nip == jadwal.dosen.nip) {
        throw JadwalConflictException(
          '${jadwal.dosen.nama} sudah mengajar pada $waktu.',
        );
      }
      if (existing.kelas.nama == jadwal.kelas.nama) {
        throw JadwalConflictException(
          'Kelas ${jadwal.kelas.nama} sudah ada jadwal pada $waktu.',
        );
      }
    }
    _items.add(jadwal);
    notifyListeners();
  }

  void setAktif(String id, {required bool isAktif}) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(isAktif: isAktif);
    notifyListeners();
  }

  String generateId() => 'jadwal-${_nextId++}';

  static List<JadwalKuliah> _buildSeedData() {
    MataKuliah mataKuliah(String kode) =>
        JadwalMasterData.mataKuliah.firstWhere((item) => item.kode == kode);
    Dosen dosen(String nip) =>
        JadwalMasterData.dosen.firstWhere((item) => item.nip == nip);
    KelasKuliah kelas(String nama) =>
        JadwalMasterData.kelas.firstWhere((item) => item.nama == nama);
    Ruangan ruangan(String kode) =>
        JadwalMasterData.ruangan.firstWhere((item) => item.kode == kode);
    SesiKuliah sesi(int nomor) => JadwalMasterData.sesi[nomor - 1];
    final programStudi = JadwalMasterData.programStudi.first;

    JadwalKuliah seed(
      String id,
      String kodeMataKuliah,
      String nipDosen,
      String namaKelas,
      String kodeRuangan,
      HariKuliah hari,
      int mulai,
      int selesai,
    ) {
      return JadwalKuliah(
        id: id,
        tahunAjaran: '2026/2027',
        mataKuliah: mataKuliah(kodeMataKuliah),
        dosen: dosen(nipDosen),
        programStudi: programStudi,
        kelas: kelas(namaKelas),
        ruangan: ruangan(kodeRuangan),
        hari: hari,
        sesiMulai: sesi(mulai),
        sesiSelesai: sesi(selesai),
      );
    }

    return [
      seed(
        '1',
        'TI501',
        '198501012010121001',
        'TI-3A',
        'J301',
        HariKuliah.senin,
        2,
        3,
      ),
      seed(
        '2',
        'TI502',
        '198703152012122002',
        'TI-3A',
        'LPR1',
        HariKuliah.selasa,
        1,
        2,
      ),
      seed(
        '3',
        'TI505',
        '198501012010121001',
        'TI-3A',
        'RT01',
        HariKuliah.rabu,
        3,
        5,
      ),
      seed(
        '4',
        'TI503',
        '198811112014032004',
        'TI-3A',
        'LPR3',
        HariKuliah.kamis,
        5,
        6,
      ),
      seed(
        '5',
        'TI504',
        '198501012010121001',
        'TI-3A',
        'LPR1',
        HariKuliah.jumat,
        8,
        10,
      ),
      seed(
        '6',
        'TI101',
        '197905052005011005',
        'TI-1A',
        'RT02',
        HariKuliah.senin,
        1,
        2,
      ),
      seed(
        '7',
        'TI102',
        '199002202015041003',
        'TI-1A',
        'LPR2',
        HariKuliah.rabu,
        7,
        9,
      ),
    ];
  }
}

/// Singleton repository instance.
final jadwalRepository = JadwalRepository();
