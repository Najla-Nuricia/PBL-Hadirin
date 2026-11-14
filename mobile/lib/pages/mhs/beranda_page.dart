import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_account.dart';
import '../../data/mhs/student_attendance.dart';
import '../../data/mhs/student_data_service.dart';
import '../../data/mhs/student_schedule.dart';
import '../../models/mhs/student_profile.dart';
import '../../routing/student_route_paths.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _selectedDay = DateTime.now().weekday;

  final Map<int, bool> _alarmToggles = {};

  bool _showReminder = true;

  StudentAccount get _account =>
      studentAuthRepository.currentAccount ??
      DummyStudentAuthRepository.demoAccount;

  String get _displayName {
    if (_profile != null && _profile!.fullName.isNotEmpty) {
      return _profile!.fullName;
    }
    final current = studentAuthRepository.currentAccount;
    if (current != null) return current.fullName;
    return _account.fullName;
  }

  String get _displaySubtitle {
    final nim = (_profile?.studentId.isNotEmpty == true)
        ? _profile!.studentId
        : (studentAuthRepository.currentAccount?.nim ?? _account.nim);
    final cls = (_profile?.className.isNotEmpty == true)
        ? _profile!.className
        : (studentAuthRepository.currentAccount?.className ?? _account.className);
    return cls.isNotEmpty ? '$nim · $cls' : nim;
  }

  StudentProfile? _profile;
  StudentAttendanceSummary _summary = const StudentAttendanceSummary(
    hadir: 0,
    izin: 0,
    sakit: 0,
    alfa: 0,
  );
  List<StudentSchedule> _schedules = const [];
  ClassReminder? _reminder;
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    studentAuthRepository.addListener(_handleAccountChanged);
    _loadData();
  }

  @override
  void dispose() {
    studentAuthRepository.removeListener(_handleAccountChanged);
    super.dispose();
  }

  void _handleAccountChanged() {
    final current = studentAuthRepository.currentAccount;
    if (!mounted) return;
    setState(() {
      if (_profile != null && current != null && current.nim == _profile!.studentId) {
        _profile = StudentProfile(
          fullName: current.fullName,
          studentId: _profile!.studentId,
          email: _profile!.email,
          phoneNumber: _profile!.phoneNumber,
          role: _profile!.role,
          className: _profile!.className,
        );
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        studentDataService.loadProfile(),
        studentDataService.loadAttendanceSummary(),
        studentDataService.loadSchedules(),
        studentDataService.loadClassReminder(),
      ]);
      if (!mounted) return;
      final loadedSchedules = results[2] as List<StudentSchedule>;
      setState(() {
        _profile = results[0] as StudentProfile;
        _summary = results[1] as StudentAttendanceSummary;
        _schedules = loadedSchedules;
        _reminder = results[3] as ClassReminder?;
        _isLoading = false;
        _loadError = null;
        for (var i = 0; i < loadedSchedules.length; i++) {
          _alarmToggles.putIfAbsent(i, () => loadedSchedules[i].hasAlarm);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_loadError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Theme.of(context).colorScheme.onErrorContainer),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gagal memuat data: $_loadError',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onErrorContainer),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _loadData,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else ...[ 
                      if (_showReminder && _reminder != null)
                        _ReminderBanner(
                          reminder: _reminder!,
                          onDismiss: () => setState(() => _showReminder = false),
                        ),
                      if (_showReminder && _reminder != null)
                        const SizedBox(height: 12),
                    _QuickActions(
                      onAbsensiTap: () => context.go(StudentRoutePaths.absensi),
                      onSuratTap: () => context.go(StudentRoutePaths.surat),
                    ),
                    const SizedBox(height: 16),
                    _AttendanceSummaryCard(
                      summary: _summary,
                      onViewAll: () => context.go(StudentRoutePaths.riwayat),
                    ),
                    const SizedBox(height: 16),
                      _ScheduleSection(
                        selectedDay: _selectedDay,
                        schedules: _schedules,
                        onDaySelected: (day) =>
                            setState(() => _selectedDay = day),
                        alarmToggles: _alarmToggles,
                        onAlarmToggle: (index, val) =>
                            setState(() => _alarmToggles[index] = val),
                      ),
                    ], // end else
                    ],
                  ),
                ),
              ),
            ),
            _AlarmInfoBanner(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang,',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _displayName,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _displaySubtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Reminder Banner
// ─────────────────────────────────────────────────────────
class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.reminder, required this.onDismiss});

  final ClassReminder reminder;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: colorScheme.onTertiaryContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.message,
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${reminder.courseName} — ${reminder.time} di ${reminder.room}',
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer.withValues(
                      alpha: 0.8,
                    ),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              color: colorScheme.onTertiaryContainer,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Quick Actions (Absensi & Surat)
