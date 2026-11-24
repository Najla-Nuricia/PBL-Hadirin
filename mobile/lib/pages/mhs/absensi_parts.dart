import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/location_service.dart';
import '../../widgets/widgets.dart';

/// Jendela pemindai QR dengan bingkai sudut dan keterangan di bawahnya.
class QrScannerFrame extends StatelessWidget {
  const QrScannerFrame({
    required this.scanner,
    required this.onDetect,
    required this.label,
    this.busy = false,
    super.key,
  });

  final MobileScannerController? scanner;
  final void Function(BarcodeCapture capture) onDetect;
  final String label;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scanner = this.scanner;

    return ClipRRect(
      borderRadius: AppRadius.card,
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.scrim),
            if (scanner != null)
              MobileScanner(
                controller: scanner,
                fit: BoxFit.cover,
                onDetect: onDetect,
                errorBuilder: (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Kamera pemindai tidak tersedia.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                placeholderBuilder: (context) =>
                    const ColoredBox(color: AppColors.scrim),
              ),
            CustomPaint(painter: _QrCornersPainter(active: scanner != null)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                decoration: BoxDecoration(
                  color: AppColors.scrim.withValues(alpha: 0.6),
                  borderRadius: AppRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      busy
                          ? PhosphorIconsRegular.arrowsClockwise
                          : PhosphorIconsRegular.qrCode,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: text.labelMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCornersPainter extends CustomPainter {
  const _QrCornersPainter({required this.active});

  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final side = (size.height - 96).clamp(72.0, 140.0);
    final frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 12),
      width: side,
      height: side,
    );
    const arm = 26.0;
    const r = 14.0;
    const radius = Radius.circular(r);
    final path = Path()
      ..moveTo(frame.left, frame.top + arm)
      ..lineTo(frame.left, frame.top + r)
      ..arcToPoint(Offset(frame.left + r, frame.top), radius: radius)
      ..lineTo(frame.left + arm, frame.top)
      ..moveTo(frame.right - arm, frame.top)
      ..lineTo(frame.right - r, frame.top)
      ..arcToPoint(Offset(frame.right, frame.top + r), radius: radius)
      ..lineTo(frame.right, frame.top + arm)
      ..moveTo(frame.right, frame.bottom - arm)
      ..lineTo(frame.right, frame.bottom - r)
      ..arcToPoint(Offset(frame.right - r, frame.bottom), radius: radius)
      ..lineTo(frame.right - arm, frame.bottom)
      ..moveTo(frame.left + arm, frame.bottom)
      ..lineTo(frame.left + r, frame.bottom)
      ..arcToPoint(Offset(frame.left, frame.bottom - r), radius: radius)
      ..lineTo(frame.left, frame.bottom - arm);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: active ? 1 : 0.4),
    );
  }

  @override
  bool shouldRepaint(_QrCornersPainter old) => old.active != active;
}

/// Status lokasi perangkat dengan tombol muat ulang.
class LocationStatusRow extends StatelessWidget {
  const LocationStatusRow({
    required this.location,
    required this.error,
    required this.locating,
    required this.onRefresh,
    super.key,
  });

  final DeviceLocation? location;
  final String? error;
  final bool locating;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final location = this.location;
    final error = this.error;

    final (icon, color, title, detail) = error != null
        ? (
            PhosphorIconsRegular.gpsSlash,
            AppColors.alfaInk,
            'Lokasi belum terdeteksi',
            error,
          )
        : location != null
        ? (
            PhosphorIconsRegular.mapPin,
            AppColors.hadir,
            'Lokasi terdeteksi',
            'Akurasi ${location.formattedAccuracy}',
          )
        : (
            PhosphorIconsRegular.crosshair,
            AppColors.inkFaint,
            'Mendeteksi lokasi…',
            'Menunggu sinyal GPS',
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, 4, 8),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  Text(
                    detail,
                    style: text.bodySmall?.tabular.copyWith(
                      color: error != null
                          ? AppColors.alfaInk
                          : AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: locating ? null : onRefresh,
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
              tooltip: 'Muat ulang lokasi',
            ),
          ],
        ),
      ),
    );
  }
}

/// Bukti presensi setelah server mencatat kehadiran.
class PresensiReceipt extends StatelessWidget {
  const PresensiReceipt({
    required this.data,
    required this.onDone,
    required this.onHistory,
    this.fallbackCourse,
    super.key,
  });

  /// Jawaban server dari `/attendance/qr` atau `/attendance/face`.
  final Map<String, dynamic> data;
  final String? fallbackCourse;
  final VoidCallback onDone;
  final VoidCallback onHistory;

  String? _text(String key) {
    final value = data[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final course =
        _text('matkul_nama') ?? _text('courseName') ?? fallbackCourse;
    final time = _text('time') ?? _text('jam_masuk');
    final message = _text('message');
    final method = switch (_text('method')) {
      'face' => 'Verifikasi wajah',
      'qr' => 'Kode QR',
      'gps' => 'Lokasi',
      _ => null,
    };
    final distance = data['distance_meters'] ?? data['jarak_meter'];
    final similarity = data['similarity'];

    final rows = <Widget>[
      AppKeyValueRow(
        label: 'Status',
        trailing: AppStatusBadge.attendance(_text('status') ?? 'hadir'),
      ),
      if (time != null) AppKeyValueRow(label: 'Waktu', value: time),
      if (method != null) AppKeyValueRow(label: 'Metode', value: method),
      if (distance is num)
        AppKeyValueRow(
          label: 'Lokasi',
          value: '${distance.round()} m dari titik presensi',
        ),
      if (similarity is num)
        AppKeyValueRow(
          label: 'Kecocokan wajah',
          value: '${(similarity * 100).round()}%',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xxxl,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.hadirTint,
                          borderRadius: AppRadius.card,
                        ),
                        child: SizedBox.square(
                          dimension: 60,
                          child: PhosphorIcon(
                            PhosphorIconsDuotone.checkCircle,
                            size: 34,
                            color: AppColors.hadirInk,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      header: true,
                      child: Text(
                        'Presensi tercatat',
                        style: text.headlineLarge,
                      ),
                    ),
                    if (course != null && course.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        course,
                        style: text.bodyLarge?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        message,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < rows.length; i++) ...[
                              if (i > 0) const Divider(),
                              rows[i],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: onDone,
                child: const Text('Kembali ke beranda'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: onHistory,
                child: const Text('Lihat riwayat'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
