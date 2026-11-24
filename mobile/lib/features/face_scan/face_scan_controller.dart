import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'face_analyzer.dart';
import 'face_guidance.dart';

enum FaceCameraStatus {
  initializing,
  ready,
  permissionDenied,
  unavailable,
  failed,
}

/// Tampilan cincin yang diminta layar induk di luar panduan otomatis,
/// misalnya saat foto sedang diverifikasi server.
enum FaceScanOverride { none, busy, success, failure }

class CapturedFace {
  const CapturedFace({
    required this.bytes,
    required this.name,
    this.path,
    this.livenessChecked = false,
  });

  final Uint8List bytes;
  final String name;
  final String? path;

  /// True bila kedipan terdeteksi sebelum foto ini diambil.
  final bool livenessChecked;
}

const _permissionErrorCodes = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
  'permissionDenied',
  'NotAllowedError',
};

/// Mengelola kamera, deteksi wajah per frame, dan pengambilan foto untuk
/// layar scan wajah. Layar induk mendengarkan perubahan lewat [Listenable].
class FaceScanController extends ChangeNotifier with WidgetsBindingObserver {
  FaceScanController({this.requireBlink = false, this.onAutoCapture})
    : _engine = FaceGuidanceEngine(requireBlink: requireBlink);

  final bool requireBlink;

  /// Dipanggil saat panduan otomatis selesai dan foto sudah diambil.
  void Function(CapturedFace face)? onAutoCapture;

  final FaceGuidanceEngine _engine;
  final FaceAnalyzer _analyzer = FaceAnalyzer();

  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _lens = CameraLensDirection.front;
  FaceCameraStatus _status = FaceCameraStatus.initializing;
  FaceGuidanceState _guidance = FaceGuidanceState.searching;
  FacePoseKind _pose = FacePoseKind.front;
  FaceScanOverride _override = FaceScanOverride.none;
  String? _overrideTitle;
  String? _overrideHint;
  Uint8List? _still;
  FaceObservation? _lastObservation;
  Size _viewSize = Size.zero;
  Rect _oval = Rect.zero;

