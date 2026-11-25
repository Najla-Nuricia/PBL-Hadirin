import 'dart:async';

import 'package:flutter/material.dart' show IconData;
import 'package:phosphor_icons/phosphor_icons.dart';

/// Langkah perbaikan yang ditawarkan saat presensi gagal.
enum PresensiRecovery {
  /// Ambil foto wajah lagi.
  rescan,

  /// Kirim ulang foto yang sudah diambil.
  resend,

  /// Perbarui lokasi, lalu kirim ulang foto yang sama.
  refreshLocation,

  /// Tidak bisa diperbaiki dari layar ini.
  leave,
}

enum PresensiFailureKind {
  faceMismatch,
  faceUnreadable,
  offline,
  outsideRadius,
  lowAccuracy,
  locationMissing,
  sessionClosed,
  invalidQr,
  other,
}

/// Kegagalan presensi yang sudah diterjemahkan untuk pengguna: apa yang
/// terjadi dan satu langkah untuk memperbaikinya.
class PresensiFailure {
  const PresensiFailure({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
    required this.actionLabel,
    required this.recovery,
  });

  static const locationMissing = PresensiFailure(
    kind: PresensiFailureKind.locationMissing,
    title: 'Lokasi belum terdeteksi',
    message: 'Aktifkan GPS, lalu perbarui lokasi.',
    icon: PhosphorIconsRegular.gpsSlash,
    actionLabel: 'Perbarui lokasi',
    recovery: PresensiRecovery.refreshLocation,
  );

  /// Menerjemahkan galat dari jaringan atau pesan `detail` server.
  factory PresensiFailure.from(Object error) {
    final raw = error
        .toString()
        .replaceFirst(RegExp(r'^(Exception|ClientException):\s*'), '')
        .trim();
    final lower = raw.toLowerCase();
    bool has(String part) => lower.contains(part);

    if (error is TimeoutException ||
        has('timeoutexception') ||
        has('socketexception') ||
        has('clientexception') ||
        has('failed host lookup') ||
        has('connection') ||
        has('network') ||
        has('sesi login server belum aktif')) {
      return const PresensiFailure(
        kind: PresensiFailureKind.offline,
        title: 'Koneksi terputus',
        message:
            'Datamu belum terkirim. Periksa internet, lalu kirim ulang. '
            'Kamu tidak perlu mengulang dari awal.',
        icon: PhosphorIconsRegular.wifiSlash,
        actionLabel: 'Kirim ulang',
        recovery: PresensiRecovery.resend,
      );
    }
    if (has('verifikasi wajah ditolak')) {
      return const PresensiFailure(
        kind: PresensiFailureKind.faceMismatch,
        title: 'Wajah tidak dikenali',
        message:
            'Wajahmu belum cocok dengan data yang terdaftar. Lepas masker '
            'atau kacamata hitam, lalu coba lagi.',
        icon: PhosphorIconsRegular.userMinus,
        actionLabel: 'Coba lagi',
        recovery: PresensiRecovery.rescan,
      );
    }
    if (has('wajah tidak terdeteksi') || has('alignment wajah')) {
      return const PresensiFailure(
        kind: PresensiFailureKind.faceUnreadable,
        title: 'Wajah tidak terbaca',
        message:
            'Foto tadi kurang jelas. Pastikan seluruh wajah terlihat dan '
            'cukup terang, lalu coba lagi.',
        icon: PhosphorIconsRegular.smileyXEyes,
        actionLabel: 'Coba lagi',
        recovery: PresensiRecovery.rescan,
      );
    }
    if (has('di luar area')) {
      return PresensiFailure(
        kind: PresensiFailureKind.outsideRadius,
        title: 'Kamu di luar area presensi',
        message: '$raw Masuk ke area kelas, lalu perbarui lokasi.',
        icon: PhosphorIconsRegular.gpsSlash,
        actionLabel: 'Perbarui lokasi',
        recovery: PresensiRecovery.refreshLocation,
      );
    }
    if (has('akurasi gps')) {
      return PresensiFailure(
        kind: PresensiFailureKind.lowAccuracy,
        title: 'Lokasi belum akurat',
        message: raw,
        icon: PhosphorIconsRegular.gpsFix,
        actionLabel: 'Perbarui lokasi',
        recovery: PresensiRecovery.refreshLocation,
      );
    }
    if (has('sudah ditutup') ||
        has('tidak ada sesi presensi') ||
        has('sesi presensi tidak ditemukan')) {
      return PresensiFailure(
        kind: PresensiFailureKind.sessionClosed,
        title: 'Sesi presensi tidak tersedia',
        message: '$raw Hubungi dosen bila kamu masih di kelas.',
        icon: PhosphorIconsRegular.calendarX,
        actionLabel: 'Kembali',
        recovery: PresensiRecovery.leave,
      );
    }
    if (has('qr')) {
      return PresensiFailure(
        kind: PresensiFailureKind.invalidQr,
        title: 'Kode QR tidak berlaku',
        message: raw,
        icon: PhosphorIconsRegular.qrCode,
        actionLabel: 'Coba lagi',
        recovery: PresensiRecovery.rescan,
      );
    }

    final technical =
        raw.isEmpty || has('exception') || has('error:') || has('null check');
    return PresensiFailure(
      kind: PresensiFailureKind.other,
      title: 'Presensi belum berhasil',
      message: technical ? 'Terjadi kendala. Coba lagi sebentar lagi.' : raw,
      icon: PhosphorIconsRegular.warningCircle,
      actionLabel: 'Coba lagi',
      recovery: PresensiRecovery.rescan,
    );
  }

  final PresensiFailureKind kind;
  final String title;
  final String message;
  final IconData icon;
  final String actionLabel;
  final PresensiRecovery recovery;
}
