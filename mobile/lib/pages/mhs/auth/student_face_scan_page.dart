import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mhs/dummy_student_auth_repository.dart';
import '../../../data/mhs/student_account.dart';
import '../../../features/face_scan/face_guidance.dart';
import '../../../features/face_scan/face_scan_controller.dart';
import '../../../features/face_scan/face_scan_stage.dart';
import '../../../routing/student_route_paths.dart';
import '../../../widgets/widgets.dart';

const _poses = [
  (FacePoseKind.front, 'Hadap lurus ke depan'),
  (FacePoseKind.turnFirst, 'Hadap ke kiri'),
  (FacePoseKind.turnSecond, 'Hadap ke kanan'),
  (FacePoseKind.pitchFirst, 'Dongakkan sedikit ke atas'),
  (FacePoseKind.pitchSecond, 'Tundukkan sedikit ke bawah'),
];

/// Langkah kedua registrasi: lima foto wajah dari arah berbeda. Foto diambil
/// otomatis saat pose pas, atau manual lewat tombol.
class StudentFaceScanPage extends StatefulWidget {
  const StudentFaceScanPage({required this.draft, super.key});

  final StudentRegistrationDraft draft;

  @override
  State<StudentFaceScanPage> createState() => _StudentFaceScanPageState();
}

class _StudentFaceScanPageState extends State<StudentFaceScanPage> {
  late final FaceScanController _scan = FaceScanController(
    onAutoCapture: _addCapture,
  );

  bool _isSubmitting = false;
  final List<String> _photoPaths = [];
  final List<Uint8List> _capturedBytes = [];
  final List<String> _capturedNames = [];

  bool get _isScanComplete => _capturedBytes.length >= _poses.length;

  bool get _canCapture =>
      _scan.canCapture && !_isSubmitting && !_isScanComplete;

  @override
  void initState() {
    super.initState();
    _scan.start();
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  void _addCapture(CapturedFace face) {
    if (!mounted) return;
    setState(() {
      final path = face.path;
      if (path != null) _photoPaths.add(path);
      _capturedBytes.add(face.bytes);
      _capturedNames.add(face.name);
    });
    HapticFeedback.selectionClick();
    if (_isScanComplete) {
      _completeRegistration();
    } else {
      _scan.setPose(_poses[_capturedBytes.length].$1);
      _scan.resume();
    }
  }

  Future<void> _capturePhoto() async {
    if (!_canCapture) return;
    final face = await _scan.capture();
    if (!mounted) return;
    if (face == null) {
      await _scan.resume();
      _showMessage('Gagal mengambil foto. Coba lagi.');
      return;
    }
    _addCapture(face);
  }

  Future<void> _pickPhotosFromFiles() async {
    if (_scan.isCapturing || _isSubmitting) return;
    final remaining = _poses.length - _capturedBytes.length;
    if (remaining <= 0) return;

    final result = await FilePicker.pickFiles(type: FileType.image);
    if (!mounted || result.isEmpty) return;

    final addedBytes = <Uint8List>[];
    final addedNames = <String>[];
    for (final file in result.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        addedBytes.add(bytes);
        addedNames.add(file.name);
      }
    }
    if (!mounted) return;
    if (addedBytes.isEmpty) {
      _showMessage('File foto tidak dapat dibaca.');
      return;
    }

    setState(() {
      _capturedBytes.addAll(addedBytes);
      _capturedNames.addAll(addedNames);
    });
    if (_isScanComplete) await _completeRegistration();
  }

