class WhitelistNim {
  const WhitelistNim({
    required this.nim,
    required this.namaMahasiswa,
    required this.kelas,
    required this.status,
  });

  final String nim;
  final String namaMahasiswa;
  final String kelas;
  final String status;

  bool get sudahRegistrasi => status == 'Sudah Registrasi';
}
