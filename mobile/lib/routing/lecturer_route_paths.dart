abstract final class LecturerRoutePaths {
  static const beranda = '/dosen/beranda';
  static const kehadiran = '/dosen/kehadiran';
  static const profil = '/dosen/profil';
  static const changePassword = '/dosen/profil/ubah-kata-sandi';

  static String studentDetail(String id) => '$kehadiran/$id';

  /// Navbar disembunyikan di halaman detail (ubah kata sandi & detail mahasiswa).
  static bool showsNavbar(String path) {
    if (path == changePassword) return false;
    if (path.startsWith('$kehadiran/')) return false;
    return true;
  }
}