  Future<void> _completeRegistration() async {
    setState(() => _isSubmitting = true);
    _scan.setOverride(
      FaceScanOverride.busy,
      title: 'Menyimpan data registrasi…',
      hint: 'Sebentar, ya.',
    );
    final messenger = ScaffoldMessenger.of(context);

    try {
      await studentAuthRepository.register(
        widget.draft,
        facePhotoPaths: _photoPaths.isNotEmpty
            ? List<String>.unmodifiable(_photoPaths)
            : List<String>.unmodifiable(_capturedNames),
        facePhotoBytes: _capturedBytes.isNotEmpty
            ? List<Uint8List>.unmodifiable(_capturedBytes)
            : null,
      );
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Registrasi berhasil. Silakan login dengan NIM kamu.',
            ),
          ),
        );
      context.go(StudentRoutePaths.login);
    } on NimNotWhitelistedException {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('NIM belum terdaftar dalam whitelist admin.');
    } on NimAlreadyRegisteredException {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'NIM ${widget.draft.nim} sudah terdaftar. Silakan login.',
            ),
          ),
        );
      context.go(StudentRoutePaths.login);
    } on RemoteApiException catch (error) {
      if (!mounted) return;
      // Server menolak fotonya; scan diulang dari awal.
      setState(() => _isSubmitting = false);
      _restartScan();
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      // Foto tetap tersimpan supaya bisa dikirim ulang tanpa memindai lagi.
      setState(() => _isSubmitting = false);
      _scan.setOverride(FaceScanOverride.none);
      _showMessage('Registrasi gagal. Periksa koneksi server dan coba lagi.');
    }
  }

  void _restartScan() {
    setState(() {
      _photoPaths.clear();
      _capturedBytes.clear();
      _capturedNames.clear();
    });
    _scan.setPose(_poses.first.$1);
    _scan.resume(clearPoseMemory: true);
  }

  void _goBack() {
    if (_isSubmitting) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(StudentRoutePaths.register);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = _capturedBytes.length;
    final total = _poses.length;

    return PopScope(
      canPop: !_isSubmitting,
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
                      title: _isScanComplete
                          ? 'Scan wajah selesai'
                          : _poses[count].$2,
                      hint: 'Foto ${math.min(count + 1, total)} dari $total',
                      segments: total,
                      completedSegments: count,
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: FaceScanStage.topBarHeight,
                      child: Row(
                        children: [
                          const SizedBox(width: AppSpacing.xs),
                          IconButton(
                            onPressed: _isSubmitting ? null : _goBack,
                            tooltip: 'Kembali',
                            icon: const Icon(PhosphorIconsRegular.arrowLeft),
                            style: _scrimIconStyle,
                          ),
                          Expanded(
                            child: Text(
                              'Scan wajah',
                              textAlign: TextAlign.center,
                              style: text.titleSmall?.copyWith(
                                color: AppColors.onScrimMuted,
                              ),
                            ),
                          ),
                          ListenableBuilder(
                            listenable: _scan,
                            builder: (context, _) =>
                                _scan.canSwitchLens && !_isSubmitting
                                ? IconButton(
                                    onPressed: _scan.switchLens,
                                    tooltip: 'Ganti kamera',
                                    icon: const Icon(
                                      PhosphorIconsRegular.cameraRotate,
                                    ),
                                    style: _scrimIconStyle,
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
            SafeArea(
              top: false,
              child: ListenableBuilder(
                listenable: _scan,
                builder: (context, _) => _buildControls(text, count),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _scrimIconStyle = IconButton.styleFrom(
    foregroundColor: Colors.white,
    disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
    backgroundColor: AppColors.scrim.withValues(alpha: 0.45),
  );

  Widget _buildControls(TextTheme text, int count) {
    final status = _scan.status;
    final cameraProblem =
        status != FaceCameraStatus.ready &&
        status != FaceCameraStatus.initializing;
    final onScrimOutline = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
    );

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
          if (cameraProblem) ...[
            FilledButton.tonal(
              onPressed: _scan.retryCamera,
              child: const Text('Coba Lagi'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              style: onScrimOutline,
              onPressed: _isSubmitting ? null : _pickPhotosFromFiles,
              child: const Text('Pilih Foto Wajah'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else if (_scan.autoMode && !_isScanComplete) ...[
            Text(
              'Foto diambil otomatis saat posisi pas.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: AppColors.onScrimMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          FilledButton(
            style: FilledButton.styleFrom(
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
            ),
            onPressed: _canCapture ? _capturePhoto : null,
            child: _scan.isCapturing || _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Ambil Foto'),
          ),
          if (count > 0 && !_isSubmitting) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              style: onScrimOutline,
              onPressed: _scan.isCapturing ? null : _completeRegistration,
              child: Text('Kirim $count Foto & Daftar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: _scan.isCapturing ? null : _restartScan,
              child: const Text('Ulangi Scan'),
            ),
          ],
        ],
      ),
    );
  }
}