// ─────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAbsensiTap, required this.onSuratTap});

  final VoidCallback onAbsensiTap;
  final VoidCallback onSuratTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.videocam_outlined,
            label: 'Absensi',
            sublabel: 'Scan Wajah',
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            onTap: onAbsensiTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.description_outlined,
            label: 'Surat',
            sublabel: 'Izin / Sakit',
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            iconColor: colorScheme.primary,
            onTap: onSuratTap,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.backgroundColor,
    required this.foregroundColor,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? foregroundColor, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        color: foregroundColor.withValues(alpha: 0.75),
                        fontSize: 11,
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
}

// ─────────────────────────────────────────────────────────
// Rekap Kehadiran Card
// ─────────────────────────────────────────────────────────
class _AttendanceSummaryCard extends StatelessWidget {
  const _AttendanceSummaryCard({
    required this.summary,
    required this.onViewAll,
  });

  final StudentAttendanceSummary summary;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Rekap Kehadiran',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: colorScheme.primary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AttendanceStat(
                count: summary.hadir,
                label: 'Hadir',
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              _AttendanceStat(
                count: summary.izin,
                label: 'Izin',
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              _AttendanceStat(
                count: summary.sakit,
                label: 'Sakit',
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _AttendanceStat(
                count: summary.alfa,
                label: 'Alfa',
                color: colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  const _AttendanceStat({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Jadwal Kelas Section
// ─────────────────────────────────────────────────────────
class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.selectedDay,
    required this.onDaySelected,
    required this.alarmToggles,
    required this.onAlarmToggle,
    this.schedules,
  });

  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  final Map<int, bool> alarmToggles;
  final void Function(int index, bool val) onAlarmToggle;
  final List<StudentSchedule>? schedules;

  static const _dayLabels = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];

  List<int> _currentWeekDayNumbers() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - DateTime.monday));
    return List.generate(7, (i) => monday.add(Duration(days: i)).day);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayDates = _currentWeekDayNumbers();
    final sourceSchedules = schedules ?? dummySchedules;
    final filteredSchedules = sourceSchedules
        .where((s) => s.dayOfWeek == selectedDay)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              'Jadwal Kelas',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Day picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onDaySelected(i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: selectedDay == (i + 1)
                              ? colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _dayLabels[i],
                              style: TextStyle(
                                color: selectedDay == (i + 1)
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${dayDates[i]}',
                              style: TextStyle(
                                color: selectedDay == (i + 1)
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Schedule list
          if (filteredSchedules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Tidak ada jadwal untuk hari ini.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < filteredSchedules.length; i++)
              _ScheduleItem(
                schedule: filteredSchedules[i],
                hasAlarm: alarmToggles[i] ?? false,
                onAlarmToggle: (val) => onAlarmToggle(i, val),
                isLast: i == filteredSchedules.length - 1,
              ),
        ],
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({
    required this.schedule,
    required this.hasAlarm,
    required this.onAlarmToggle,
    this.isLast = false,
  });

  final StudentSchedule schedule;
  final bool hasAlarm;
  final ValueChanged<bool> onAlarmToggle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
          indent: 14,
          endIndent: 14,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.courseName,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${schedule.startTime} – ${schedule.endTime}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              schedule.room,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule.lecturerName,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: hasAlarm,
                onChanged: onAlarmToggle,
                activeThumbColor: colorScheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Alarm Info Banner (bottom)
// ─────────────────────────────────────────────────────────
class _AlarmInfoBanner extends StatelessWidget {
  const _AlarmInfoBanner({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pengingat kelas — Toggle menyalakan alarm 30 menit sebelum kelas.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
