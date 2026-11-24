import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';
import 'hadirin_wordmark.dart';

/// Ikon status bar gelap: teks dan ikon di atas langit memakai navy.
const skyStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

/// App bar langit dengan tepi awan di bawahnya. Dipakai semua layar ber-app
/// bar supaya tiap halaman melanjutkan ilustrasi di layar pembuka.
class SkyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SkyAppBar({
    this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.titleSpacing,
    this.showCloudEdge = true,
    super.key,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final double? titleSpacing;

  /// Matikan bila tepat di bawahnya ada [SkyHeader] yang meneruskan langit.
  final bool showCloudEdge;

  static const double cloudEdgeHeight = 26;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (showCloudEdge ? cloudEdgeHeight : 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      backgroundColor: AppColors.sky,
      foregroundColor: AppColors.gownNavy,
      systemOverlayStyle: skyStatusBar,
      bottom: showCloudEdge
          ? const PreferredSize(
              preferredSize: Size.fromHeight(cloudEdgeHeight),
              child: SizedBox(
                height: cloudEdgeHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: CloudEdgePainter(scale: 0.5, compact: true),
                ),
              ),
            )
          : null,
    );
  }
}

/// Kepala layar berupa langit dengan tepi awan. Isi di bawahnya bisa naik
/// menutupi awan sejauh [overlap].
class SkyHeader extends StatelessWidget {
  const SkyHeader({
    required this.child,
    this.includeStatusBar = true,
    this.overlap = 0,
    this.showDecor = true,
    this.gradient = AppColors.skyGradient,
    super.key,
  });

  final Widget child;

  /// Tambahkan tinggi status bar di atas isi bila tidak ada app bar.
  final bool includeStatusBar;

  /// Ruang ekstra di bawah isi untuk kartu yang menumpuk di atas awan.
  final double overlap;
  final bool showDecor;
  final Gradient gradient;

  static const double cloudHeight = 76;

  @override
  Widget build(BuildContext context) {
    final top = includeStatusBar ? MediaQuery.paddingOf(context).top : 0.0;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        ),
        if (showDecor)
          const Positioned.fill(
            child: CustomPaint(painter: SkyDecorPainter()),
          ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: -1,
          height: cloudHeight,
          child: CustomPaint(painter: CloudEdgePainter()),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            top + AppSpacing.lg,
            AppSpacing.page,
            cloudHeight + overlap,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth - AppSpacing.page * 2,
              ),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ],
    );
  }
}

/// Garis angin putih dan satu pita oranye, seperti pada ilustrasi.
class SkyDecorPainter extends CustomPainter {
  const SkyDecorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final streak = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final (x1, y1, x2, y2) in const [
      (0.58, 0.12, 0.80, 0.04),
      (0.68, 0.21, 0.86, 0.14),
    ]) {
      canvas.drawLine(Offset(x1 * w, y1 * h), Offset(x2 * w, y2 * h), streak);
    }

    final ribbon = Path()
      ..moveTo(w * 0.84, h * 0.36)
      ..quadraticBezierTo(w * 0.94, h * 0.15, w * 1.02, h * 0.04)
      ..quadraticBezierTo(w * 0.95, h * 0.22, w * 0.84, h * 0.36)
      ..close();
    canvas.drawPath(ribbon, Paint()..color = AppColors.ribbonOrange);
  }

  @override
  bool shouldRepaint(SkyDecorPainter oldDelegate) => false;
}

/// Tiga lapis gumpalan awan: krem di belakang, putih, lalu warna kanvas
/// sehingga langit menyatu dengan isi di bawahnya.
class CloudEdgePainter extends CustomPainter {
  const CloudEdgePainter({
    this.scale = 1,
    this.background = AppColors.canvas,
    this.compact = false,
  });

  /// Ukuran gumpalan relatif terhadap tepi awan besar setinggi 76.
  final double scale;
  final Color background;

  /// Dua lapis saja (krem lalu kanvas) untuk tepi tipis di bawah app bar;
  /// tiga lapis kecil terlihat ramai.
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Gumpalan lapis terbawah melewati tepi kotak; tanpa klip ia menimpa
    // tepi atas kartu pertama di bawah app bar.
    canvas.clipRect(Offset.zero & size);

    void layer(
      Color color,
      double baseY,
      double spacing,
      double radius,
      double phase,
      List<double> pattern,
    ) {
      final path = Path()..addRect(Rect.fromLTRB(0, baseY, w, h + 1));
      var index = 0;
      for (var x = -spacing * phase; x <= w + spacing; x += spacing) {
        final r = radius * pattern[index % pattern.length];
        path.addOval(Rect.fromCircle(center: Offset(x, baseY), radius: r));
        index++;
      }
      canvas.drawPath(path, Paint()..color = color);
    }

    final s = scale;
    if (compact) {
      layer(AppColors.cloudCream, h * 0.5, 56 * s, 34 * s, 0.3, const [
        1,
        0.8,
        1.08,
        0.86,
      ]);
      layer(background, h * 0.92, 50 * s, 30 * s, 0.75, const [
        1,
        0.84,
        1.04,
        0.9,
      ]);
      return;
    }
    layer(AppColors.cloudCream, h * 0.62, 52 * s, 40 * s, 0.3, const [
      1,
      0.78,
      1.1,
      0.85,
      1.02,
      0.8,
    ]);
    layer(const Color(0xFFF6F9FE), h * 0.8, 46 * s, 34 * s, 0.65, const [
      0.9,
      1.08,
      0.8,
      1,
      0.86,
    ]);
    layer(background, h * 0.96, 44 * s, 30 * s, 0.1, const [
      1,
      0.82,
      1.06,
      0.88,
    ]);
  }

  @override
  bool shouldRepaint(CloudEdgePainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.background != background ||
      oldDelegate.compact != compact;
}

/// Logo dalam pil putih, terbaca di atas langit dan ilustrasi.
class WordmarkPill extends StatelessWidget {
  const WordmarkPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.pill,
        boxShadow: AppColors.shadowSoft,
      ),
      child: const HadirinWordmark(),
    );
  }
}
