import 'admin_master_data_service.dart';
import 'jadwal.dart';
import 'tahun_ajaran.dart';

/// Pilihan master data yang dipakai form tambah jadwal admin.
class JadwalFormOptions {
  const JadwalFormOptions({
    required this.tahunAjaran,
    required this.mataKuliah,
    required this.dosen,
    required this.programStudi,
    required this.ruangan,
    required this.sesi,
    required this.kelas,
  });

  final List<TahunAjaran> tahunAjaran;
  final List<MataKuliah> mataKuliah;
  final List<Dosen> dosen;
  final List<ProgramStudi> programStudi;
  final List<Ruangan> ruangan;
  final List<SesiKuliah> sesi;
  final List<KelasKuliah> kelas;

  JadwalFormOptions copyWith({List<KelasKuliah>? kelas}) => JadwalFormOptions(
    tahunAjaran: tahunAjaran,
    mataKuliah: mataKuliah,
    dosen: dosen,
    programStudi: programStudi,
    ruangan: ruangan,
    sesi: sesi,
    kelas: kelas ?? this.kelas,
  );
}

/// Mengambil seluruh pilihan form jadwal dari backend Hadirin.
class AdminJadwalOptionsService {
  AdminJadwalOptionsService({AdminMasterDataService? masterData})
    : _masterData = masterData ?? adminMasterDataService;

  final AdminMasterDataService _masterData;

  Future<JadwalFormOptions> load() async {
    final results = await Future.wait<Object>([
      _masterData.listTahunAjaran(),
      _masterData.listMataKuliah(),
      _masterData.listDosen(),
      _masterData.listProgramStudi(),
      _masterData.listRuangan(),
      _masterData.listSesiKuliah(),
    ]);

    final sesi = (results[5] as List<SesiKuliah>).toList()
      ..sort((a, b) => a.nomor.compareTo(b.nomor));

    return JadwalFormOptions(
      tahunAjaran: results[0] as List<TahunAjaran>,
      mataKuliah: results[1] as List<MataKuliah>,
      dosen: results[2] as List<Dosen>,
      programStudi: results[3] as List<ProgramStudi>,
      ruangan: results[4] as List<Ruangan>,
      sesi: sesi,
      kelas: const [],
    );
  }

  /// Kelas bergantung pada tahun ajaran yang dipilih di form.
  Future<List<KelasKuliah>> loadKelas(String tahunAjaran) =>
      _masterData.listKelas(tahunAjaran: tahunAjaran);
}

final adminJadwalOptionsService = AdminJadwalOptionsService();
