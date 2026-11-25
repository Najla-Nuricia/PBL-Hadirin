import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/location_service.dart';
import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_data_service.dart';
import '../../routing/student_route_paths.dart';

enum _CameraStatus {
  idle,
  initializing,
  ready,
  unavailable,
  permissionDenied,
  failed,
}

const _cameraPermissionErrorCodes = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
  'AudioAccessDenied',
  'AudioAccessDeniedWithoutPrompt',
  'AudioAccessRestricted',
  'permissionDenied',
  'NotAllowedError',
};

/// Halaman presensi dua tahap: validasi sesi QR + GPS kampus dan verifikasi wajah via kamera.
class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Koordinat perangkat diambil dari GPS asli (lihat LocationService).
  int _currentStep = 0; // 0 = Scan/Token QR, 1 = Verifikasi Wajah (Kamera)
  bool _isLoadingSessions = false;
  bool _isSubmitting = false;
  bool _isCapturing = false;
  bool _isInitializingCamera = false;
  bool _attendanceDone = false;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _preferredLens = CameraLensDirection.front;
  _CameraStatus _cameraStatus = _CameraStatus.idle;

  List<Map<String, dynamic>> _activeSessions = const [];
  String? _selectedSessionId;
  bool _faceRegistered = true;

  bool _isRoomVerified = false;
  String? _verifiedRoomToken;
  String? _verifiedRoomKode;
  String? _verifiedRoomName;
  String? _verifiedCourseName;
  final _manualTokenController = TextEditingController();
  bool _showManualToken = false;

  Uint8List? _probeImageBytes;
  String? _probeImageName;
  String? _statusMessage;
  String? _errorMessage;

  DeviceLocation? _location;
  bool _isLocating = false;
  String? _locationError;

  MobileScannerController? _qrScanner;
  bool _isStartingQrScanner = false;
  String? _qrScannerError;
  String? _handledQrToken;

  // Di lingkungan flutter test plugin scanner tidak tersedia, jadi jangan mount.
  bool get _isFlutterTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadInitialData();
    _refreshLocation();
    _startQrScanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      if (_currentStep == 0) {
        _stopQrScanner();
      } else {
        _disposeCamera();
      }
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    _refreshLocation();
    if (_attendanceDone) return;
    if (_currentStep == 0) {
      _startQrScanner();
    } else if (_cameraController == null) {
      _initializeCamera();
    }
  }

  void _setSubmitting(bool value) {
    if (value) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
    setState(() => _isSubmitting = value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera(notify: false);
    _qrScanner?.dispose();
    _qrScanner = null;
    _pulseController.dispose();
    _manualTokenController.dispose();
    super.dispose();
  }

  Future<void> _disposeCamera({bool notify = true}) async {
    final controller = _cameraController;
    if (controller == null) return;
    _cameraController = null;
    if (notify && mounted) {
      setState(() => _cameraStatus = _CameraStatus.idle);
    }
    await controller.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera) return;
    _isInitializingCamera = true;
    await _disposeCamera(notify: false);
    if (mounted) {
      setState(() => _cameraStatus = _CameraStatus.initializing);
    }

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setCameraStatus(_CameraStatus.unavailable);
        return;
      }
      _cameras = cameras;

      final preferred = cameras
          .where((c) => c.lensDirection == _preferredLens)
          .toList();
      final candidates = [
        ...preferred,
        ...cameras.where((c) => !preferred.contains(c)),
      ];

      CameraException? lastCameraError;
      for (final candidate in candidates) {
        for (final preset in const [
          ResolutionPreset.medium,
          ResolutionPreset.low,
          ResolutionPreset.high,
        ]) {
          CameraController? candidateController;
          try {
            candidateController = CameraController(
              candidate,
              preset,
              enableAudio: false,
            );
            await candidateController.initialize();
            if (!mounted || _currentStep != 1) {
              await candidateController.dispose();
              return;
            }
            controller = candidateController;
            setState(() {
              _cameraController = candidateController;
              _cameraStatus = _CameraStatus.ready;
              _errorMessage = null;
            });
            return;
          } on CameraException catch (e) {
            lastCameraError = e;
            await candidateController?.dispose();
          }
        }
      }

      if (lastCameraError != null) {
        throw lastCameraError;
      }
    } on CameraException catch (error) {
      await controller?.dispose();
      debugPrint('Attendance camera initialization failed: ${error.code}');
      if (_cameraPermissionErrorCodes.contains(error.code)) {
        _setCameraStatus(_CameraStatus.permissionDenied);
        setState(() {
          _errorMessage = 'Izin kamera belum aktif. Berikan izin kamera di browser/perangkat lalu tekan Coba Buka Kamera Lagi.';
        });
      } else if (error.code == 'cameraNotFound') {
        _setCameraStatus(_CameraStatus.unavailable);
        setState(() {
          _errorMessage = 'Kamera tidak terdeteksi (cameraNotFound). Pastikan webcam terhubung dan diizinkan.';
        });
      } else {
        _setCameraStatus(_CameraStatus.failed);
        setState(() {
          _errorMessage =
              'Kamera gagal dibuka (${error.code}). Pastikan kamera tidak dipakai aplikasi lain lalu coba lagi.';
        });
      }
    } catch (error) {
      await controller?.dispose();
      debugPrint('Attendance camera unavailable on this platform: $error');
      _setCameraStatus(_CameraStatus.unavailable);
      setState(() {
        _errorMessage = 'Kamera tidak tersedia di platform ini.';
      });
    } finally {
      _isInitializingCamera = false;
    }
  }

  void _setCameraStatus(_CameraStatus status) {
    if (mounted) setState(() => _cameraStatus = status);
  }

  Future<void> _switchCameraLens() async {
    _preferredLens = _preferredLens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _initializeCamera();
  }

  Future<void> _captureFromCamera() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        _showSnackBar('Hasil foto kamera kosong.');
        return;
      }
      setState(() {
        _probeImageBytes = bytes;
        _probeImageName = photo.name.isNotEmpty ? photo.name : 'capture.jpg';
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengambil foto dari kamera: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingSessions = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        studentDataService.loadActiveSessions(),
        studentDataService.getFaceStatus(),
      ]);
      if (!mounted) return;
      final sessions = results[0] as List<Map<String, dynamic>>;
      final faceStatus = results[1] as Map<String, dynamic>;
      setState(() {
        _activeSessions = sessions;
        if (sessions.isNotEmpty && _selectedSessionId == null) {
          _selectedSessionId = sessions.first['sesi_presensi_id'] as String?;
        }
        _faceRegistered = (faceStatus['is_registered'] as bool?) ?? false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshLocation() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      final location = await locationService.currentPosition();
      if (!mounted) return;
      setState(() {
        _location = location;
        _locationError = null;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = 'Gagal membaca lokasi: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _startQrScanner() async {
    if (_isFlutterTest) return;
    if (_qrScanner != null || _isStartingQrScanner) return;
    _isStartingQrScanner = true;
    final scanner = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    if (mounted) {
      setState(() {
        _qrScanner = scanner;
        _qrScannerError = null;
      });
    }
    try {
      // Tunggu widget MobileScanner ter-mount & attach ke controller.
      await WidgetsBinding.instance.endOfFrame;
      await scanner.start();
      if (!mounted) return;
      setState(() => _qrScannerError = null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _qrScannerError = 'Kamera pemindai QR tidak tersedia. Periksa izin kamera lalu coba lagi.';
        _qrScanner = null;
      });
      await Future<void>.delayed(Duration.zero);
      await scanner.dispose();
    } finally {
      _isStartingQrScanner = false;
    }
  }

  Future<void> _stopQrScanner({bool notify = true}) async {
    final scanner = _qrScanner;
    if (scanner == null) return;
    if (notify && mounted) {
      setState(() => _qrScanner = null);
      // Beri satu frame agar widget MobileScanner lepas dari controller.
      await Future<void>.delayed(Duration.zero);
    } else {
      _qrScanner = null;
    }
    await scanner.dispose();
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_isSubmitting || _attendanceDone || _isRoomVerified) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      final token = _extractQrToken(raw);
      if (token.isEmpty || token == _handledQrToken) continue;
      _handledQrToken = token;
      _validateDoorQr(token);
      return;
    }
  }

  /// QR bisa berisi token mentah, URL (`?token=...`), atau JSON (`qr_token`).
  String _extractQrToken(String raw) {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasQuery) {
      for (final key in const ['qr_token', 'token', 'code']) {
        final value = uri.queryParameters[key]?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          for (final key in const ['qr_token', 'token', 'code']) {
            final value = decoded[key];
            if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }
        }
      } catch (_) {}
    }
    return trimmed;
  }

  Future<void> _validateDoorQr(String qrToken) async {
    final location = _location;
    setState(() {
      _errorMessage = null;
    });
    _setSubmitting(true);
    try {
      final res = await studentDataService.validateRoomQr(
        qrToken: qrToken,
        latitude: location?.latitude,
        longitude: location?.longitude,
        accuracy: location?.accuracy,
      );
      if (!mounted) return;
      await _stopQrScanner();
      if (!mounted) return;

      final roomKode = (res['ruangan_kode'] as String?) ?? '';
      final roomNama = (res['ruangan_nama'] as String?) ?? roomKode;
      final courseNama = (res['matkul_nama'] as String?) ?? '';
      final sessionId = res['sesi_presensi_id'] as String?;
      final msg = (res['message'] as String?) ?? 'Pintu ruangan berhasil diverifikasi!';

      setState(() {
        _isRoomVerified = true;
        _verifiedRoomToken = qrToken;
        _verifiedRoomKode = roomKode;
        _verifiedRoomName = roomNama;
        _verifiedCourseName = courseNama;
        if (sessionId != null && sessionId.isNotEmpty) {
          _selectedSessionId = sessionId;
        }
        _statusMessage = msg;
        _errorMessage = null;
      });
      _showSnackBar(msg);

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _currentStep == 0 && _isRoomVerified) {
          _proceedToFaceStep();
        }
      });
    } catch (e) {
      if (!mounted) return;
      final msg = _cleanError(e);
      _handledQrToken = null;
      setState(() {
        _isRoomVerified = false;
        _errorMessage = msg;
      });
      _showSnackBar(msg);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  void _proceedToFaceStep() {
    if (!_isRoomVerified && !_isFlutterTest) {
      const msg = 'Pindai QR di pintu ruangan kelas Anda terlebih dahulu untuk membuka verifikasi wajah.';
      _showSnackBar(msg);
      setState(() => _errorMessage = msg);
      return;
    }
    _stopQrScanner();
    setState(() {
      _currentStep = 1;
      _errorMessage = null;
      _attendanceDone = false;
      _statusMessage = null;
    });
    _initializeCamera();
  }

  Future<void> _submitFaceAttendance() async {
    if (_probeImageBytes == null || _probeImageBytes!.isEmpty) {
      setState(
        () => _errorMessage = 'Ambil foto wajah dari kamera terlebih dahulu.',
      );
      return;
    }
    final location = _location;
    if (location == null) {
      setState(
        () => _errorMessage = 'Lokasi belum terdeteksi. Aktifkan GPS lalu tekan Muat Ulang Lokasi.',
      );
      return;
    }
    final effectiveSessionId =
        _selectedSessionId ??
        (_activeSessions.isNotEmpty
            ? _activeSessions.first['sesi_presensi_id'] as String?
            : null);

    setState(() => _errorMessage = null);
    _setSubmitting(true);
    try {
      final res = await studentDataService.submitFaceAttendance(
        imageBytes: _probeImageBytes!,
        filename: _probeImageName ?? 'probe.jpg',
        sesiPresensiId: effectiveSessionId,
        qrToken: _verifiedRoomToken,
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
      );
      if (!mounted) return;
      final sim = res['similarity'] ?? res['similarity_score'];
      final simSuffix = sim is num
          ? ' (kemiripan ${(sim * 100).toStringAsFixed(1)}%)'
          : '';
      await _disposeCamera();
      if (!mounted) return;
      setState(() {
        _attendanceDone = true;
        _statusMessage =
            '${(res['message'] as String?) ?? 'Presensi wajah berhasil!'}$simSuffix';
      });
      _showSnackBar(_statusMessage!);
    } catch (e) {
      if (!mounted) return;
      final msg = _cleanError(e);
      setState(() => _errorMessage = msg);
      _showSnackBar(msg);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(colorScheme),
            _buildStepper(colorScheme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInitialData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildScanArea(colorScheme),
                      const SizedBox(height: 16),
                      _buildStatusBanner(colorScheme),

                      if (_currentStep == 0) ...[
                        const SizedBox(height: 16),
                        _buildRoomStatusCard(colorScheme),
                        const SizedBox(height: 12),
                        _buildManualTokenSection(colorScheme),
                        const SizedBox(height: 12),
                        _buildSessionSelector(colorScheme),
                        if (_qrScannerError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _qrScannerError!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _isStartingQrScanner
                                ? null
                                : _startQrScanner,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Coba Buka Pemindai QR'),
                          ),
                        ],
                      ] else if (!_attendanceDone) ...[
                        const SizedBox(height: 16),
                        _buildVerifiedRoomBadge(colorScheme),
                        const SizedBox(height: 14),
                        _buildFacePreviewCard(colorScheme),
                      ],
                      const SizedBox(height: 16),
                      _buildLocationCard(colorScheme),
                      const SizedBox(height: 20),
                      _buildActionButtons(colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Container(
      height: 52,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: colorScheme.onSurfaceVariant,
            onPressed: () {
              if (_currentStep == 1 && !_attendanceDone) {
                _disposeCamera();
                setState(() {
                  _currentStep = 0;
                  _errorMessage = null;
                });
                _startQrScanner();
              } else {
                context.go(StudentRoutePaths.beranda);
              }
            },
            tooltip: 'Kembali',
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Absensi',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' - ${_currentStep == 0 ? 'Scan QR' : 'Scan Wajah'}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: colorScheme.onSurfaceVariant,
            onPressed: _isLoadingSessions ? null : _loadInitialData,
            tooltip: 'Muat ulang sesi',
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          _StepIndicatorItem(
            stepNumber: 1,
            label: '1. QR Pintu',
            isActive: _currentStep == 0,
            isDone: _isRoomVerified || _currentStep > 0 || _attendanceDone,
            colorScheme: colorScheme,
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: _isRoomVerified || _currentStep > 0 || _attendanceDone
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          _StepIndicatorItem(
            stepNumber: 2,
            label: '2. Scan Wajah',
            isActive: _currentStep == 1,
            isDone: _currentStep == 1 && _attendanceDone,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildScanArea(ColorScheme colorScheme) {
    final isDone = _attendanceDone;
    final qrScanner = _currentStep == 0 && !isDone ? _qrScanner : null;
    final showQrScanner = qrScanner != null;
    final showLiveCamera =
        _currentStep == 1 &&
        !isDone &&
        _probeImageBytes == null &&
        _cameraStatus == _CameraStatus.ready &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;

    return Container(
      width: double.infinity,
      height: (showLiveCamera || showQrScanner) ? 290 : 210,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? colorScheme.secondary : colorScheme.outlineVariant,
          width: isDone ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showQrScanner)
            Positioned.fill(
              child: MobileScanner(
                controller: qrScanner,
                fit: BoxFit.cover,
                onDetect: _onQrDetected,
                errorBuilder: (context, error) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Text(
                      'Kamera pemindai QR tidak tersedia.',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                placeholderBuilder: (context) =>
                    ColoredBox(color: colorScheme.surfaceContainerHighest),
              ),
            )
          else if (showLiveCamera)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 320,
                  height: _cameraController!.value.previewSize?.width ?? 240,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _isSubmitting ? _pulseAnimation.value : 1.0,
              child: child,
            ),
            child: Container(
              width: (showLiveCamera || showQrScanner) ? 180 : 150,
              height: (showLiveCamera || showQrScanner) ? 180 : 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDone
                      ? colorScheme.secondary
                      : (showLiveCamera || showQrScanner)
                      ? Colors.white70
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(
                  showLiveCamera
                      ? 90
                      : showQrScanner
                      ? 24
                      : 14,
                ),
              ),
              child: (showLiveCamera || showQrScanner)
                  ? null
                  : Center(
                      child: isDone
                          ? Icon(
                              Icons.check_circle_outline,
                              color: colorScheme.secondary,
                              size: 52,
                            )
                          : (_currentStep == 1 && _probeImageBytes != null)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _probeImageBytes!,
                                fit: BoxFit.cover,
                                width: 146,
                                height: 146,
                              ),
                            )
                          : _currentStep == 1 &&
                                _cameraStatus == _CameraStatus.initializing
                          ? const CircularProgressIndicator(strokeWidth: 2.5)
                          : (_currentStep == 1 &&
                                (_cameraStatus == _CameraStatus.unavailable ||
                                    _cameraStatus == _CameraStatus.failed ||
                                    _cameraStatus ==
                                        _CameraStatus.permissionDenied))
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_off_outlined,
                                  color: colorScheme.error,
                                  size: 38,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Kamera Tidak Aktif',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Icon(
                              _currentStep == 0
                                  ? Icons.qr_code_scanner
                                  : Icons.face_retouching_natural,
                              color: colorScheme.primary.withValues(
                                alpha: 0.65,
                              ),
                              size: 52,
                            ),
                    ),
            ),
          ),
          if (showLiveCamera && _cameras.length > 1)
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black54,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.cameraswitch_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: _switchCameraLens,
                  tooltip: 'Ganti Kamera',
                ),
              ),
            ),
          if (showQrScanner && !_isSubmitting)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Arahkan kamera ke QR',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_isSubmitting)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Memproses ke server...',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(ColorScheme colorScheme) {
    final cameraHint = switch (_cameraStatus) {
      _CameraStatus.initializing => 'Membuka kamera perangkat...',
      _CameraStatus.permissionDenied => 'Izin kamera belum aktif. Berikan izin kamera di browser/perangkat lalu tekan Coba Buka Kamera Lagi.',
      _CameraStatus.unavailable => 'Kamera langsung tidak terdeteksi (cameraNotFound). Pastikan webcam terhubung dan diizinkan.',
      _CameraStatus.failed => 'Kamera gagal dibuka. Pastikan kamera tidak dipakai aplikasi lain lalu tekan Coba Buka Kamera Lagi.',
      _CameraStatus.ready =>
        _probeImageBytes == null
            ? 'Arahkan wajah ke bingkai kamera lalu tekan Ambil Foto Wajah'
            : 'Foto wajah siap dikirim untuk verifikasi MobileFaceNet',
      _CameraStatus.idle => 'Siapkan verifikasi wajah via kamera',
    };

    final message =
        _errorMessage ??
        _statusMessage ??
        (_currentStep == 0
            ? (_isRoomVerified
                  ? 'Pintu Ruangan Terverifikasi! Kunci presensi wajah telah terbuka.'
                  : (_qrScanner == null
                        ? 'Pemindai QR tidak aktif. Pindai QR di pintu kelas atau gunakan input kode manual.'
                        : 'Arahkan kamera ke QR Code di pintu ruangan kelas Anda'))
            : cameraHint);
    final isError = _errorMessage != null;
    final isSuccess = !isError && _attendanceDone;

    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isError
            ? colorScheme.error
            : (isSuccess
                  ? colorScheme.secondary
                  : colorScheme.onSurfaceVariant),
        fontSize: 13,
        fontWeight: (isError || isSuccess) ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildRoomStatusCard(ColorScheme colorScheme) {
    if (_isRoomVerified) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.secondary),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colorScheme.secondary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PINTU RUANGAN TERVERIFIKASI',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSecondaryContainer,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_verifiedRoomName ?? 'Ruangan'} (${_verifiedRoomKode ?? '-'})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  if (_verifiedCourseName != null && _verifiedCourseName!.isNotEmpty)
                    Text(
                      'Mata Kuliah: $_verifiedCourseName',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSecondaryContainer.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.meeting_room_outlined, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Langkah 1: Pindai QR Pintu Kelas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pindai QR Code statis pada pintu kelas ruangan Anda. Fitur verifikasi wajah selfie akan terbuka setelah pintu ruangan sesuai.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTokenSection(ColorScheme colorScheme) {
    if (_isRoomVerified) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _showManualToken = !_showManualToken),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showManualToken ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _showManualToken
                      ? 'Tutup Input Manual Kode Ruangan'
                      : 'Kamera bermasalah? Masukkan kode ruangan manual',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showManualToken) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualTokenController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: RT01 atau RPL1',
                    labelText: 'Kode / Token Ruangan',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        final text = _manualTokenController.text.trim();
                        if (text.isEmpty) {
                          _showSnackBar('Masukkan kode atau token ruangan.');
                          return;
                        }
                        _validateDoorQr(text);
                      },
                child: const Text('Validasi'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVerifiedRoomBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: colorScheme.secondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ruangan: ${_verifiedRoomName ?? 'Kelas'} (${_verifiedRoomKode ?? '-'})'
              '${_verifiedCourseName != null && _verifiedCourseName!.isNotEmpty ? ' • $_verifiedCourseName' : ''}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSelector(ColorScheme colorScheme) {
    if (_isLoadingSessions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_activeSessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          studentAuthRepository.hasRemoteSession
              ? 'Belum ada sesi presensi aktif untuk kelas kamu saat ini.'
              : 'Mode pratinjau: masuk untuk melihat sesi aktif dari server.',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      );
    }

    final validSelection =
        _activeSessions.any((s) => s['sesi_presensi_id'] == _selectedSessionId)
        ? _selectedSessionId
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(validSelection),
      initialValue: validSelection,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Sesi Presensi Aktif',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: _activeSessions.map((session) {
        final id = session['sesi_presensi_id'] as String;
        final matkul = (session['matkul_nama'] as String?) ?? '-';
        final jam = (session['jam_mulai'] as String?) ?? '';
        final ruang = (session['ruangan_nama'] as String?) ?? '';
        final subtitle = [jam, ruang].where((s) => s.isNotEmpty).join(' • ');
        return DropdownMenuItem(
          value: id,
          child: Text(
            subtitle.isNotEmpty ? '$matkul ($subtitle)' : matkul,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedSessionId = val),
    );
  }

  Widget _buildFacePreviewCard(ColorScheme colorScheme) {
    final cameraReady =
        _cameraStatus == _CameraStatus.ready &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_faceRegistered && studentAuthRepository.hasRemoteSession)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Perhatian: data wajah belum terdaftar di akun ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (_probeImageBytes == null && cameraReady)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.icon(
              onPressed: (_isSubmitting || _isCapturing)
                  ? null
                  : _captureFromCamera,
              icon: _isCapturing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(
                _isCapturing ? 'Mengambil foto...' : 'Ambil Foto Wajah',
              ),
            ),
          )
        else if (_probeImageBytes != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _probeImageBytes = null;
                        _probeImageName = null;
                      });
                      if (_cameraController == null) {
                        _initializeCamera();
                      }
                    },
              icon: const Icon(Icons.refresh),
              label: const Text('Ambil Ulang dari Kamera'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.tonalIcon(
              onPressed: _isInitializingCamera ? null : _initializeCamera,
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Coba Buka Kamera Lagi'),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationCard(ColorScheme colorScheme) {
    final location = _location;
    final hasError = _locationError != null;
    final statusColor = hasError
        ? colorScheme.error
        : location != null
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final title = hasError
        ? 'Lokasi Tidak Terdeteksi'
        : location != null
        ? 'Lokasi Perangkat'
        : 'Mendeteksi Lokasi...';
    final detail = hasError
        ? _locationError!
        : location != null
        ? '${location.formattedCoordinates} (akurasi ${location.formattedAccuracy})'
        : 'Mengambil koordinat GPS perangkat...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? colorScheme.error : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: statusColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    color: hasError ? colorScheme.error : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_isLocating)
            Icon(Icons.location_searching, size: 22, color: statusColor)
          else if (location != null)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: colorScheme.onPrimary, size: 16),
            )
          else
            IconButton(
              onPressed: _refreshLocation,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Muat Ulang Lokasi',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    if (_attendanceDone) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: () => context.go(StudentRoutePaths.beranda),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Selesai',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    if (_currentStep == 0) {
      final canProceed = _isRoomVerified || _isFlutterTest;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _proceedToFaceStep,
              icon: Icon(
                canProceed ? Icons.arrow_forward : Icons.lock_outline,
                size: 18,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: canProceed
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: canProceed
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              label: const Text(
                'Lanjutkan ke Scan Wajah',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _submitFaceAttendance,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Kirim Verifikasi Wajah',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class _StepIndicatorItem extends StatelessWidget {
  const _StepIndicatorItem({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isDone,
    required this.colorScheme,
  });

  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isDone;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final activeColor = isActive || isDone
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive || isDone
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check, color: colorScheme.onPrimary, size: 14)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: activeColor,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
