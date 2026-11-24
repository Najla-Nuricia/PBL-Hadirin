import '../app_tokens.dart';

/// Ukuran layar auth. Nilainya mengikuti token aplikasi; nama lama tetap ada
/// karena masih dipakai halaman mahasiswa dan dosen.
abstract final class AuthStyle {
  static const double maxContentWidth = AppSizes.contentMaxWidth;
  static const double headerHorizontalPadding = AppSpacing.page;
  static const double contentHorizontalPadding = AppSpacing.page;
  static const double stepIndicatorHeight = 4;

  /// Bilah aksen bawah sudah dihapus dari layar auth.
  static const double bottomAccentHeight = 0;
  static const double fieldRadius = AppRadius.md;
  static const double buttonHeight = AppSizes.control;
  static const double titleSize = 24;
  static const double bodySize = 14;
  static const double captionSize = 12.5;
  static const double cameraFrameMaxWidth = 315;
  static const double cameraFrameAspectRatio = 315 / 333;
  static const double cameraFrameRadius = 20;

  /// Jarak dari label ke kolom isiannya.
  static const double labelGap = 6;

  /// Jarak antar kolom isian dalam satu formulir.
  static const double fieldGap = AppSpacing.lg;
}
