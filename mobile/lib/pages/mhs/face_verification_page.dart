import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/location_service.dart';
import '../../data/mhs/student_data_service.dart';
import '../../features/face_scan/face_scan_controller.dart';
import '../../features/face_scan/face_scan_stage.dart';
import '../../features/face_scan/presensi_failure.dart';
import '../../widgets/widgets.dart';

/// Verifikasi wajah untuk presensi, layar penuh. Mengembalikan jawaban server
/// lewat `Navigator.pop` bila presensi tercatat, atau null bila dibatalkan.
class FaceVerificationPage extends StatefulWidget {
  const FaceVerificationPage({
    this.sessionId,
    this.courseName,
    this.roomName,
    this.qrToken,
    this.initialLocation,
    this.faceRegistered = true,
    super.key,
  });

  final String? sessionId;
  final String? courseName;
  final String? roomName;
  final String? qrToken;
  final DeviceLocation? initialLocation;
  final bool faceRegistered;

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  late final FaceScanController _scan = FaceScanController(
    requireBlink: true,
    onAutoCapture: _onAutoCapture,
  );

  DeviceLocation? _location;
  bool _locating = false;
  CapturedFace? _photo;
  PresensiFailure? _failure;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation;
    _scan.start();
    if (_location == null) _refreshLocation();
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  Future<void> _refreshLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final location = await locationService.currentPosition();
      if (mounted) setState(() => _location = location);
    } catch (_) {
      // Keping lokasi menunjukkan statusnya; kegagalan dilaporkan saat mengirim.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onAutoCapture(CapturedFace face) {
    if (!mounted) return;
    setState(() => _photo = face);
    _scan.still = face.bytes;
    _submit();
  }

  Future<void> _captureManually() async {
    final face = await _scan.capture();
    if (!mounted) return;
    if (face == null) {
      await _scan.resume();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Foto belum berhasil diambil. Coba lagi.'),
          ),
        );
      return;
    }
    setState(() => _photo = face);
    _scan.still = face.bytes;
  }

  Future<void> _retake() async {
    setState(() {
      _photo = null;
      _failure = null;
    });
    await _scan.resume();
  }

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null || _submitting) return;
    final location = _location;
    if (location == null) {
      _fail(PresensiFailure.locationMissing);
      return;
    }

    setState(() {
      _submitting = true;
      _failure = null;
    });
    _scan.setOverride(
      FaceScanOverride.busy,
      title: 'Memverifikasi…',
      hint: 'Mencocokkan wajah dengan data terdaftar.',
    );
    try {
      final result = await studentDataService.submitFaceAttendance(
        imageBytes: photo.bytes,
        filename: photo.name,
        sesiPresensiId: widget.sessionId,
        qrToken: widget.qrToken,
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
      );
      if (!mounted) return;
      _scan.setOverride(
        FaceScanOverride.success,
        title: 'Wajah terverifikasi',
        hint: 'Presensi kamu sudah tercatat.',
      );
      HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) _fail(PresensiFailure.from(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _fail(PresensiFailure failure) {
    setState(() => _failure = failure);
    _scan.setOverride(FaceScanOverride.failure);
    HapticFeedback.lightImpact();
  }

  Future<void> _recover() async {
    final failure = _failure;
    if (failure == null) return;
    switch (failure.recovery) {
      case PresensiRecovery.rescan:
        await _retake();
      case PresensiRecovery.resend:
        await _submit();
      case PresensiRecovery.refreshLocation:
        setState(() => _failure = null);
        _scan.setOverride(
          FaceScanOverride.busy,
          title: 'Memperbarui lokasi…',
          hint: 'Fotomu tetap tersimpan.',
        );
        await _refreshLocation();
        if (mounted) await _submit();
      case PresensiRecovery.leave:
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final failure = _failure;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: AppColors.scrim,
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FaceScanStage(
                      controller: _scan,
                      footer: _buildChips(),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: FaceScanStage.topBarHeight,
                      child: Row(
                        children: [
                          const SizedBox(width: AppSpacing.xs),
                          _ScrimIconButton(
                            icon: PhosphorIconsRegular.arrowLeft,
                            tooltip: 'Kembali',
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              'Scan Wajah',
                              textAlign: TextAlign.center,
                              style: text.titleSmall?.copyWith(
                                color: AppColors.onScrimMuted,
                              ),
                            ),
                          ),
                          ListenableBuilder(
                            listenable: _scan,
                            builder: (context, _) =>
                                _scan.canSwitchLens && _photo == null
                                ? _ScrimIconButton(
                                    icon: PhosphorIconsRegular.cameraRotate,
                                    tooltip: 'Ganti kamera',
                                    onPressed: _scan.switchLens,
                                  )
                                : const SizedBox(width: AppSizes.touch),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: AppMotion.base,
              curve: AppMotion.curve,
              alignment: Alignment.bottomCenter,
              child: failure != null
                  ? _FailurePanel(
                      failure: failure,
                      onRecover: _recover,
                      onLeave: () => Navigator.of(context).pop(),
                    )
                  : SafeArea(top: false, child: _buildControls(text)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips() {
    final location = _location;
    final course = widget.courseName;
    final room = widget.roomName;
    final (icon, color, label) = _locating
        ? (PhosphorIconsRegular.crosshair, Colors.white, 'Mencari lokasi…')
        : location != null
        ? (
            PhosphorIconsRegular.mapPin,
            AppColors.ringOk,
            'Lokasi terdeteksi · ${location.formattedAccuracy}',
          )
        : (
            PhosphorIconsRegular.gpsSlash,
            AppColors.ringFail,
            'Lokasi belum terdeteksi',
          );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _ScanChip(icon: icon, iconColor: color, label: label),
        if (room != null && room.isNotEmpty)
          _ScanChip(
            icon: PhosphorIconsRegular.door,
            iconColor: Colors.white,
            label: room,
          ),
        if (course != null && course.isNotEmpty)
          _ScanChip(
            icon: PhosphorIconsRegular.bookOpen,
            iconColor: Colors.white,
            label: course,
          ),
      ],
    );
  }

  Widget _buildControls(TextTheme text) {
    final onScrim = FilledButton.styleFrom(
      disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
      disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
    );

    return ListenableBuilder(
      listenable: _scan,
      builder: (context, _) {
        final ready = _scan.status == FaceCameraStatus.ready;
        final opening = _scan.status == FaceCameraStatus.initializing;
        final photo = _photo;
        final List<Widget> actions;

        if (_scan.autoMode && ready) {
          // Panduan otomatis: status tampil di atas, di sini hanya jalan keluar.
          actions = photo != null
              ? const [SizedBox(height: AppSizes.touch)]
              : [
                  Text(
                    'Wajah belum terdeteksi juga?',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.onScrimMuted,
                    ),
                  ),
                  TextButton(
                    onPressed: _scan.useManual,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Ambil foto manual'),
                  ),
                ];
        } else {
          actions = [
            FilledButton.tonalIcon(
              style: onScrim,
              onPressed: _submitting || opening
                  ? null
                  : !ready
                  ? _scan.retryCamera
                  : photo != null
                  ? _retake
                  : _scan.canCapture
                  ? _captureManually
                  : null,
              icon: Icon(
                !ready
                    ? PhosphorIconsRegular.videoCamera
                    : photo != null
                    ? PhosphorIconsRegular.arrowsClockwise
                    : PhosphorIconsRegular.camera,
              ),
              label: Text(
                !ready
                    ? 'Coba Buka Kamera Lagi'
                    : photo != null
                    ? 'Ambil ulang foto'
                    : 'Ambil foto wajah',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              style: onScrim,
              onPressed: photo != null && !_submitting ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim Verifikasi Wajah'),
            ),
          ];
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.faceRegistered) ...[
                const AppBanner(
                  tone: StatusTone.warning,
                  message:
                      'Data wajah belum terdaftar di akun ini, sehingga '
                      'verifikasi bisa ditolak.',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              ...actions,
            ],
          ),
        );
      },
    );
  }
}

class _ScrimIconButton extends StatelessWidget {
  const _ScrimIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
        backgroundColor: AppColors.scrim.withValues(alpha: 0.45),
      ),
    );
  }
}

class _ScanChip extends StatelessWidget {
  const _ScanChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.scrim.withValues(alpha: 0.6),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({
    required this.failure,
    required this.onRecover,
    required this.onLeave,
  });

  final PresensiFailure failure;
  final VoidCallback onRecover;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xxl,
              AppSpacing.page,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    failure.icon,
                    size: 32,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(failure.title, style: text.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  failure.message,
                  style: text.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: onRecover,
                  child: Text(failure.actionLabel),
                ),
                if (failure.recovery != PresensiRecovery.leave)
                  TextButton(onPressed: onLeave, child: const Text('Kembali')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
