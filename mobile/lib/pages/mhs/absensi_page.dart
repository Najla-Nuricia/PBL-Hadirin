import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/api_config.dart';
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
};

/// Halaman presensi dua tahap: validasi sesi QR + GPS kampus dan verifikasi wajah via kamera.
class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Default coordinates correspond to JTI Polinema campus geofence.
  static const double _defaultLatitude = -7.946714;
  static const double _defaultLongitude = 112.615668;

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

  Uint8List? _probeImageBytes;
  String? _probeImageName;
  String? _statusMessage;
  String? _errorMessage;
  Map<String, dynamic>? _lastRecordResponse;

  final _qrTokenController = TextEditingController();
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentStep != 1) return;
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed &&
        _cameraController == null &&
        !_attendanceDone) {
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
    _pulseController.dispose();
    _qrTokenController.dispose();
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

      final selected = cameras.firstWhere(
        (c) => c.lensDirection == _preferredLens,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted || _currentStep != 1) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraStatus = _CameraStatus.ready;
      });
    } on CameraException catch (error) {
      await controller?.dispose();
      debugPrint('Attendance camera initialization failed: ${error.code}');
      _setCameraStatus(
        _cameraPermissionErrorCodes.contains(error.code)
            ? _CameraStatus.permissionDenied
            : _CameraStatus.failed,
      );
    } catch (error) {
      await controller?.dispose();
      debugPrint('Attendance camera unavailable on this platform: $error');
      _setCameraStatus(_CameraStatus.unavailable);
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
    if (!studentAuthRepository.hasRemoteSession) return;
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

  Future<void> _submitQrOnly() async {
    if (!studentAuthRepository.hasRemoteSession) {
      _showSnackBar('Login terlebih dahulu untuk mencatat presensi QR.');
      return;
    }
    final qrToken = _qrTokenController.text.trim();
    if (qrToken.length < 4) {
      setState(() => _errorMessage = 'Masukkan token QR minimal 4 karakter.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _lastRecordResponse = null;
    });
    _setSubmitting(true);
    try {
      final res = await studentDataService.submitQrAttendance(
        qrToken: qrToken,
        latitude: _defaultLatitude,
        longitude: _defaultLongitude,
      );
      if (!mounted) return;
      setState(() {
        _attendanceDone = true;
        _lastRecordResponse = res;
        _statusMessage =
            (res['message'] as String?) ?? 'Presensi QR berhasil dicatat!';
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

  void _proceedToFaceStep() {
    setState(() {
      _currentStep = 1;
      _errorMessage = null;
      _attendanceDone = false;
      _statusMessage = null;
      _lastRecordResponse = null;
    });
    _initializeCamera();
  }

  Future<void> _pickFaceProbePhoto() async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.image);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        _showSnackBar('File foto kosong atau gagal dibaca.');
        return;
      }
      setState(() {
        _probeImageBytes = bytes;
        _probeImageName = picked.name;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal membaca file foto: $e');
    }
  }

  Future<void> _submitFaceAttendance() async {
    if (!studentAuthRepository.hasRemoteSession) {
      _showSnackBar(
        'Sesi server belum aktif (${ApiConfig.baseUrl}). Masuk ulang terlebih dahulu.',
      );
      return;
    }
    if (_probeImageBytes == null || _probeImageBytes!.isEmpty) {
      setState(
        () => _errorMessage = 'Ambil foto dari kamera atau pilih foto wajah terlebih dahulu.',
      );
      return;
    }
    final qrToken = _qrTokenController.text.trim();
    if ((_selectedSessionId == null || _selectedSessionId!.isEmpty) &&
        qrToken.isEmpty) {
      setState(
        () => _errorMessage =
            'Pilih sesi presensi aktif atau isi token QR terlebih dahulu.',
      );
      return;
    }

    setState(() => _errorMessage = null);
    _setSubmitting(true);
    try {
      final res = await studentDataService.submitFaceAttendance(
        imageBytes: _probeImageBytes!,
        filename: _probeImageName ?? 'probe.jpg',
        sesiPresensiId: _selectedSessionId,
        qrToken: qrToken.isNotEmpty ? qrToken : null,
        latitude: _defaultLatitude,
        longitude: _defaultLongitude,
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
        _lastRecordResponse = res;
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
                      if (_attendanceDone && _lastRecordResponse != null) ...[
                        const SizedBox(height: 12),
                        _buildStorageProofCard(colorScheme),
                      ],
                      if (_currentStep == 0) ...[
                        const SizedBox(height: 16),
                        _buildSessionSelector(colorScheme),
                        const SizedBox(height: 12),
                        _buildQrInput(colorScheme),
                      ] else if (!_attendanceDone) ...[
                        const SizedBox(height: 16),
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
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _StepIndicatorItem(
            stepNumber: 1,
            label: 'Scan QR',
            isActive: _currentStep == 0,
            isDone: _currentStep > 0 || _attendanceDone,
            colorScheme: colorScheme,
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: _currentStep > 0 || _attendanceDone
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          _StepIndicatorItem(
            stepNumber: 2,
            label: 'Scan Wajah',
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
    final showLiveCamera = _currentStep == 1 &&
        !isDone &&
        _probeImageBytes == null &&
        _cameraStatus == _CameraStatus.ready &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;

    return Container(
      width: double.infinity,
      height: showLiveCamera ? 290 : 210,
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
          if (showLiveCamera)
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
              width: showLiveCamera ? 180 : 150,
              height: showLiveCamera ? 180 : 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDone
                      ? colorScheme.secondary
                      : showLiveCamera
                          ? Colors.white70
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(showLiveCamera ? 90 : 14),
              ),
              child: showLiveCamera
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
                                  : Icon(
                                      _currentStep == 0
                                          ? Icons.qr_code_scanner
                                          : Icons.face_retouching_natural,
                                      color: colorScheme.primary.withValues(alpha: 0.65),
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
          if (_isSubmitting)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      _CameraStatus.permissionDenied =>
        'Izin kamera ditolak. Berikan izin kamera atau pilih foto dari file.',
      _CameraStatus.unavailable =>
        'Kamera langsung tidak tersedia di perangkat ini; gunakan Pilih Foto (File).',
      _CameraStatus.failed =>
        'Kamera gagal dibuka. Coba muat ulang kamera atau pilih foto dari file.',
      _CameraStatus.ready =>
        _probeImageBytes == null
            ? 'Arahkan wajah ke bingkai kamera lalu tekan Ambil Foto Wajah'
            : 'Foto wajah siap dikirim untuk verifikasi MobileFaceNet',
      _CameraStatus.idle => 'Siapkan verifikasi wajah MobileFaceNet',
    };

    final message = _errorMessage ??
        _statusMessage ??
        (_currentStep == 0
            ? 'Pilih sesi aktif atau masukkan token QR dosen di depan kelas'
            : cameraHint);
    final isError = _errorMessage != null;
    final isSuccess = !isError && _attendanceDone;

    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isError
            ? colorScheme.error
            : (isSuccess ? colorScheme.secondary : colorScheme.onSurfaceVariant),
        fontSize: 13,
        fontWeight: (isError || isSuccess) ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildStorageProofCard(ColorScheme colorScheme) {
    final rec = _lastRecordResponse ?? const {};
    final photoPath = rec['face_photo_path'] as String?;
    final kehadiranId = rec['kehadiran_id'] as String?;
    if (photoPath == null && kehadiranId == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bukti Tersimpan di Database',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (kehadiranId != null)
            Text(
              'ID Kehadiran: $kehadiranId',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
            ),
          if (photoPath != null)
            Text(
              'Storage Foto: foto-presensi/$photoPath',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
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

    final validSelection = _activeSessions.any(
      (s) => s['sesi_presensi_id'] == _selectedSessionId,
    )
        ? _selectedSessionId
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(validSelection),
      initialValue: validSelection,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Sesi Presensi Aktif',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _buildQrInput(ColorScheme colorScheme) {
    return TextField(
      controller: _qrTokenController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Token QR Sesi',
        hintText: 'Masukkan token QR dari dosen (opsional jika pakai sesi aktif)',
        prefixIcon: const Icon(Icons.qr_code_2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFacePreviewCard(ColorScheme colorScheme) {
    final cameraReady = _cameraStatus == _CameraStatus.ready &&
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
            child: FilledButton.tonalIcon(
              onPressed: (_isSubmitting || _isCapturing) ? null : _captureFromCamera,
              icon: _isCapturing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_isCapturing ? 'Mengambil foto...' : 'Ambil Foto Wajah'),
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
        else if (_cameraStatus == _CameraStatus.permissionDenied ||
            _cameraStatus == _CameraStatus.failed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: _isInitializingCamera ? null : _initializeCamera,
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Coba Buka Kamera Lagi'),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _pickFaceProbePhoto,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(
            _probeImageName != null
                ? 'Ganti Foto (${_probeImageName!})'
                : 'Pilih Foto dari Galeri / File',
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lokasi Geofence Kampus',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                'JTI Polinema ($_defaultLatitude, $_defaultLongitude)',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: colorScheme.onPrimary, size: 16),
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
      final hasQrToken = _qrTokenController.text.trim().isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasQrToken) ...[
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitQrOnly,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Catat Presensi QR Sekarang'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _proceedToFaceStep,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
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
