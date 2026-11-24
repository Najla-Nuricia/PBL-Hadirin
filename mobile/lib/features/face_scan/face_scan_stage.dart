import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../theme/app_tokens.dart';
import 'face_guidance.dart';
import 'face_scan_controller.dart';

enum _RingStyle { dashed, solid, progress, sweep }

class _Visual {
  const _Visual({
    required this.color,
    required this.style,
    required this.title,
    this.hint = '',
    this.progress = 0,
    this.spin = false,
  });

  final Color color;
  final _RingStyle style;
  final String title;
  final String hint;
  final double progress;
  final bool spin;
}

/// Area kamera layar scan wajah: pratinjau, tirai gelap dengan bingkai oval,
/// cincin yang bereaksi pada keadaan, dan petunjuk di atasnya.
///
/// Layar induk menaruh bilah atas setinggi [topBarHeight] di atas area ini.
class FaceScanStage extends StatefulWidget {
  const FaceScanStage({
    required this.controller,
    this.title,
    this.hint,
    this.segments = 1,
    this.completedSegments = 0,
    this.footer,
    super.key,
  });

  static const double topBarHeight = 56;

  final FaceScanController controller;

  /// Petunjuk dari layar induk (misalnya pose yang diminta). Peringatan
  /// posisi dan cahaya tetap menggantikannya selama berlaku.
  final String? title;
  final String? hint;

  /// Jumlah foto yang dikumpulkan; lebih dari satu membagi cincin jadi segmen.
  final int segments;
  final int completedSegments;

  /// Isi di bawah bingkai oval, misalnya keping lokasi.
  final Widget? footer;

  @override
  State<FaceScanStage> createState() => _FaceScanStageState();
}

