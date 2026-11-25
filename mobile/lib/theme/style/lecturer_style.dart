import 'package:flutter/widgets.dart';

import '../app_tokens.dart';

/// Ukuran tata letak layar dosen, semuanya diturunkan dari token pusat.
abstract final class LecturerStyle {
  /// Jarak isi layar yang bisa digulir.
  static const pageInsets = EdgeInsets.fromLTRB(
    AppSpacing.page,
    AppSpacing.xs,
    AppSpacing.page,
    AppSpacing.xxl,
  );

  /// Jarak batang aksi di dasar layar.
  static const bottomBarInsets = EdgeInsets.fromLTRB(
    AppSpacing.page,
    AppSpacing.md,
    AppSpacing.page,
    AppSpacing.lg,
  );

  static const cardInsets = EdgeInsets.all(AppSpacing.lg);

  /// Kartu rincian: baris label dan nilai sudah punya jarak vertikal sendiri.
  static const detailCardInsets = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.xs,
  );

  /// Isi satu baris daftar di dalam kartu.
  static const rowInsets = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );

  static const double rowMinHeight = 64;

  /// Avatar atau kotak ikon di awal baris daftar.
  static const double rowLeadingSize = 40;

  /// Avatar di kepala layar profil dan detail mahasiswa.
  static const double headerAvatarSize = 64;

  static const double fieldLabelGap = 6;
}
