import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Koordinat perangkat saat ini beserta akurasi (meter).
class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double accuracy;

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get formattedAccuracy => '±${accuracy.toStringAsFixed(0)} m';
}

/// Kegagalan mengambil lokasi yang sudah siap ditampilkan ke pengguna.
class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pembungkus Geolocator: cek izin, ambil posisi akurasi tinggi, fallback last-known.
class LocationService {
  const LocationService();

  static const Duration _defaultTimeout = Duration(seconds: 15);

  Future<DeviceLocation> currentPosition({
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationException(
          'Layanan lokasi tidak aktif. Aktifkan GPS/lokasi perangkat lalu coba lagi.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationException(
          'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan aplikasi.',
        );
      }
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Izin lokasi ditolak. Berikan izin lokasi lalu coba lagi.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return _toDeviceLocation(position);
    } on LocationException {
      rethrow;
    } on LocationServiceDisabledException {
      throw const LocationException(
        'Layanan lokasi tidak aktif. Aktifkan GPS/lokasi perangkat lalu coba lagi.',
      );
    } on PermissionDeniedException {
      throw const LocationException(
        'Izin lokasi ditolak. Berikan izin lokasi lalu coba lagi.',
      );
    } on TimeoutException {
      return _lastKnownOrThrow();
    } catch (error) {
      // Plugin tidak tersedia (mis. unit test / platform tanpa GPS).
      return _lastKnownOrThrow(
        fallbackMessage: 'Gagal membaca lokasi perangkat: $error',
      );
    }
  }

  Future<DeviceLocation> _lastKnownOrThrow({String? fallbackMessage}) async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return _toDeviceLocation(last);
    } catch (_) {}
    throw LocationException(
      fallbackMessage ?? 'Lokasi perangkat belum terdeteksi. Pastikan GPS aktif dan berada di area terbuka.',
    );
  }

  DeviceLocation _toDeviceLocation(Position position) => DeviceLocation(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
  );
}

const locationService = LocationService();
