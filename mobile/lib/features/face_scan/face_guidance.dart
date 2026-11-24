import 'dart:math' as math;
import 'dart:ui' show Rect;

/// Arah wajah yang diminta untuk satu foto.
///
/// `turnFirst` dan `pitchFirst` menerima arah mana pun; pasangannya
/// (`turnSecond`, `pitchSecond`) meminta arah sebaliknya. Dengan begitu dua
/// sampel samping selalu berbeda, apa pun konvensi tanda sudut di perangkat.
enum FacePoseKind { front, turnFirst, turnSecond, pitchFirst, pitchSecond }

/// Hasil deteksi satu frame kamera. [box] memakai koordinat tampilan yang
/// sama dengan bingkai oval.
class FaceObservation {
  const FaceObservation({
    required this.faceCount,
    this.box,
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.brightness,
  });

  final int faceCount;
  final Rect? box;

  /// Sudut kepala dalam derajat: toleh kiri-kanan, angguk, dan miring.
  final double yaw;
  final double pitch;
  final double roll;

  /// Peluang mata terbuka (0–1), null bila perangkat tidak menghitungnya.
  final double? leftEyeOpen;
  final double? rightEyeOpen;

  /// Rata-rata kecerahan frame (0–255).
  final double? brightness;
}

enum FaceIssue {
  noFace,
  multipleFaces,
  lowLight,
  tooFar,
  tooClose,
  offCenter,
  wrongPose,
}

enum FaceGuidancePhase { searching, adjusting, holding, blink, ready }

class FaceGuidanceState {
  const FaceGuidanceState(
    this.phase, {
    this.issue,
    this.progress = 0,
    this.livenessChecked = false,
  });

  static const searching = FaceGuidanceState(
    FaceGuidancePhase.searching,
    issue: FaceIssue.noFace,
  );

  final FaceGuidancePhase phase;
  final FaceIssue? issue;

  /// Kemajuan menahan posisi, 0–1.
  final double progress;

  /// True bila kedipan benar-benar terdeteksi sebelum foto diambil.
  final bool livenessChecked;

  @override
  bool operator ==(Object other) =>
      other is FaceGuidanceState &&
      other.phase == phase &&
      other.issue == issue &&
      other.progress == progress &&
      other.livenessChecked == livenessChecked;

  @override
  int get hashCode => Object.hash(phase, issue, progress, livenessChecked);
}

/// Menerjemahkan deteksi per frame menjadi tahap panduan:
/// cari wajah, perbaiki posisi, tahan, kedip, lalu siap difoto.
class FaceGuidanceEngine {
  FaceGuidanceEngine({
    this.requireBlink = false,
    this.holdDuration = const Duration(milliseconds: 800),
    this.issueDebounce = const Duration(milliseconds: 400),
  });

  final bool requireBlink;
  final Duration holdDuration;

  /// Masalah baru tampil setelah bertahan selama ini, supaya petunjuk tidak
  /// berkedip saat wajah bergerak sedikit.
  final Duration issueDebounce;

  static const double lowLightThreshold = 55;
  static const double _frontTolerance = 14;
  static const double _minTurn = 16;
  static const double _minPitch = 10;

  FaceGuidanceState _state = FaceGuidanceState.searching;
  FaceIssue? _pendingIssue;
  DateTime? _pendingSince;
  DateTime? _holdSince;
  bool _eyesSeenOpen = false;
  bool _eyesSeenClosed = false;
  double? _turnSign;
  double? _pitchSign;

  FaceGuidanceState get state => _state;

  /// Mulai lagi dari mencari wajah. Arah pose yang sudah direkam tetap.
  void reset() {
    _state = FaceGuidanceState.searching;
    _pendingIssue = null;
    _pendingSince = null;
    _holdSince = null;
    _eyesSeenOpen = false;
    _eyesSeenClosed = false;
  }

  /// Lupakan arah pose yang sudah direkam (scan diulang dari awal).
  void clearPoseMemory() {
    _turnSign = null;
    _pitchSign = null;
  }

  /// Catat arah foto yang baru diambil untuk pose pasangannya.
  void markCaptured(FacePoseKind pose, FaceObservation? last) {
    if (last == null) return;
    if (pose == FacePoseKind.turnFirst && last.yaw.abs() >= _minTurn / 2) {
      _turnSign = last.yaw.sign;
    }
    if (pose == FacePoseKind.pitchFirst && last.pitch.abs() >= _minPitch / 2) {
      _pitchSign = last.pitch.sign;
    }
  }

