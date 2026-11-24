import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/location_service.dart';
import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_data_service.dart';
import '../../features/face_scan/presensi_failure.dart';
import '../../routing/student_route_paths.dart';
import '../../widgets/widgets.dart';
import 'absensi_parts.dart';
import 'face_verification_page.dart';

/// Presensi: pindai QR kelas atau masukkan token, lalu verifikasi wajah.
class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> with WidgetsBindingObserver {
  bool _isLoadingSessions = false;
  bool _isSubmitting = false;
  String? _loadError;

  List<Map<String, dynamic>> _activeSessions = const [];
  String? _selectedSessionId;
  bool _faceRegistered = true;

  PresensiFailure? _failure;
  String? _tokenError;
  Map<String, dynamic>? _receipt;

  DeviceLocation? _location;
  bool _isLocating = false;
  String? _locationError;

  MobileScannerController? _qrScanner;
  bool _isStartingQrScanner = false;
  String? _qrScannerError;
  String? _handledQrToken;
  bool _faceScanOpen = false;

  final _tokenController = TextEditingController();

  // Di lingkungan flutter test plugin scanner tidak tersedia, jadi jangan mount.
  bool get _isFlutterTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    _refreshLocation();
    _startQrScanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _stopQrScanner();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    _refreshLocation();
    if (_receipt == null && !_faceScanOpen) _startQrScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _qrScanner?.dispose();
    _qrScanner = null;
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingSessions = true;
      _loadError = null;
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
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = PresensiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
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
        if (_failure?.recovery == PresensiRecovery.refreshLocation) {
          _failure = null;
        }
      });
    } on LocationException catch (error) {
      if (mounted) setState(() => _locationError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _locationError =
            'Lokasi belum bisa dibaca. Pastikan GPS aktif, lalu coba lagi.',
      );
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
      if (mounted) setState(() => _qrScannerError = null);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _qrScannerError =
            'Pemindai QR tidak bisa dibuka. Izinkan Kamera di pengaturan '
            'aplikasi, atau masukkan token secara manual.';
        _qrScanner = null;
      });
      await Future<void>.delayed(Duration.zero);
      await scanner.dispose();
    } finally {
      _isStartingQrScanner = false;
    }
  }

  Future<void> _stopQrScanner() async {
    final scanner = _qrScanner;
    if (scanner == null) return;
    if (mounted) {
      setState(() => _qrScanner = null);
      // Beri satu frame agar widget MobileScanner lepas dari controller.
      await Future<void>.delayed(Duration.zero);
    } else {
      _qrScanner = null;
    }
    await scanner.dispose();
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_isSubmitting || _receipt != null) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      final token = _extractQrToken(raw);
      if (token.isEmpty || token == _handledQrToken) continue;
      _handledQrToken = token;
      _submitQrAttendance(token);
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

  void _submitManualToken() {
    if (_isSubmitting) return;
    final token = _extractQrToken(_tokenController.text);
    FocusScope.of(context).unfocus();
    if (token.isEmpty) {
      setState(
        () => _tokenError = 'Token belum diisi. Ketik token dari dosen.',
      );
      return;
    }
    _submitQrAttendance(token);
  }

  Future<void> _submitQrAttendance(String qrToken) async {
    if (!studentAuthRepository.hasRemoteSession) {
      _handledQrToken = null;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Masuk dulu untuk mencatat presensi lewat QR.'),
          ),
        );
      return;
    }
    final location = _location;
    if (location == null) {
      _handledQrToken = null;
      setState(() => _failure = PresensiFailure.locationMissing);
      return;
    }

    setState(() {
      _failure = null;
      _isSubmitting = true;
    });
    try {
      final result = await studentDataService.submitQrAttendance(
        qrToken: qrToken,
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
      );
      if (!mounted) return;
      await _stopQrScanner();
      if (mounted) setState(() => _receipt = result);
    } catch (error) {
      if (!mounted) return;
      _handledQrToken = null;
      setState(() => _failure = PresensiFailure.from(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Map<String, dynamic>? get _selectedSession {
    for (final session in _activeSessions) {
      if (session['sesi_presensi_id'] == _selectedSessionId) return session;
    }
    return _activeSessions.isNotEmpty ? _activeSessions.first : null;
  }

  /// Kamera hanya boleh dipakai satu pemakai, jadi pemindai QR dilepas dulu.
  Future<void> _openFaceScan() async {
    FocusScope.of(context).unfocus();
    _faceScanOpen = true;
    await _stopQrScanner();
    if (!mounted) return;
    final session = _selectedSession;
    final result = await Navigator.of(context, rootNavigator: true)
        .push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => FaceVerificationPage(
              sessionId: session?['sesi_presensi_id'] as String?,
              courseName: session?['matkul_nama'] as String?,
              initialLocation: _location,
              faceRegistered:
                  _faceRegistered || !studentAuthRepository.hasRemoteSession,
            ),
          ),
        );
    _faceScanOpen = false;
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _failure = null;
        _receipt = result;
      });
    } else {
      _startQrScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;

    return Scaffold(
      appBar: SkyAppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          tooltip: 'Kembali',
          onPressed: () => context.go(StudentRoutePaths.beranda),
        ),
        title: const Text('Presensi'),
        actions: [
          if (receipt == null)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
              tooltip: 'Muat ulang sesi',
              onPressed: _isLoadingSessions ? null : _loadInitialData,
            ),
        ],
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: receipt != null
              ? PresensiReceipt(
                  data: receipt,
                  fallbackCourse: _selectedSession?['matkul_nama'] as String?,
                  onDone: () => context.go(StudentRoutePaths.beranda),
                  onHistory: () => context.go(StudentRoutePaths.riwayat),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadInitialData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.page,
                            AppSpacing.md,
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
                                children: _buildContent(context),
                              ),
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
                      child: AppGradientButton(
                        onPressed: _isSubmitting ? null : _openFaceScan,
                        icon: PhosphorIconsDuotone.userFocus,
                        label: 'Lanjutkan ke Scan Wajah',
                        isBusy: _isSubmitting,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final failure = _failure;
    final scannerError = _qrScannerError;

    return [
      const AppPageHeading(
        title: 'Pindai kode QR',
        description: 'Gunakan kode dari dosen atau presensi dengan wajah.',
      ),
      _buildSessionInfo(context),
      const SizedBox(height: AppSpacing.md),
      QrScannerFrame(
        scanner: _qrScanner,
        onDetect: _onQrDetected,
        label: _isSubmitting
            ? 'Mengirim ke server…'
            : _qrScanner == null
            ? 'Pemindai belum aktif'
            : 'Arahkan kamera ke kode QR',
        busy: _isSubmitting,
      ),
      if (scannerError != null) ...[
        const SizedBox(height: AppSpacing.md),
        AppBanner(
          tone: StatusTone.danger,
          message: scannerError,
          action: OutlinedButton.icon(
            onPressed: _isStartingQrScanner ? null : _startQrScanner,
            icon: const Icon(PhosphorIconsRegular.scan, size: 20),
            label: const Text('Coba buka pemindai QR'),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Text('Atau masukkan token', style: text.titleSmall),
      const SizedBox(height: 6),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('manual-token-field'),
              controller: _tokenController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) {
                if (_tokenError != null) setState(() => _tokenError = null);
              },
              onSubmitted: (_) => _submitManualToken(),
              decoration: InputDecoration(
                hintText: 'Token dari dosen',
                prefixIcon: const Icon(PhosphorIconsRegular.key),
                errorText: _tokenError,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: _isSubmitting ? null : _submitManualToken,
            child: const Text('Kirim'),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      LocationStatusRow(
        location: _location,
        error: _locationError,
        locating: _isLocating,
        onRefresh: _refreshLocation,
      ),
      if (failure != null) ...[
        const SizedBox(height: AppSpacing.md),
        AppBanner(
          tone: StatusTone.danger,
          icon: failure.icon,
          title: failure.title,
          message: failure.message,
        ),
      ],
    ];
  }

  Widget _buildSessionInfo(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (_isLoadingSessions) {
      return const AppSkeleton(height: 76, radius: AppRadius.lg);
    }
    final loadError = _loadError;
    if (loadError != null) {
      return AppBanner(
        tone: StatusTone.danger,
        title: 'Sesi presensi belum bisa dimuat',
        message: loadError,
        action: OutlinedButton(
          onPressed: _loadInitialData,
          child: const Text('Coba lagi'),
        ),
      );
    }
    if (_activeSessions.isEmpty) {
      return AppBanner(
        tone: StatusTone.neutral,
        message: studentAuthRepository.hasRemoteSession
            ? 'Belum ada sesi presensi yang dibuka untuk kelas Anda. '
                  'Tarik layar ke bawah untuk memuat ulang.'
            : 'Mode pratinjau. Masuk untuk melihat sesi presensi yang dibuka.',
      );
    }

    String detail(Map<String, dynamic> session) => [
      (session['jam_mulai'] as String?) ?? '',
      (session['ruangan_nama'] as String?) ?? '',
    ].where((part) => part.isNotEmpty).join(' · ');

    if (_activeSessions.length == 1) {
      final session = _activeSessions.first;
      final sub = detail(session);
      return Card(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE9F7F0), Colors.white],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.hadir, AppColors.brandCyan],
                    ),
                    borderRadius: AppRadius.control,
                    boxShadow: AppColors.shadowSoft,
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.graduationCap,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Presensi dibuka',
                        style: text.labelMedium?.copyWith(
                          color: AppColors.hadirInk,
                        ),
                      ),
                      Text(
                        (session['matkul_nama'] as String?) ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                      if (sub.isNotEmpty)
                        Text(
                          sub,
                          style: text.bodySmall?.tabular.copyWith(
                            color: AppColors.inkFaint,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      decoration: const InputDecoration(labelText: 'Sesi presensi yang dibuka'),
      items: [
        for (final session in _activeSessions)
          DropdownMenuItem(
            value: session['sesi_presensi_id'] as String,
            child: Text(
              [
                (session['matkul_nama'] as String?) ?? '-',
                detail(session),
              ].where((part) => part.isNotEmpty).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => setState(() => _selectedSessionId = value),
    );
  }
}
