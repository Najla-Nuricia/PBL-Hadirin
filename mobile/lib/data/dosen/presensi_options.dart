const lecturerKelasOptions = ['TI-3A', 'TI-3B', 'SIB-2C'];

const lecturerMataKuliahOptions = [
  'Basis Data',
  'Pemrograman Mobile',
  'Jaringan Komputer',
  'Rekayasa Perangkat Lunak',
];

/// Pilihan yang dikirim ke halaman Daftar Kehadiran.
class PresensiFilter {
  const PresensiFilter({
    required this.kelas,
    required this.tanggal,
    required this.mataKuliah,
  });

  final String kelas;
  final DateTime tanggal;
  final String mataKuliah;
}