  FaceGuidanceState update(
    FaceObservation observation, {
    required Rect oval,
    required FacePoseKind pose,
    required DateTime now,
  }) {
    final issue = evaluate(observation, oval: oval, pose: pose);

    if (issue != null) {
      if (issue != _pendingIssue) {
        _pendingIssue = issue;
        _pendingSince = now;
      }
      if (now.difference(_pendingSince!) >= issueDebounce) {
        _holdSince = null;
        _eyesSeenOpen = false;
        _eyesSeenClosed = false;
        _state = issue == FaceIssue.noFace
            ? FaceGuidanceState.searching
            : FaceGuidanceState(FaceGuidancePhase.adjusting, issue: issue);
      }
      return _state;
    }

    _pendingIssue = null;
    _pendingSince = null;
    _holdSince ??= now;
    final held = now.difference(_holdSince!).inMilliseconds;
    final progress = (held / holdDuration.inMilliseconds).clamp(0.0, 1.0);
    if (progress < 1) {
      return _state = FaceGuidanceState(
        FaceGuidancePhase.holding,
        progress: progress,
      );
    }

    final left = observation.leftEyeOpen;
    final right = observation.rightEyeOpen;
    final canBlink = requireBlink && left != null && right != null;
    if (canBlink && !_blinkSeen(left, right)) {
      return _state = const FaceGuidanceState(
        FaceGuidancePhase.blink,
        progress: 1,
      );
    }
    return _state = FaceGuidanceState(
      FaceGuidancePhase.ready,
      progress: 1,
      livenessChecked: canBlink,
    );
  }

  /// Kedipan: mata terbuka, tertutup, lalu terbuka lagi.
  bool _blinkSeen(double left, double right) {
    final open = math.min(left, right);
    final closed = math.max(left, right);
    if (!_eyesSeenOpen) {
      if (open >= 0.6) _eyesSeenOpen = true;
      return false;
    }
    if (!_eyesSeenClosed) {
      if (closed <= 0.35) _eyesSeenClosed = true;
      return false;
    }
    return open >= 0.5;
  }

  /// Masalah pada frame ini, atau null bila wajah sudah pas.
  FaceIssue? evaluate(
    FaceObservation observation, {
    required Rect oval,
    required FacePoseKind pose,
  }) {
    final brightness = observation.brightness;
    final dark = brightness != null && brightness < lowLightThreshold;
    final box = observation.box;

    if (observation.faceCount == 0 || box == null) {
      // Di tempat gelap wajah memang tidak terdeteksi; sebut penyebabnya.
      return dark ? FaceIssue.lowLight : FaceIssue.noFace;
    }
    if (observation.faceCount > 1) return FaceIssue.multipleFaces;
    if (dark) return FaceIssue.lowLight;

    final ratio = box.width / oval.width;
    if (ratio < 0.5) return FaceIssue.tooFar;
    if (ratio > 1.15) return FaceIssue.tooClose;

    final frontal = pose == FacePoseKind.front;
    final dx = (box.center.dx - oval.center.dx).abs() / oval.width;
    final dy = (box.center.dy - oval.center.dy).abs() / oval.height;
    if (dx > (frontal ? 0.2 : 0.3) || dy > (frontal ? 0.2 : 0.28)) {
      return FaceIssue.offCenter;
    }

    return _poseMatches(observation, pose) ? null : FaceIssue.wrongPose;
  }

  bool _poseMatches(FaceObservation o, FacePoseKind pose) => switch (pose) {
    FacePoseKind.front =>
      o.yaw.abs() <= _frontTolerance &&
          o.pitch.abs() <= _frontTolerance &&
          o.roll.abs() <= _frontTolerance,
    FacePoseKind.turnFirst => o.yaw.abs() >= _minTurn,
    FacePoseKind.turnSecond =>
      o.yaw.abs() >= _minTurn && (_turnSign == null || o.yaw.sign != _turnSign),
    FacePoseKind.pitchFirst => o.pitch.abs() >= _minPitch,
    FacePoseKind.pitchSecond =>
      o.pitch.abs() >= _minPitch &&
          (_pitchSign == null || o.pitch.sign != _pitchSign),
  };
}
