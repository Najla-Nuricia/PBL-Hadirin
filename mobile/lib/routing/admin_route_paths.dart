abstract final class AdminRoutePaths {
  static const login = '/admin/login';
  static const dataAkademik = '/admin/data-akademik';
  static const tambahJadwal = '/admin/tambah-jadwal';
  static const jadwal = '/admin/jadwal';
  static const tahunAjaran = '/admin/tahun-ajaran';
  static const tambahTahunAjaranSegment = 'tambah';
  static const tambahTahunAjaran = '$tahunAjaran/$tambahTahunAjaranSegment';

  /// Sub-segment umum untuk halaman form tambah data.
  static const tambahSegment = 'tambah';

  // Modul Kelas
  static const kelas = '/admin/kelas';
  static const tambahKelas = '$kelas/$tambahSegment';

  // Modul Ruangan
  static const ruangan = '/admin/ruangan';
  static const tambahRuangan = '$ruangan/$tambahSegment';

  // Modul Dosen
  static const dosen = '/admin/dosen';
  static const tambahDosen = '$dosen/$tambahSegment';

  // Modul Mata Kuliah
  static const mataKuliah = '/admin/mata-kuliah';
  static const tambahMataKuliah = '$mataKuliah/$tambahSegment';
}
