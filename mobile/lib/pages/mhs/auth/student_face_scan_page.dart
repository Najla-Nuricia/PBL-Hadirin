import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mhs/dummy_student_auth_repository.dart';
import '../../../data/mhs/student_account.dart';
import '../../../routing/student_route_paths.dart';
import '../../../theme/style/auth_style.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_info_banner.dart';
import 'widgets/auth_scaffold.dart';

const _faceDirections = [
  'Hadap lurus ke depan',
  'Hadap ke kiri',
  'Hadap ke kanan',
  'Dongakkan sedikit ke atas',
  'Tundukkan sedikit ke bawah',
];

const _cameraPermissionErrorCodes = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
};

enum _CameraStatus {
  initializing,
  ready,
  permissionDenied,
  unavailable,
  failed,
}

class StudentFaceScanPage extends StatefulWidget {
  const StudentFaceScanPage({required this.draft, super.key});

  final StudentRegistrationDraft draft;

  @override
  State<StudentFaceScanPage> createState() => _StudentFaceScanPageState();
}

class _StudentFaceScanPageState extends State<StudentFaceScanPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  _CameraStatus _cameraStatus = _CameraStatus.initializing;
  bool _isInitializingCamera = false;
  bool _isCapturing = false;
  bool _isSubmitting = false;
  final List<XFile> _capturedPhotos = [];
  final List<Uint8List> _capturedBytes = [];
  final List<String> _capturedNames = [];

  bool get _isScanComplete => _capturedBytes.length >= _faceDirections.length;

  bool get _canCapture =>
      _cameraStatus == _CameraStatus.ready &&
      _controller != null &&
      !_isCapturing &&
      !_isSubmitting &&
      !_isScanComplete;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final controller = _controller;
      if (controller == null) return;
      setState(() {
        _controller = null;
        _cameraStatus = _CameraStatus.initializing;
      });
      controller.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera) return;
    _isInitializingCamera = true;
    setState(() => _cameraStatus = _CameraStatus.initializing);

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setCameraStatus(_CameraStatus.unavailable);
        return;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraStatus = _CameraStatus.ready;
      });
    } on CameraException catch (error) {
      await controller?.dispose();
      debugPrint('Camera initialization failed: ${error.code}');
      _setCameraStatus(
        _cameraPermissionErrorCodes.contains(error.code)
            ? _CameraStatus.permissionDenied
            : _CameraStatus.failed,
      );
    } catch (error) {
      // Platforms without a camera implementation (e.g. desktop) throw
      // plugin errors instead of CameraException.
      await controller?.dispose();
      debugPrint('Camera unavailable: $error');
      _setCameraStatus(_CameraStatus.unavailable);
    } finally {
      _isInitializingCamera = false;
    }
  }

  void _setCameraStatus(_CameraStatus status) {
    if (mounted) setState(() => _cameraStatus = status);
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (!_canCapture ||
        controller == null ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() => _isCapturing = true);
    XFile? photo;
    Uint8List? bytes;
    try {
      photo = await controller.takePicture();
      bytes = await photo.readAsBytes();
    } catch (error) {
      debugPrint('Taking face photo failed: $error');
    }
    if (!mounted) return;

    setState(() {
      _isCapturing = false;
      if (photo != null && bytes != null && bytes.isNotEmpty) {
        _capturedPhotos.add(photo);
        _capturedBytes.add(bytes);
        _capturedNames.add(photo.name);
      }
    });

    if (photo == null || bytes == null || bytes.isEmpty) {
      _showMessage('Gagal mengambil foto. Coba lagi.');
    } else if (_isScanComplete) {
      await _completeRegistration();
    }
  }

  Future<void> _pickPhotosFromFiles() async {
    if (_isCapturing || _isSubmitting) return;
    final remaining = _faceDirections.length - _capturedBytes.length;
    if (remaining <= 0) return;

    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );
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

    if (_isScanComplete) {
      await _completeRegistration();
    }
  }

  Future<void> _completeRegistration() async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await studentAuthRepository.register(
        widget.draft,
        facePhotoPaths: _capturedPhotos.isNotEmpty
            ? [for (final photo in _capturedPhotos) photo.path]
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
            content: Text('Registrasi berhasil. Silakan login dengan NIM kamu.'),
          ),
        );
      context.go(StudentRoutePaths.login);
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
      setState(() {
        _isSubmitting = false;
        _capturedPhotos.clear();
        _capturedBytes.clear();
        _capturedNames.clear();
      });
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('Registrasi gagal. Periksa koneksi server dan coba lagi.');
    }
  }

  void _restartScan() {
    setState(() {
      _capturedPhotos.clear();
      _capturedBytes.clear();
      _capturedNames.clear();
    });
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
    final colorScheme = Theme.of(context).colorScheme;
    final capturedCount = _capturedBytes.length;
    final totalDirections = _faceDirections.length;
    final currentDirection = _isScanComplete
        ? 'Scan wajah selesai'
        : _faceDirections[capturedCount];

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: 'Registrasi Mahasiswa',
            subtitle: 'Scan wajah',
            activeSteps: 2,
            onBack: _goBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AuthStyle.contentHorizontalPadding,
                24,
                AuthStyle.contentHorizontalPadding,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _CameraFrame(
                      status: _cameraStatus,
                      controller: _controller,
                      onRetry: _initializeCamera,
                      onPickFiles: _cameraStatus != _CameraStatus.initializing
                          ? _pickPhotosFromFiles
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentDirection,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isSubmitting
                        ? 'Menyimpan data registrasi...'
                        : 'Foto ${math.min(capturedCount + 1, totalDirections)} '
                              'dari $totalDirections',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: AuthStyle.captionSize,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AuthInfoBanner(
                    message:
                        'Arahkan kamera ke wajah dengan pencahayaan yang cukup',
                  ),
                  const SizedBox(height: 16),
                  AuthPrimaryButton(
                    label: 'Ambil Foto',
                    onPressed: _canCapture ? _capturePhoto : null,
                    isLoading: _isCapturing || _isSubmitting,
                  ),
                  if (capturedCount > 0 && !_isSubmitting) ...[
                    const SizedBox(height: 8),
                    if (!_isScanComplete)
                      OutlinedButton(
                        onPressed: _isCapturing ? null : _completeRegistration,
                        child: Text('Kirim $capturedCount Foto & Daftar'),
                      ),
                    TextButton(
                      onPressed: _isCapturing ? null : _restartScan,
                      child: const Text('Ulangi Scan'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraFrame extends StatelessWidget {
  const _CameraFrame({
    required this.status,
    required this.controller,
    required this.onRetry,
    this.onPickFiles,
  });

  final _CameraStatus status;
  final CameraController? controller;
  final VoidCallback onRetry;
  final VoidCallback? onPickFiles;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final readyController = status == _CameraStatus.ready ? controller : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AuthStyle.cameraFrameMaxWidth,
      ),
      child: AspectRatio(
        aspectRatio: AuthStyle.cameraFrameAspectRatio,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.outline,
            borderRadius: BorderRadius.circular(AuthStyle.cameraFrameRadius),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (readyController != null)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: 100,
                    height: 100 * readyController.value.aspectRatio,
                    child: CameraPreview(readyController),
                  ),
                ),
              CustomPaint(
                painter: _FaceFrameCornersPainter(
                  color: readyController != null
                      ? colorScheme.surface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              if (readyController == null)
                Center(child: _buildStatusContent(colorScheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusContent(ColorScheme colorScheme) {
    if (status == _CameraStatus.initializing) {
      return Container(
        width: 125,
        height: 125,
        decoration: BoxDecoration(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(AuthStyle.cameraFrameRadius),
          border: Border.all(color: colorScheme.onSurfaceVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 24, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              'Membuka kamera...',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: AuthStyle.captionSize,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    }

    final (icon, message) = switch (status) {
      _CameraStatus.permissionDenied => (
        Icons.no_photography_outlined,
        'Izin kamera ditolak. Aktifkan izin kamera di pengaturan, '
            'lalu coba lagi.',
      ),
      _CameraStatus.unavailable => (
        Icons.videocam_off_outlined,
        'Kamera tidak tersedia di perangkat ini.',
      ),
      _ => (Icons.error_outline, 'Kamera gagal dibuka.'),
    };

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: AuthStyle.captionSize,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          if (onPickFiles != null)
            TextButton(
              onPressed: onPickFiles,
              child: const Text('Pilih Foto Wajah'),
            ),
        ],
      ),
    );
  }
}

class _FaceFrameCornersPainter extends CustomPainter {
  const _FaceFrameCornersPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final horizontalInset = size.width * 26 / AuthStyle.cameraFrameMaxWidth;
    final frame = Rect.fromLTRB(
      horizontalInset,
      horizontalInset,
      size.width - horizontalInset,
      size.height - horizontalInset,
    );
    final cornerLength = frame.shortestSide * 0.3;
    const radius = Radius.circular(AuthStyle.cameraFrameRadius);
    final r = radius.x;

    final path = Path()
      ..moveTo(frame.left, frame.top + cornerLength)
      ..lineTo(frame.left, frame.top + r)
      ..arcToPoint(Offset(frame.left + r, frame.top), radius: radius)
      ..lineTo(frame.left + cornerLength, frame.top)
      ..moveTo(frame.right - cornerLength, frame.top)
      ..lineTo(frame.right - r, frame.top)
      ..arcToPoint(Offset(frame.right, frame.top + r), radius: radius)
      ..lineTo(frame.right, frame.top + cornerLength)
      ..moveTo(frame.right, frame.bottom - cornerLength)
      ..lineTo(frame.right, frame.bottom - r)
      ..arcToPoint(Offset(frame.right - r, frame.bottom), radius: radius)
      ..lineTo(frame.right - cornerLength, frame.bottom)
      ..moveTo(frame.left + cornerLength, frame.bottom)
      ..lineTo(frame.left + r, frame.bottom)
      ..arcToPoint(Offset(frame.left, frame.bottom - r), radius: radius)
      ..lineTo(frame.left, frame.bottom - cornerLength);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceFrameCornersPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
