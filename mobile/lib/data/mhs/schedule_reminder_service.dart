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
/// Toggle disimpan di SharedPreferences dan dijadwalkan ulang setiap kali
/// halaman beranda memuat jadwal.
class ScheduleReminderService {
  ScheduleReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int leadMinutes = 30;
  static const _channelId = 'class_reminders';
  static const _channelName = 'Pengingat Kelas';
  static const _prefKey = 'schedule_reminder.enabled';
  static const _testNotificationId = 999999;

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initFuture;

  Future<void> init() => _initFuture ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Pakai zona lokal bawaan kalau database timezone tidak tersedia.
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
    await requestPermissions();
  }

  /// Minta izin notifikasi (Android 13+) dan exact alarm (Android 12+).
  Future<void> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  /// ID stabil untuk satu jadwal: sama untuk hari yang sama lintas minggu.
  static int idFor(StudentSchedule schedule) =>
      Object.hash(schedule.dayOfWeek, schedule.startTime, schedule.courseName) &
      0x3fffffff;

  /// Kapan alarm harus berbunyi untuk kemunculan jadwal berikutnya.
  ///
  /// [now] bisa disuntik untuk keperluan test. Null jika jadwal tidak valid
  /// atau waktunya sudah lewat hari ini.
  static DateTime? nextReminderTime(
    StudentSchedule schedule, {
    DateTime? now,
    int leadMinutes = leadMinutes,
  }) {
    final start = _parseTime(schedule.startTime);
    if (start == null) return null;
    final current = now ?? DateTime.now();

    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(
        current.year,
        current.month,
        current.day + offset,
      );
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

  /// Sinkronkan semua alarm: yang aktif dijadwalkan, yang mati dibatalkan.
  Future<void> sync(
    List<StudentSchedule> schedules,
    Map<int, bool> enabledByIndex,
  ) async {
    await init();
    final exact = await _canScheduleExactly();
    for (var i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];
      final id = idFor(schedule);
      if (enabledByIndex[i] != true) {
        await _plugin.cancel(id: id);
        continue;
      }
      final at = nextReminderTime(schedule);
      if (at == null) {
        await _plugin.cancel(id: id);
        continue;
      }
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
    }
  }

  Future<bool> _canScheduleExactly() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
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

  // ── Persistensi toggle ─────────────────────────────────────────────────

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
    } catch (_) {
      return const <String, bool>{};
    }
  }

  Future<void> saveEnabledState(int id, bool enabled) async {
    final states = await loadEnabledStates();
    states[id.toString()] = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(states));
  }
}

final scheduleReminderService = ScheduleReminderService();
