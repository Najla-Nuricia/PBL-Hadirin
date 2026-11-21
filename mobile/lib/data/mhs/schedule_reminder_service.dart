import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'student_schedule.dart';

/// Alarm pengingat kelas: notifikasi OS + suara, 30 menit sebelum kelas.
///
/// - ID notifikasi turunan dari hari + jam + nama matkul (stabil lintas run).
/// - Toggle disimpan di SharedPreferences dan dijadwalkan ulang tiap kali
///   beranda memuat jadwal, sehingga alarm tetap berjalan walau app ditutup.
class ScheduleReminderService {
  ScheduleReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int leadMinutes = 30;

  /// Channel di-version karena audio usage diubah ke `alarm`.
  /// Channel Android tidak bisa diubah attribernya setelah dibuat.
  static const _channelId = 'class_reminders_v2';
  static const _channelName = 'Pengingat Kelas';
  static const _prefKey = 'schedule_reminder.enabled.v2';
  static const _scheduledIdsKey = 'schedule_reminder.scheduled_ids.v2';
  static const _testNotificationId = 999999;

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initFuture;

  Future<void> init() {
    final pending = _initFuture;
    if (pending != null) return pending;

    final future = _initialize();
    _initFuture = future;
    // Gagal init tidak boleh mengunci retry di sesi berikutnya.
    future.then(
      (_) {},
      onError: (Object _) {
        if (identical(_initFuture, future)) _initFuture = null;
      },
    );
    return future;
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (e) {
      debugPrint('REMINDER_TZ_FALLBACK: $e');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestSoundPermission: true,
          defaultPresentAlert: true,
          defaultPresentSound: true,
        ),
      ),
    );
    await requestNotificationPermission();
  }

  /// Izin notifikasi (Android 13+). Tidak boleh menggagalkan inisialisasi.
  Future<void> requestNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('REMINDER_NOTIF_PERMISSION: $e');
    }
  }

  /// Izin exact alarm (Android 12+). Dipanggil hanya saat user menyalakan
  /// alarm, karena plugin membuka halaman Settings untuk grant permission.
  Future<void> requestExactAlarmPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('REMINDER_EXACT_PERMISSION: $e');
    }
  }

  /// ID deterministik (FNV-1a 32-bit) dari hari + jam + nama matkul.
  /// Tidak bergantung pada implementasi [Object.hash] tiap versi Dart dan
  /// tidak pernah bernilai 0.
  static int idFor(StudentSchedule schedule) {
    final key =
        '${schedule.dayOfWeek}|${schedule.startTime}|'
        '${schedule.courseName.trim().toLowerCase()}';
    var hash = 2166136261;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xffffffff;
    }
    final id = hash & 0x3fffffff;
    return id == 0 ? 1 : id;
  }

  /// Kapan alarm berbunyi untuk kemunculan jadwal berikutnya.
  /// [now] bisa disuntik untuk test. Null jika jam invalid / sudah terlewat.
  static DateTime? nextReminderTime(
    StudentSchedule schedule, {
    DateTime? now,
    int leadMinutes = leadMinutes,
  }) {
    final start = _parseTime(schedule.startTime);
    if (start == null) return null;
    final current = now ?? DateTime.now();

    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(current.year, current.month, current.day + offset);
      if (day.weekday != schedule.dayOfWeek) continue;
      final classStart = DateTime(
        day.year,
        day.month,
        day.day,
        start.$1,
        start.$2,
      );
      final reminder = classStart.subtract(Duration(minutes: leadMinutes));
      if (!reminder.isAfter(current)) continue;
      return reminder;
    }
    return null;
  }

  static (int, int)? _parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(value);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  /// Jadwalkan ulang semua alarm aktif. Alarm lama yang tidak lagi aktif
  /// dibatalkan memakai daftar ID yang tersimpan.
  Future<void> sync(
    List<StudentSchedule> schedules,
    Set<int> enabledIds,
  ) async {
    await init();
    final exact = await _canScheduleExactly();
    final scheduled = <int>{};

    for (final schedule in schedules) {
      final id = idFor(schedule);
      if (!enabledIds.contains(id)) continue;
      final at = nextReminderTime(schedule);
      if (at == null) continue;

      final body = '$leadMinutes menit lagi: ${schedule.courseName} '
          'di ${schedule.room}';
      await _plugin.zonedSchedule(
        id: id,
        title: 'Pengingat kelas',
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _details(),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: schedule.courseName,
      );
      scheduled.add(id);
    }

    final previous = await _loadScheduledIds();
    for (final stale in previous.difference(scheduled)) {
      await _plugin.cancel(id: stale);
    }
    await _saveScheduledIds(scheduled);
  }

  Future<bool> _canScheduleExactly() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.canScheduleExactNotifications() ?? false;
    } catch (e) {
      debugPrint('REMINDER_CAN_EXACT: $e');
      return false;
    }
  }

  /// Langsung bunyikan alarm (tombol uji di banner).
  Future<void> showTestReminder(StudentSchedule schedule) async {
    await init();
    await _plugin.show(
      id: _testNotificationId,
      title: 'Pengingat kelas (uji)',
      body: '$leadMinutes menit lagi: ${schedule.courseName} di ${schedule.room}',
      notificationDetails: _details(),
      payload: schedule.courseName,
    );
  }

  static NotificationDetails _details() => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Pengingat 30 menit sebelum kelas dimulai',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      enableVibration: true,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
      sound: 'default',
    ),
  );

  // ── Persistensi ────────────────────────────────────────────────────────

  Future<Map<String, bool>> loadEnabledStates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return const <String, bool>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          if (entry.value is bool) entry.key: entry.value as bool,
      };
    } catch (e) {
      debugPrint('REMINDER_PREFS_READ: $e');
      return const <String, bool>{};
    }
  }

  Future<void> saveEnabledState(int id, bool enabled) async {
    final states = await loadEnabledStates();
    states[id.toString()] = enabled;
    await _writeJson(_prefKey, states);
  }

  Future<Set<int>> _loadScheduledIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scheduledIdsKey);
    if (raw == null || raw.isEmpty) return const <int>{};
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<num>()
          .map((value) => value.toInt())
          .toSet();
    } catch (e) {
      debugPrint('REMINDER_SCHEDULED_READ: $e');
      return const <int>{};
    }
  }

  Future<void> _saveScheduledIds(Set<int> ids) =>
      _writeJson(_scheduledIdsKey, ids.toList());

  Future<void> _writeJson(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }
}

final scheduleReminderService = ScheduleReminderService();
