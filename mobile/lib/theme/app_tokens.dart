import 'package:flutter/material.dart';

/// Palet mentah. Layar memakainya lewat [ColorScheme] atau [StatusTone].
abstract final class AppColors {
  static const canvas = Color(0xFFF1F4FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF7F9FD);
  static const surfaceInset = Color(0xFFEAEEF7);

  static const ink = Color(0xFF0E1A2E);
  static const inkMuted = Color(0xFF4B5A72);
  static const inkFaint = Color(0xFF6A778C);

  static const line = Color(0xFFE0E6F2);
  static const lineStrong = Color(0xFFD2D9E8);
  static const fieldLine = Color(0xFFBFC8DA);

  static const brand50 = Color(0xFFE8F0FF);
  static const brand100 = Color(0xFFDCE8FF);
  static const brand200 = Color(0xFFB9D0FF);
  static const brand600 = Color(0xFF1257E7);
  static const brand700 = Color(0xFF0E49BD);
  static const brand800 = Color(0xFF0B389F);
  static const brand900 = Color(0xFF0A2C73);

  /// Pendamping hijau-sian untuk ikon sesi yang dibuka.
  static const brandCyan = Color(0xFF22B8F0);

  static const sessionBackground = Color(0xFF13213A);
  static const sessionLine = Color(0xFF2E4F8C);
  static const sessionOpen = Color(0xFF7CF0BD);
  static const onBrandMuted = Color(0xFFD9E7F7);

  /// Palet ilustrasi landing: langit, awan, dan pita wisuda.
  static const sky = Color(0xFF0FA1FD);
  static const skySoft = Color(0xFF7BCAFD);
  static const cloud = Color(0xFFDDEEFD);
  static const cloudCream = Color(0xFFFEEEDC);
  static const ribbonOrange = Color(0xFFFE8614);
  static const ribbonCoral = Color(0xFFFD3E50);
  static const gownNavy = Color(0xFF1B2B45);

  /// Tombol utama di atas ilustrasi: navy toga ke biru buku.
  static const landingCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2B45), Color(0xFF224D74), Color(0xFF0A64A2)],
  );

  /// Gradien tanda tangan aplikasi: biru langit ke biru Hadir.in. Bagian
  /// tengahnya tetap biru tua supaya label putih di atasnya kontras.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A8CF0), Color(0xFF1257E7), Color(0xFF1442C4)],
  );

  /// Gradien gelap untuk kartu sesi dan kepala profil: navy toga ke biru
  /// buku pada ilustrasi.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF13213A), Color(0xFF1B3A66), Color(0xFF0A64A2)],
    stops: [0, 0.55, 1],
  );

  /// Langit di kepala layar, dari biru terang ke biru awan.
  static const skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sky, Color(0xFF45B6FD), skySoft],
  );

  /// Kabut latar: krem di kanan atas menyambung awan di bawah app bar,
  /// biru langit di kiri, dan semburat oranye pita di kanan bawah.
  static const auroraBlobs = [
    Color(0x80FEEEDC),
    Color(0x1F0FA1FD),
    Color(0x14FE8614),
  ];

  /// Bayangan lembut berlapis untuk kartu dan elemen melayang.
  static const shadowSoft = [
    BoxShadow(
      color: Color(0x140C1B33),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: -10,
    ),
    BoxShadow(color: Color(0x0A0C1B33), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const shadowLifted = [
    BoxShadow(
      color: Color(0x1F0C1B33),
      blurRadius: 40,
      offset: Offset(0, 18),
      spreadRadius: -12,
    ),
    BoxShadow(color: Color(0x0F0C1B33), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const shadowBrand = [
    BoxShadow(
      color: Color(0x401257E7),
      blurRadius: 28,
      offset: Offset(0, 14),
      spreadRadius: -12,
    ),
  ];

  static const hadir = Color(0xFF0E9258);
  static const hadirInk = Color(0xFF08714A);
  static const hadirTint = Color(0xFFE3F5EB);
  static const izin = Color(0xFFD98A00);
  static const izinInk = Color(0xFF8A4F00);
  static const izinTint = Color(0xFFFFF0D2);
  static const sakit = Color(0xFF0F86B5);
  static const sakitInk = Color(0xFF0B6588);
  static const sakitTint = Color(0xFFE0F2FA);
  static const alfa = Color(0xFFD5301F);
  static const alfaInk = Color(0xFFAE1F14);
  static const alfaTint = Color(0xFFFDE8E5);

  // Layar kamera: tirai gelap dan warna cincin verifikasi.
  static const scrim = Color(0xFF0B1220);
  static const onScrimMuted = Color(0xFFDDE3EC);
  static const ringIdle = Color(0xFFFFFFFF);
  static const ringWarn = Color(0xFFFFB020);
  static const ringActive = Color(0xFF5B93FF);
  static const ringOk = Color(0xFF2FD08A);
  static const ringFail = Color(0xFFFF6B5E);
}

/// Warna semantik. Empat yang pertama adalah status kehadiran dan selalu
/// tampil bersama ikon dan teks, tidak pernah warna saja.
enum StatusTone {
  hadir(AppColors.hadir, AppColors.hadirInk, AppColors.hadirTint),
  izin(AppColors.izin, AppColors.izinInk, AppColors.izinTint),
  sakit(AppColors.sakit, AppColors.sakitInk, AppColors.sakitTint),
  alfa(AppColors.alfa, AppColors.alfaInk, AppColors.alfaTint),
  info(AppColors.brand600, AppColors.brand900, AppColors.brand50),
  neutral(AppColors.inkFaint, AppColors.inkMuted, AppColors.surfaceInset);

  const StatusTone(this.solid, this.ink, this.tint);

  /// Isi batang, titik, dan ikon di atas permukaan putih.
  final Color solid;

  /// Teks dan ikon di atas [tint]; kontras minimal 4,5:1.
  final Color ink;

  /// Latar lencana dan banner.
  final Color tint;

  static const success = StatusTone.hadir;
  static const warning = StatusTone.izin;
  static const danger = StatusTone.alfa;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Jarak isi dari tepi layar.
  static const double page = 20;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 30;
  static const double sheet = 32;

  static const control = BorderRadius.all(Radius.circular(md));
  static const card = BorderRadius.all(Radius.circular(lg));
  static const hero = BorderRadius.all(Radius.circular(xl));
  static const dock = BorderRadius.all(Radius.circular(xxl));
  static const pill = BorderRadius.all(Radius.circular(999));
}

abstract final class AppSizes {
  static const double touch = 48;
  static const double control = 52;

  /// Lebar isi maksimal di tablet dan desktop.
  static const double contentMaxWidth = 560;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 250);
  static const ring = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 450);
  static const curve = Cubic(0.16, 1, 0.3, 1);
}

extension AppTextStyleX on TextStyle {
  /// Angka selebar sama untuk jam, NIM, dan jumlah.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
