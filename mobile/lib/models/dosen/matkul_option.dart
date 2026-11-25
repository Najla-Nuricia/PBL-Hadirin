/// Opsi mata kuliah dari `GET /dosen/matkul?kelas_id=...&tanggal=...`.
class MatkulOption {
  const MatkulOption({
    required this.jadwalId,
    required this.kode,
    required this.nama,
    this.sks,
    this.jamMulai = '',
    this.jamSelesai = '',
    this.ruanganNama,
  });

  factory MatkulOption.fromJson(Map<String, dynamic> json) {
    return MatkulOption(
      jadwalId: (json['jadwal_id'] as String?) ?? '',
      kode: (json['kode'] as String?) ?? (json['course_code'] as String?) ?? '',
      nama: (json['nama'] as String?) ?? (json['course_name'] as String?) ?? '',
      sks: (json['sks'] as num?)?.toInt(),
      jamMulai: (json['jam_mulai'] as String?) ?? '',
      jamSelesai: (json['jam_selesai'] as String?) ?? '',
      ruanganNama: json['ruangan_nama'] as String?,
    );
  }

  final String jadwalId;
  final String kode;
  final String nama;
  final int? sks;
  final String jamMulai;
  final String jamSelesai;
  final String? ruanganNama;
}