  bool _started = false;
  bool _disposed = false;
  bool _initializing = false;
  bool _manual = false;
  bool _detectionFailed = false;
  bool _paused = false;
  bool _analyzing = false;
  bool _capturing = false;
  int _unreadableFrames = 0;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);

  CameraController? get camera => _camera;
  FaceCameraStatus get status => _status;
  FaceGuidanceState get guidance => _guidance;
  FacePoseKind get pose => _pose;
  FaceScanOverride get overlay => _override;
  String? get overrideTitle => _overrideTitle;
  String? get overrideHint => _overrideHint;
  Uint8List? get still => _still;
  bool get isCapturing => _capturing;

  /// Deteksi di perangkat bisa dipakai di platform ini.
  bool get detectionSupported => FaceAnalyzer.isSupported && !_detectionFailed;

  /// Panduan otomatis aktif; bila false, foto diambil manual.
  bool get autoMode => detectionSupported && !_manual;

  bool get canCapture =>
      _status == FaceCameraStatus.ready && _camera != null && !_capturing;

  bool get canSwitchLens => _cameras.length > 1 && canCapture;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  /// Ukuran area pratinjau dan posisi bingkai oval, dilaporkan oleh tampilan.
  void updateGeometry(Size viewSize, Rect oval) {
    _viewSize = viewSize;
    _oval = oval;
  }

  void setPose(FacePoseKind pose) {
    _pose = pose;
    _engine.reset();
    _guidance = FaceGuidanceState.searching;
    _notify();
  }

  void setOverride(FaceScanOverride value, {String? title, String? hint}) {
    _override = value;
    _overrideTitle = title;
    _overrideHint = hint;
    _notify();
  }

  /// Foto diam yang menggantikan pratinjau, atau null untuk kamera langsung.
  set still(Uint8List? bytes) {
    _still = bytes;
    _notify();
  }

  void useManual() {
    _manual = true;
    unawaited(_stopDetection());
    _notify();
  }

  Future<void> retryCamera() => _initCamera();

  Future<void> switchLens() async {
    _lens = _lens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _initCamera();
  }

  /// Kembali ke kamera langsung dan mulai memandu lagi.
  Future<void> resume({bool clearPoseMemory = false}) async {
    _paused = false;
    _still = null;
    _override = FaceScanOverride.none;
    _overrideTitle = null;
    _overrideHint = null;
    if (clearPoseMemory) _engine.clearPoseMemory();
    _engine.reset();
    _guidance = FaceGuidanceState.searching;
    _notify();
    if (_camera == null) {
      await _initCamera();
    } else {
      await _startDetection();
    }
  }

  /// Mengambil satu foto. Panduan berhenti sampai [resume] dipanggil.
  Future<CapturedFace?> capture() async {
    final camera = _camera;
    if (camera == null ||
        !camera.value.isInitialized ||
        camera.value.isTakingPicture ||
        _capturing) {
      return null;
    }
    _capturing = true;
    _paused = true;
    final liveness =
        _guidance.phase == FaceGuidancePhase.ready && _guidance.livenessChecked;
    _notify();
    try {
      await _stopDetection();
      final file = await camera.takePicture();
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      _engine.markCaptured(_pose, _lastObservation);
      return CapturedFace(
        bytes: bytes,
        name: file.name.isNotEmpty ? file.name : 'capture.jpg',
        path: file.path,
        livenessChecked: liveness,
      );
    } catch (error) {
      debugPrint('Face capture failed: $error');
      return null;
    } finally {
      _capturing = false;
      _notify();
    }
  }

  Future<void> _autoCapture() async {
    final face = await capture();
    if (_disposed) return;
    if (face == null) {
      await resume();
      return;
    }
    onAutoCapture?.call(face);
  }

  Future<void> _initCamera() async {
    if (_initializing || _disposed) return;
    _initializing = true;
    // Lepas pratinjau dari layar lebih dulu, baru kamera lama ditutup.
    final disposing = _disposeCamera();
    _status = FaceCameraStatus.initializing;
    _notify();
    await disposing;
    try {
      final cameras = await availableCameras();
      if (_disposed) return;
      if (cameras.isEmpty) {
        _setStatus(FaceCameraStatus.unavailable);
        return;
      }
      _cameras = cameras;
      final preferred = cameras.where((c) => c.lensDirection == _lens).toList();
      final candidates = [
        ...preferred,
        ...cameras.where((c) => !preferred.contains(c)),
      ];

      CameraException? lastError;
      for (final candidate in candidates) {
        for (final preset in const [
          ResolutionPreset.medium,
          ResolutionPreset.low,
          ResolutionPreset.high,
        ]) {
          final controller = CameraController(
            candidate,
            preset,
            enableAudio: false,
            imageFormatGroup: FaceAnalyzer.isSupported
                ? FaceAnalyzer.imageFormat
                : null,
          );
          try {
            await controller.initialize();
            if (_disposed) {
              await controller.dispose();
              return;
            }
            _camera = controller;
            _status = FaceCameraStatus.ready;
            _notify();
            await _startDetection();
            return;
          } on CameraException catch (error) {
            lastError = error;
            await controller.dispose();
            if (_permissionErrorCodes.contains(error.code)) rethrow;
          }
        }
      }
      if (lastError != null) throw lastError;
    } on CameraException catch (error) {
      debugPrint('Camera initialization failed: ${error.code}');
      _setStatus(
        _permissionErrorCodes.contains(error.code)
            ? FaceCameraStatus.permissionDenied
            : error.code == 'cameraNotFound'
            ? FaceCameraStatus.unavailable
            : FaceCameraStatus.failed,
      );
    } catch (error) {
      // Platform tanpa kamera (desktop, pengujian) melempar galat plugin.
      debugPrint('Camera unavailable: $error');
      _setStatus(FaceCameraStatus.unavailable);
    } finally {
      _initializing = false;
    }
  }

  Future<void> _startDetection() async {
    final camera = _camera;
    if (camera == null || !autoMode || _paused || _disposed) return;
    if (camera.value.isStreamingImages) return;
    try {
      await camera.startImageStream(_onFrame);
    } catch (error) {
      debugPrint('Face detection stream unavailable: $error');
      _detectionFailed = true;
      _notify();
    }
  }

  Future<void> _stopDetection() async {
    final camera = _camera;
    if (camera == null || !camera.value.isStreamingImages) return;
    try {
      await camera.stopImageStream();
    } catch (_) {}
  }

  void _onFrame(CameraImage image) {
    if (_analyzing || _paused || _capturing || _disposed) return;
    if (_viewSize.isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastFrameAt) < const Duration(milliseconds: 70)) return;
    _lastFrameAt = now;
    _analyzing = true;
    unawaited(_analyze(image));
  }

  Future<void> _analyze(CameraImage image) async {
    try {
      final camera = _camera;
      if (camera == null) return;
      final observation = await _analyzer.analyze(
        image,
        camera: camera.description,
        deviceOrientation: camera.value.deviceOrientation,
        viewSize: _viewSize,
      );
      if (_disposed || _paused) return;
      if (observation == null) {
        _countUnreadableFrame();
        return;
      }
      _unreadableFrames = 0;
      _lastObservation = observation;
      final next = _engine.update(
        observation,
        oval: _oval,
        pose: _pose,
        now: DateTime.now(),
      );
      if (next != _guidance) {
        _guidance = next;
        _notify();
      }
      if (next.phase == FaceGuidancePhase.ready) unawaited(_autoCapture());
    } catch (error) {
      debugPrint('Face analysis failed: $error');
      _countUnreadableFrame();
    } finally {
      _analyzing = false;
    }
  }

  /// Bila frame terus tidak terbaca, beralih ke pengambilan foto manual.
  void _countUnreadableFrame() {
    if (++_unreadableFrames < 15) return;
    _detectionFailed = true;
    unawaited(_stopDetection());
    _notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      if (_camera == null) return;
      _status = FaceCameraStatus.initializing;
      unawaited(_disposeCamera());
      _notify();
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      _initCamera();
    }
  }

  void _setStatus(FaceCameraStatus status) {
    _status = status;
    _notify();
  }

  Future<void> _disposeCamera() async {
    final camera = _camera;
    _camera = null;
    if (camera == null) return;
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
    } catch (_) {}
    try {
      await camera.dispose();
    } catch (_) {}
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_started) WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera());
    unawaited(_analyzer.close());
    super.dispose();
  }
}
