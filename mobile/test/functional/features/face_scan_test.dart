import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/face_scan/face_guidance.dart';
import 'package:mobile/features/face_scan/presensi_failure.dart';

void main() {
  const oval = Rect.fromLTWH(60, 200, 240, 320);
  final start = DateTime(2026, 11, 20, 7);
  DateTime at(int ms) => start.add(Duration(milliseconds: ms));

  FaceObservation face({
    double widthRatio = 0.8,
    double yaw = 0,
    double pitch = 0,
    double? eyes,
    double brightness = 120,
    int count = 1,
  }) => FaceObservation(
    faceCount: count,
    box: Rect.fromCenter(
      center: oval.center,
      width: oval.width * widthRatio,
      height: oval.height * widthRatio,
    ),
    yaw: yaw,
    pitch: pitch,
    leftEyeOpen: eyes,
    rightEyeOpen: eyes,
    brightness: brightness,
  );

  group('FaceGuidanceEngine', () {
    test('a brief problem does not replace the current hint', () {
      final engine = FaceGuidanceEngine();
      FaceGuidanceState step(FaceObservation o, int ms) =>
          engine.update(o, oval: oval, pose: FacePoseKind.front, now: at(ms));

      expect(step(face(widthRatio: 0.3), 0).phase, FaceGuidancePhase.searching);
      expect(step(face(widthRatio: 0.3), 200).issue, FaceIssue.noFace);

      final settled = step(face(widthRatio: 0.3), 450);
      expect(settled.phase, FaceGuidancePhase.adjusting);
      expect(settled.issue, FaceIssue.tooFar);
    });

    test('a dark frame without a face is reported as low light', () {
      final engine = FaceGuidanceEngine();
      const dark = FaceObservation(faceCount: 0, brightness: 20);
      engine.update(dark, oval: oval, pose: FacePoseKind.front, now: at(0));
      final state = engine.update(
        dark,
        oval: oval,
        pose: FacePoseKind.front,
        now: at(500),
      );

      expect(state.issue, FaceIssue.lowLight);
    });

    test('verification holds, waits for a blink, then is ready', () {
      final engine = FaceGuidanceEngine(requireBlink: true);
      FaceGuidanceState step(double eyes, int ms) => engine.update(
        face(eyes: eyes),
        oval: oval,
        pose: FacePoseKind.front,
        now: at(ms),
      );

      expect(step(0.9, 0).phase, FaceGuidancePhase.holding);
      expect(step(0.9, 400).progress, closeTo(0.5, 0.01));
      expect(step(0.9, 800).phase, FaceGuidancePhase.blink);
      expect(step(0.9, 900).phase, FaceGuidancePhase.blink);
      expect(step(0.1, 1000).phase, FaceGuidancePhase.blink);

      final ready = step(0.9, 1100);
      expect(ready.phase, FaceGuidancePhase.ready);
      expect(ready.livenessChecked, isTrue);
    });

    test('without eye data the photo is taken but liveness is not claimed', () {
      final engine = FaceGuidanceEngine(requireBlink: true);
      engine.update(face(), oval: oval, pose: FacePoseKind.front, now: at(0));
      final state = engine.update(
        face(),
        oval: oval,
        pose: FacePoseKind.front,
        now: at(800),
      );

      expect(state.phase, FaceGuidancePhase.ready);
      expect(state.livenessChecked, isFalse);
    });

    test('the second side pose needs the opposite direction', () {
      final engine = FaceGuidanceEngine();
      FaceIssue? check(FacePoseKind pose, double yaw) =>
          engine.evaluate(face(yaw: yaw), oval: oval, pose: pose);

      expect(check(FacePoseKind.turnFirst, 5), FaceIssue.wrongPose);
      expect(check(FacePoseKind.turnFirst, 25), isNull);
      engine.markCaptured(FacePoseKind.turnFirst, face(yaw: 25));

      expect(check(FacePoseKind.turnSecond, 25), FaceIssue.wrongPose);
      expect(check(FacePoseKind.turnSecond, -25), isNull);
    });
  });

  group('PresensiFailure.from', () {
    test('maps a rejected face to a rescan', () {
      final failure = PresensiFailure.from(
        Exception(
          'Verifikasi wajah ditolak: Tidak cocok '
          '(kemiripan=0.3123, batas minimum=0.50).',
        ),
      );

      expect(failure.kind, PresensiFailureKind.faceMismatch);
      expect(failure.recovery, PresensiRecovery.rescan);
      expect(failure.message, isNot(contains('0.3123')));
    });

    test('keeps the server distance when outside the radius', () {
      final failure = PresensiFailure.from(
        Exception(
          'Lokasi di luar area Kampus: 240 m dari titik presensi, batas 100 m.',
        ),
      );

      expect(failure.kind, PresensiFailureKind.outsideRadius);
      expect(failure.recovery, PresensiRecovery.refreshLocation);
      expect(failure.message, contains('240 m'));
    });

    test('a timeout keeps the photo and offers a resend', () {
      final failure = PresensiFailure.from(TimeoutException('no reply'));

      expect(failure.kind, PresensiFailureKind.offline);
      expect(failure.title, 'Koneksi terputus');
      expect(failure.recovery, PresensiRecovery.resend);
    });

    test('a closed session cannot be retried from the scan screen', () {
      final failure = PresensiFailure.from(
        Exception('Sesi presensi sudah ditutup.'),
      );

      expect(failure.kind, PresensiFailureKind.sessionClosed);
      expect(failure.recovery, PresensiRecovery.leave);
    });

    test('technical errors are not shown to the user', () {
      final failure = PresensiFailure.from(
        const FormatException('Unexpected character'),
      );

      expect(failure.kind, PresensiFailureKind.other);
      expect(failure.message, isNot(contains('FormatException')));
    });
  });
}