class _FaceScanStageState extends State<FaceScanStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncSpin);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  @override
  void didUpdateWidget(FaceScanStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncSpin);
      widget.controller.addListener(_syncSpin);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncSpin);
    _spin.dispose();
    super.dispose();
  }

  // Animasi berulang hanya berjalan selama keadaannya memang menunggu.
  void _syncSpin() {
    if (!mounted) return;
    final run = _visual().spin && !MediaQuery.disableAnimationsOf(context);
    if (run && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!run && _spin.isAnimating) {
      _spin.stop();
    }
  }

  _Visual _visual() {
    final c = widget.controller;
    final title = widget.title;
    final hint = widget.hint ?? '';
    String hintOr(String fallback) => title == null ? fallback : hint;

    switch (c.overlay) {
      case FaceScanOverride.success:
        return _Visual(
          color: AppColors.ringOk,
          style: _RingStyle.solid,
          title: c.overrideTitle ?? 'Wajah terverifikasi',
          hint: c.overrideHint ?? '',
        );
      case FaceScanOverride.failure:
        return _Visual(
          color: AppColors.ringFail,
          style: _RingStyle.solid,
          title: c.overrideTitle ?? '',
          hint: c.overrideHint ?? '',
        );
      case FaceScanOverride.busy:
        return _Visual(
          color: AppColors.ringActive,
          style: _RingStyle.sweep,
          title: c.overrideTitle ?? 'Memproses…',
          hint: c.overrideHint ?? '',
          spin: true,
        );
      case FaceScanOverride.none:
        break;
    }

    // Tanpa animasi berulang: di sebagian perangkat kamera butuh waktu lama.
    if (c.status == FaceCameraStatus.initializing) {
      return _Visual(
        color: AppColors.ringIdle,
        style: _RingStyle.dashed,
        title: title ?? 'Membuka kamera…',
        hint: hintOr('Sebentar, ya.'),
      );
    }
    if (c.status != FaceCameraStatus.ready) {
      return _Visual(
        color: Colors.white.withValues(alpha: 0.28),
        style: _RingStyle.solid,
        title: title ?? 'Kamera belum aktif',
        hint: hintOr(''),
      );
    }
    if (c.isCapturing) {
      return _Visual(
        color: AppColors.ringActive,
        style: _RingStyle.progress,
        progress: 1,
        title: title ?? 'Tahan sebentar',
        hint: 'Mengambil foto…',
      );
    }
    if (!c.autoMode) {
      return _Visual(
        color: AppColors.ringIdle,
        style: _RingStyle.solid,
        title: title ?? 'Posisikan wajah, lalu ambil foto',
        hint: hintOr(
          c.detectionSupported
              ? 'Pastikan seluruh wajah terlihat.'
              : 'Deteksi otomatis tidak tersedia di perangkat ini.',
        ),
      );
    }

    final guidance = c.guidance;
    switch (guidance.phase) {
      case FaceGuidancePhase.searching:
        return _Visual(
          color: AppColors.ringIdle,
          style: _RingStyle.dashed,
          title: title ?? 'Posisikan wajah di dalam bingkai',
          hint: hintOr('Pastikan seluruh wajah terlihat.'),
          spin: true,
        );
      case FaceGuidancePhase.adjusting:
        final issue = guidance.issue ?? FaceIssue.noFace;
        // Pose samping yang belum pas bukan kesalahan; pengguna sedang menuju ke sana.
        if (issue == FaceIssue.wrongPose && c.pose != FacePoseKind.front) {
          return _Visual(
            color: AppColors.ringIdle,
            style: _RingStyle.dashed,
            title: title ?? 'Ikuti arah yang diminta',
            hint: hintOr(''),
            spin: true,
          );
        }
        final (issueTitle, issueHint) = _issueCopy(issue);
        return _Visual(
          color: AppColors.ringWarn,
          style: _RingStyle.solid,
          title: issueTitle,
          hint: issueHint,
        );
      case FaceGuidancePhase.holding:
        return _Visual(
          color: AppColors.ringActive,
          style: _RingStyle.progress,
          progress: guidance.progress * (c.requireBlink ? 0.6 : 1),
          title: 'Tahan sebentar',
          hint: 'Bagus, jangan bergerak dulu.',
        );
      case FaceGuidancePhase.blink:
        return const _Visual(
          color: AppColors.ringActive,
          style: _RingStyle.progress,
          progress: 0.6,
          title: 'Kedipkan mata',
          hint: 'Sekali saja, untuk memastikan ini benar-benar kamu.',
        );
      case FaceGuidancePhase.ready:
        return const _Visual(
          color: AppColors.ringActive,
          style: _RingStyle.progress,
          progress: 1,
          title: 'Tahan sebentar',
          hint: 'Mengambil foto…',
        );
    }
  }

  static (String, String) _issueCopy(FaceIssue issue) => switch (issue) {
    FaceIssue.noFace => (
      'Posisikan wajah di dalam bingkai',
      'Pastikan seluruh wajah terlihat.',
    ),
    FaceIssue.multipleFaces => (
      'Satu wajah saja',
      'Pastikan tidak ada orang lain di dalam bingkai.',
    ),
    FaceIssue.lowLight => (
      'Cahaya kurang',
      'Cari tempat yang lebih terang atau hadap ke jendela.',
    ),
    FaceIssue.tooFar => (
      'Dekatkan wajah',
      'Wajahmu masih terlalu kecil di dalam bingkai.',
    ),
    FaceIssue.tooClose => ('Mundur sedikit', 'Wajahmu melewati bingkai.'),
    FaceIssue.offCenter => (
      'Geser ke tengah',
      'Sejajarkan wajah dengan bingkai.',
    ),
    FaceIssue.wrongPose => (
      'Hadap lurus ke kamera',
      'Tegakkan kepala dan lihat ke depan.',
    ),
  };

  static Rect _ovalFor(Size size, double topInset, bool hasFooter) {
    final top = topInset + 80;
    final bottom = hasFooter ? 64.0 : 24.0;
    final room = math.max(size.height - top - bottom, 160.0);
    var width = math.min(size.width * 0.68, 300.0);
    var height = width * 4 / 3;
    if (height > room) {
      height = room;
      width = height * 3 / 4;
    }
    return Rect.fromCenter(
      center: Offset(size.width / 2, top + room / 2),
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset =
        MediaQuery.paddingOf(context).top + FaceScanStage.topBarHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final oval = _ovalFor(size, topInset, widget.footer != null);
        widget.controller.updateGeometry(size, oval);
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => _buildStage(context, oval, topInset),
        );
      },
    );
  }

  Widget _buildStage(BuildContext context, Rect oval, double topInset) {
    final c = widget.controller;
    final visual = _visual();
    final camera = c.camera;
    final still = c.still;
    final text = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.scrim),
        if (still != null)
          Image.memory(still, fit: BoxFit.cover, gaplessPlayback: true)
        else if (c.status == FaceCameraStatus.ready && camera != null)
          _CoverPreview(camera: camera),
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: visual.color),
          duration: AppMotion.ring,
          curve: AppMotion.curve,
          builder: (context, color, _) => TweenAnimationBuilder<double>(
            tween: Tween(end: visual.progress),
            duration: AppMotion.base,
            curve: AppMotion.curve,
            builder: (context, progress, _) => AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => CustomPaint(
                painter: _RingPainter(
                  oval: oval,
                  color: color ?? visual.color,
                  progress: progress,
                  style: visual.style,
                  phase: _spin.value,
                  segments: widget.segments,
                  completed: widget.completedSegments,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: topInset + 4,
          left: AppSpacing.xxl,
          right: AppSpacing.xxl,
          child: Semantics(
            container: true,
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: AppMotion.curve,
              child: Column(
                key: ValueKey('${visual.title}|${visual.hint}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    visual.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(color: Colors.white),
                  ),
                  if (visual.hint.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      visual.hint,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.onScrimMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: oval,
          child: Center(child: _centerContent(c, text)),
        ),
        if (widget.footer != null)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: oval.bottom + AppSpacing.lg,
            child: widget.footer!,
          ),
      ],
    );
  }

  Widget _centerContent(FaceScanController c, TextTheme text) {
    if (c.overlay == FaceScanOverride.success) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.slow,
        curve: AppMotion.curve,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.ringOk,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            PhosphorIconsBold.check,
            size: 38,
            color: AppColors.scrim,
          ),
        ),
      );
    }
    if (c.overlay != FaceScanOverride.none) return const SizedBox.shrink();
    final (icon, message) = switch (c.status) {
      FaceCameraStatus.initializing => (
        PhosphorIconsRegular.camera,
        'Membuka kamera…',
      ),
      FaceCameraStatus.permissionDenied => (
        PhosphorIconsRegular.cameraSlash,
        'Izin kamera belum diberikan. Izinkan Kamera di Pengaturan, '
            'lalu coba lagi.',
      ),
      FaceCameraStatus.unavailable => (
        PhosphorIconsRegular.videoCameraSlash,
        'Kamera tidak tersedia di perangkat ini.',
      ),
      FaceCameraStatus.failed => (
        PhosphorIconsRegular.warningCircle,
        'Kamera gagal dibuka. Tutup aplikasi lain yang memakai kamera, '
            'lalu coba lagi.',
      ),
      _ => (null, ''),
    };
    if (icon == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AppColors.onScrimMuted),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.camera});

  final CameraController camera;

  @override
  Widget build(BuildContext context) {
    // previewSize dilaporkan mendatar; layar ini selalu tegak.
    final preview = camera.value.previewSize;
    return Semantics(
      label: 'Pratinjau kamera',
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: preview?.height ?? 480,
            height: preview?.width ?? 640,
            child: CameraPreview(camera),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.oval,
    required this.color,
    required this.progress,
    required this.style,
    required this.phase,
    required this.segments,
    required this.completed,
  });

  final Rect oval;
  final Color color;
  final double progress;
  final _RingStyle style;

  /// Posisi animasi berulang, 0–1.
  final double phase;
  final int segments;
  final int completed;

  static const _top = -math.pi / 2;
  static const _turn = 2 * math.pi;

  Paint _stroke(Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addOval(oval),
      Paint()..color = AppColors.scrim.withValues(alpha: 0.72),
    );

    final track = _stroke(Colors.white.withValues(alpha: 0.28));
    final pulse = (math.sin(phase * _turn) + 1) / 2;
    final pulsing = _stroke(color.withValues(alpha: 0.4 + 0.6 * pulse));

    if (segments > 1) {
      const gap = 0.12;
      final step = _turn / segments;
      for (var i = 0; i < segments; i++) {
        final start = _top + i * step + gap / 2;
        final sweep = step - gap;
        canvas.drawArc(oval, start, sweep, false, track);
        if (i < completed) {
          canvas.drawArc(oval, start, sweep, false, _stroke(AppColors.ringOk));
        } else if (i == completed) {
          switch (style) {
            case _RingStyle.progress:
              canvas.drawArc(
                oval,
                start,
                sweep * progress,
                false,
                _stroke(color),
              );
            case _RingStyle.solid:
              canvas.drawArc(oval, start, sweep, false, _stroke(color));
            case _RingStyle.dashed || _RingStyle.sweep:
              canvas.drawArc(oval, start, sweep, false, pulsing);
          }
        }
      }
      return;
    }

    switch (style) {
      case _RingStyle.dashed:
        const dashes = 56;
        for (var i = 0; i < dashes; i++) {
          canvas.drawArc(
            oval,
            _top + i * _turn / dashes,
            _turn / dashes * 0.4,
            false,
            pulsing,
          );
        }
      case _RingStyle.solid:
        canvas.drawOval(oval, _stroke(color));
      case _RingStyle.progress:
        canvas.drawOval(oval, track);
        canvas.drawArc(oval, _top, _turn * progress, false, _stroke(color));
      case _RingStyle.sweep:
        canvas.drawOval(oval, track);
        canvas.drawArc(
          oval,
          _top + phase * _turn,
          _turn * 0.28,
          false,
          _stroke(color),
        );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.oval != oval ||
      old.color != color ||
      old.progress != progress ||
      old.style != style ||
      old.phase != phase ||
      old.segments != segments ||
      old.completed != completed;
}
