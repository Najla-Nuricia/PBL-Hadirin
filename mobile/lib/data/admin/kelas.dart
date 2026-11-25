/// Status kelas sesuai nilai yang diterima backend (`aktif`/`non_aktif`).
enum KelasStatus { aktif, nonAktif }

extension KelasStatusLabel on KelasStatus {
  String get label => switch (this) {
        KelasStatus.aktif => 'Aktif',
        KelasStatus.nonAktif => 'Non-Aktif',
      };

  /// Nilai persis yang dikirim ke/diterima dari backend.
  String get apiValue => switch (this) {
        KelasStatus.aktif => 'aktif',
        KelasStatus.nonAktif => 'non_aktif',
      };

  static KelasStatus fromApiValue(Object? value) =>
      value?.toString().toLowerCase() == 'non_aktif'
      ? KelasStatus.nonAktif
      : KelasStatus.aktif;
}

/// Model Kelas dari endpoint `/admin/kelas`.
///
/// Backend menghilangkan field bernilai null (`response_model_exclude_none`),
/// jadi semua field opsional dibaca dengan aman.
class Kelas {
  const Kelas({
    required this.id,
    required this.nama,
    required this.tingkat,
    required this.programStudiKode,
    required this.tahunAjaranId,
    this.kapasitas = 30,
    this.status = KelasStatus.aktif,
    this.programStudiNama,
    this.tahunAjaranTahun,
    this.createdAt,
    this.updatedAt,
  });

  factory Kelas.fromAdminApiJson(Map<String, dynamic> json) => Kelas(
    id: _string(json['id']),
    nama: _string(json['nama']),
    tingkat: _integer(json['tingkat']),
    programStudiKode: _string(json['program_studi_kode']),
    tahunAjaranId: _string(json['tahun_ajaran_id']),
    kapasitas: _integer(json['kapasitas'], fallback: 30),
    status: KelasStatusLabel.fromApiValue(json['status']),
    programStudiNama: _optionalString(json['program_studi_nama']),
    tahunAjaranTahun: _optionalString(json['tahun_ajaran_tahun']),
    createdAt: _dateTime(json['created_at']),
    updatedAt: _dateTime(json['updated_at']),
  );

  factory Kelas.fromJson(Map<String, dynamic> json) =>
      Kelas.fromAdminApiJson(json);

  final String id;
  final String nama;
  final int tingkat;
  final String programStudiKode;
  final String tahunAjaranId;
  final int kapasitas;
  final KelasStatus status;

  /// Field turunan dari join backend; boleh tidak ada pada response.
  final String? programStudiNama;
  final String? tahunAjaranTahun;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get programStudiLabel {
    final nama = programStudiNama?.trim();
    return nama == null || nama.isEmpty ? programStudiKode : nama;
  }

  String get tahunAjaranLabel {
    final tahun = tahunAjaranTahun?.trim();
    return tahun == null || tahun.isEmpty ? tahunAjaranId : tahun;
  }

  /// Payload POST/PUT: hanya field yang diterima backend.
  Map<String, dynamic> toAdminApiJson() => {
    'nama': nama.trim(),
    'tingkat': tingkat,
    'program_studi_kode': programStudiKode.trim(),
    'tahun_ajaran_id': tahunAjaranId.trim(),
    'kapasitas': kapasitas,
    'status': status.apiValue,
  };

  Map<String, dynamic> toJson() => toAdminApiJson();

  static String _string(Object? value) => value?.toString() ?? '';

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int _integer(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _dateTime(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
