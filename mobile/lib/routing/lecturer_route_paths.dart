// lib/routing/lecturer_route_paths.dart
abstract final class LecturerRoutePaths {
  static const beranda = '/dosen/beranda';
  static const kehadiran = '/dosen/kehadiran';
  static const profil = '/dosen/profil';
  static const changePassword = '/dosen/profil/ubah-kata-sandi';

  static const daftarSegment = 'daftar';
  static const daftarKehadiran = '$kehadiran/$daftarSegment';

  static String studentDetail(String id) => '$daftarKehadiran/$id';

  /// Alias, dipakai oleh attendance_list_page.dart.
  static String kehadiranDetail(String id) => studentDetail(id);

  /// Navbar disembunyikan di halaman detail (ubah kata sandi & detail mahasiswa).
  static bool showsNavbar(String path) {
    if (path == changePassword) return false;
    if (path.startsWith('$daftarKehadiran/')) return false;
    return true;
  }
}