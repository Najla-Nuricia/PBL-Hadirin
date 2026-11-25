import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_guidance.dart';

/// Deteksi wajah di perangkat memakai ML Kit. Hanya ada di Android dan iOS;
/// di platform lain layar scan memakai pengambilan foto manual.
class FaceAnalyzer {
  static bool get isSupported =>
      !kIsWeb &&
      (Platform.isAndroid || Platform.isIOS) &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  /// Format frame yang bisa dibaca ML Kit di platform ini.
  static ImageFormatGroup get imageFormat => !kIsWeb && Platform.isIOS
      ? ImageFormatGroup.bgra8888
      : ImageFormatGroup.nv21;

  static const _orientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  FaceDetector? _detector;

  // Sudut toleh (yaw) hanya dijamin pada mode akurat.
  FaceDetector get _faceDetector => _detector ??= FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  /// Membaca satu frame. Mengembalikan null bila format frame tidak didukung.
  /// [viewSize] adalah ukuran area pratinjau (kamera mengisi area itu penuh).
  Future<FaceObservation?> analyze(
    CameraImage image, {
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
    required Size viewSize,
  }) async {
    final input = _toInputImage(image, camera, deviceOrientation);
    if (input == null) return null;

    final faces = await _faceDetector.processImage(input);
    final brightness = _brightness(image);
    if (faces.isEmpty) {
      return FaceObservation(faceCount: 0, brightness: brightness);
    }

    faces.sort((a, b) => b.boundingBox.width.compareTo(a.boundingBox.width));
    final main = faces.first;
    // Wajah kecil di latar belakang tidak dihitung.
    final count = faces
        .where((f) => f.boundingBox.width >= main.boundingBox.width * 0.5)
        .length;

    final rotation = input.metadata!.rotation;
    final sideways =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final upright = sideways
        ? Size(image.height.toDouble(), image.width.toDouble())
        : Size(image.width.toDouble(), image.height.toDouble());

    return FaceObservation(
      faceCount: count,
      box: _toView(
        main.boundingBox,
        upright,
        viewSize,
        mirror: camera.lensDirection == CameraLensDirection.front,
      ),
      yaw: main.headEulerAngleY ?? 0,
      pitch: main.headEulerAngleX ?? 0,
      roll: main.headEulerAngleZ ?? 0,
      leftEyeOpen: main.leftEyeOpenProbability,
      rightEyeOpen: main.rightEyeOpenProbability,
      brightness: brightness,
    );
  }

  Future<void> close() async {
    final detector = _detector;
    _detector = null;
    if (detector == null) return;
    try {
      await detector.close();
    } catch (_) {}
  }

  static InputImage? _toInputImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    if (image.planes.length != 1) return null;
    final rawFormat = image.format.raw;
    if (rawFormat is! int) return null;
    final format = InputImageFormatValue.fromRawValue(rawFormat);
    final expected = Platform.isIOS
        ? InputImageFormat.bgra8888
        : InputImageFormat.nv21;
    if (format != expected) return null;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else {
      final device = _orientationDegrees[deviceOrientation];
      if (device == null) return null;
      final degrees = camera.lensDirection == CameraLensDirection.front
          ? (camera.sensorOrientation + device) % 360
          : (camera.sensorOrientation - device + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(degrees);
    }
    if (rotation == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Memetakan kotak wajah dari koordinat gambar ke koordinat tampilan
  /// (gambar mengisi tampilan penuh, kamera depan dicerminkan).
  static Rect _toView(Rect box, Size image, Size view, {required bool mirror}) {
    final scale = math.max(
      view.width / image.width,
      view.height / image.height,
    );
    final dx = (view.width - image.width * scale) / 2;
    final dy = (view.height - image.height * scale) / 2;
    var left = box.left * scale + dx;
    var right = box.right * scale + dx;
    if (mirror) {
      final mirroredLeft = view.width - right;
      right = view.width - left;
      left = mirroredLeft;
    }
    return Rect.fromLTRB(
      left,
      box.top * scale + dy,
      right,
      box.bottom * scale + dy,
    );
  }

  /// Rata-rata kecerahan frame (0–255) dari sampel piksel.
  static double? _brightness(CameraImage image) {
    final bytes = image.planes.first.bytes;
    if (bytes.isEmpty) return null;
    var sum = 0;
    var samples = 0;
    if (image.format.group == ImageFormatGroup.bgra8888) {
      for (var i = 0; i + 2 < bytes.length; i += 4 * 97) {
        sum += (bytes[i] * 29 + bytes[i + 1] * 150 + bytes[i + 2] * 77) >> 8;
        samples++;
      }
    } else {
      // NV21: luma berada di width × height byte pertama.
      final lumaLength = math.min(bytes.length, image.width * image.height);
      for (var i = 0; i < lumaLength; i += 53) {
        sum += bytes[i];
        samples++;
      }
    }
    return samples == 0 ? null : sum / samples;
  }
}
