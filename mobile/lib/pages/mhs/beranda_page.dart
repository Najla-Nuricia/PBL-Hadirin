import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_account.dart';
import '../../data/mhs/student_attendance.dart';
import '../../data/mhs/student_data_service.dart';
import '../../data/mhs/student_schedule.dart';
import '../../models/dosen/date_id.dart';
import '../../models/mhs/student_profile.dart';
import '../../routing/student_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/content_width.dart';
import 'widgets/friendly_error.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({this.dataService, super.key});

  final StudentDataService? dataService;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _selectedDay = DateTime.now().weekday;

  final Map<String, bool> _alarmToggles = {};

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
        : (studentAuthRepository.currentAccount?.className ??
              _account.className);
    return cls.isNotEmpty ? '$cls · $nim' : nim;
  }

  StudentProfile? _profile;
  StudentAttendanceSummary _summary = const StudentAttendanceSummary(
    hadir: 0,
    izin: 0,
    sakit: 0,
    alfa: 0,
  );
  List<StudentSchedule> _schedules = const [];
  List<Map<String, dynamic>> _activeSessions = const [];
  List<StudentAttendanceRecord> _records = const [];
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
      if (_profile != null &&
          current != null &&
          current.nim == _profile!.studentId) {
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
      final data = widget.dataService ?? studentDataService;
      final results = await Future.wait([
        data.loadProfile(),
        data.loadAttendanceSummary(),
        data.loadSchedules(),
        data.loadClassReminder(),
        // Sesi aktif dan riwayat hanya pelengkap; kegagalannya tidak boleh
        // mengosongkan seluruh beranda.
        data.loadActiveSessions().catchError((_) => <Map<String, dynamic>>[]),
        data.loadAttendanceHistory().catchError(
          (_) => <StudentAttendanceRecord>[],
        ),
      ]);
      if (!mounted) return;
      final loadedSchedules = results[2] as List<StudentSchedule>;
      setState(() {
        _profile = results[0] as StudentProfile;
        _summary = results[1] as StudentAttendanceSummary;
        _schedules = loadedSchedules;
        _reminder = results[3] as ClassReminder?;
        _activeSessions = results[4] as List<Map<String, dynamic>>;
        _records = results[5] as List<StudentAttendanceRecord>;
        _isLoading = false;
        _loadError = null;
        for (final s in loadedSchedules) {
          _alarmToggles.putIfAbsent(_scheduleKey(s), () => s.hasAlarm);
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

  static String _scheduleKey(StudentSchedule s) =>
      '${s.dayOfWeek}|${s.startTime}|${s.courseName}';

  static int? _minutes(String raw) {
    final m = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(raw);
    if (m == null) return null;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  /// Rekaman presensi hari ini untuk mata kuliah tertentu. Hanya dipakai bila
  /// data berasal dari server, karena data contoh tidak mewakili hari ini.
  StudentAttendanceRecord? _recordFor(String courseName) {
    if (!studentAuthRepository.hasRemoteSession) return null;
    final today = DateTime.now().day;
    for (final r in _records) {
      if (int.tryParse(r.date) == today &&
          r.courseName.trim().toLowerCase() ==
              courseName.trim().toLowerCase()) {
        return r;
      }
    }
    return null;
  }

  _FocusClass? _focusClass() {
    if (_activeSessions.isNotEmpty) {
      final s = _activeSessions.first;
      final course = (s['matkul_nama'] as String?) ?? '-';
      final start = (s['jam_mulai'] as String?) ?? '';
      final end = (s['jam_selesai'] as String?) ?? '';
      return _FocusClass(
        courseName: course,
        timeLabel: end.isEmpty ? start : '$start – $end',
        room: (s['ruangan_nama'] as String?) ?? '-',
        phase: _FocusPhase.ongoing,
        sessionOpen: true,
        record: _recordFor(course),
      );
    }

    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final today = _schedules.where((s) => s.dayOfWeek == now.weekday).toList()
      ..sort(
        (a, b) =>
            (_minutes(a.startTime) ?? 0).compareTo(_minutes(b.startTime) ?? 0),
      );
    StudentSchedule? pick;
    var phase = _FocusPhase.upcoming;
    for (final s in today) {
      final start = _minutes(s.startTime);
      final end = _minutes(s.endTime);
      if (start == null || end == null) continue;
      if (nowMin >= start && nowMin < end) {
        pick = s;
        phase = _FocusPhase.ongoing;
        break;
      }
      if (nowMin < start) {
        pick ??= s;
      }
    }
    if (pick != null) {
      return _FocusClass(
        courseName: pick.courseName,
        timeLabel: '${pick.startTime} – ${pick.endTime}',
        room: pick.room,
        phase: phase,
        sessionOpen: false,
        record: _recordFor(pick.courseName),
      );
    }

    final r = _reminder;
    if (r != null && r.courseName.isNotEmpty) {
      return _FocusClass(
        courseName: r.courseName,
        timeLabel: r.time,
        room: r.room,
        phase: _FocusPhase.upcoming,
        sessionOpen: false,
        record: _recordFor(r.courseName),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final now = DateTime.now();
    final name = _displayName.trim();
    final nameParts = name.split(RegExp(r'\s+'));
    final firstName = nameParts.first;
    final focus = _focusClass();

    return Scaffold(
      appBar: SkyAppBar(
        title: const WordmarkPill(),
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.page,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: IconButton(
              tooltip: 'Buka profil',
              onPressed: () => context.go(StudentRoutePaths.profil),
              icon: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.shadowSoft,
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.brand50,
                  foregroundColor: AppColors.brand700,
                  child: name.isEmpty
                      ? const Icon(PhosphorIconsRegular.userCircle, size: 20)
                      : Text(
                          nameParts
                              .take(2)
                              .map(
                                (part) => part.characters.first.toUpperCase(),
                              )
                              .join(),
                          maxLines: 1,
                          textScaler: TextScaler.noScaling,
                          style: text.labelMedium?.copyWith(
                            color: AppColors.brand700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AuroraBackground(
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              child: ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.pill,
                            boxShadow: AppColors.shadowSoft,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                PhosphorIconsRegular.calendarBlank,
                                size: 14,
                                color: AppColors.brand700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatDateId(now),
                                style: muted?.tabular.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      header: true,
                      child: Text(
                        firstName.isEmpty ? 'Halo.' : 'Halo, $firstName.',
                        style: text.displaySmall?.copyWith(fontSize: 34),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_displaySubtitle, style: muted?.tabular),
                    const SizedBox(height: AppSpacing.lg),
                  if (_isLoading) ...const [
                    AppSkeleton(height: 150, radius: AppRadius.lg),
                    SizedBox(height: AppSpacing.xxl),
                    AppSkeletonList(),
                  ] else if (_loadError != null)
                    AppErrorState(
                      message: friendlyError(
                        _loadError!,
                        fallback: 'Periksa koneksi internet, lalu coba lagi.',
                      ),
                      onRetry: _loadData,
                    )
                  else ...[
                    _SessionCard(
                      focus: focus,
                      onStart: () => context.go(StudentRoutePaths.absensi),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ScheduleSection(
                      selectedDay: _selectedDay,
                      today: now,
                      focus: focus,
                      schedules: _schedules,
                      onDaySelected: (day) =>
                          setState(() => _selectedDay = day),
                      alarmToggles: _alarmToggles,
                      keyOf: _scheduleKey,
                      onAlarmToggle: (key, val) =>
                          setState(() => _alarmToggles[key] = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSectionHeader(
                      title: 'Kehadiran semester ini',
                      action: TextButton(
                        onPressed: () => context.go(StudentRoutePaths.riwayat),
                        child: const Text('Lihat riwayat'),
                      ),
                    ),
                    _AttendanceCard(summary: _summary),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.go(StudentRoutePaths.surat),
                        icon: const Icon(
                          PhosphorIconsRegular.fileText,
                          size: 18,
                        ),
                        label: const Text('Ajukan izin atau sakit'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

enum _FocusPhase { ongoing, upcoming }

class _FocusClass {
  const _FocusClass({
    required this.courseName,
    required this.timeLabel,
    required this.room,
    required this.phase,
    required this.sessionOpen,
    this.record,
  });

  final String courseName;
  final String timeLabel;
  final String room;
  final _FocusPhase phase;
  final bool sessionOpen;
  final StudentAttendanceRecord? record;
}

bool _hasValue(String value) => value.isNotEmpty && value != '-';

// ─────────────────────────────────────────────────────────
// Kartu sesi: keadaan kelas hari ini dan satu aksi utamanya
// ─────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.focus, required this.onStart});

  final _FocusClass? focus;
  final VoidCallback onStart;

  static const _padding = EdgeInsets.all(18);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final f = focus;

    if (f == null) {
      return Card(
        child: Padding(
          padding: _padding,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.brand50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.calendarBlank,
                  size: 20,
                  color: AppColors.brand700,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Tidak ada kelas yang sedang atau akan berlangsung hari ini.',
                  style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final record = f.record;
    if (record != null) {
      final tone = AttendanceVisual.of(record.status.name).tone;
      return Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: tone.tint,
          borderRadius: AppRadius.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lencana sewarna dengan kartu ini; garis tepi menjaganya tetap
            // terbaca sebagai lencana.
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(color: tone.solid.withValues(alpha: 0.4)),
                ),
              ),
              child: AppStatusBadge.attendance(record.status.name),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              f.courseName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge?.copyWith(color: tone.ink),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _hasValue(record.time)
                  ? 'Presensi tercatat pukul ${record.time}'
                  : 'Presensi tercatat',
              style: text.bodyMedium?.tabular.copyWith(color: tone.ink),
            ),
          ],
        ),
      );
    }

    if (f.sessionOpen) {
      return AppGradientCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Stack(
          children: [
            Positioned(
              top: -34,
              right: -30,
              child: Icon(
                PhosphorIconsRegular.scan,
                size: 150,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OnDarkPill(label: 'Presensi dibuka'),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xxl),
                  child: Text(
                    f.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SessionMeta(focus: f, color: AppColors.onBrandMuted),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: AppGradientButton(
                    label: 'Mulai presensi',
                    onPressed: onStart,
                    icon: PhosphorIconsRegular.scan,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFE6EEFF)],
                    ),
                    foregroundColor: AppColors.sessionBackground,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Card(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF5FF), Colors.white],
          ),
        ),
        child: Padding(
          padding: _padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStatusBadge(
                label: f.phase == _FocusPhase.ongoing
                    ? 'Sedang berlangsung'
                    : 'Akan dimulai',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                f.courseName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _SessionMeta(focus: f, color: AppColors.inkMuted),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceInset,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.lock,
                      size: 16,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Presensi belum dibuka',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionMeta extends StatelessWidget {
  const _SessionMeta({required this.focus, required this.color});

  final _FocusClass focus;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.tabular
        .copyWith(color: color, fontWeight: FontWeight.w500);

    Widget item(IconData icon, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        if (_hasValue(focus.timeLabel))
          item(PhosphorIconsRegular.clock, focus.timeLabel),
        if (_hasValue(focus.room))
          item(PhosphorIconsRegular.mapPin, focus.room),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Jadwal Kelas
// ─────────────────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.summary});

  final StudentAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total =
        summary.hadir + summary.izin + summary.sakit + summary.alfa;
    final percent = total == 0 ? 0 : (summary.hadir * 100 / total).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$percent%',
                        style: text.displaySmall?.copyWith(
                          color: AppColors.brand700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'tingkat kehadiran',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        PhosphorIconsRegular.chartLineUp,
                        size: 14,
                        color: AppColors.brand700,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$total pertemuan',
                        style: text.labelMedium?.copyWith(
                          color: AppColors.brand700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AttendanceBar(
              hadir: summary.hadir,
              izin: summary.izin,
              sakit: summary.sakit,
              alfa: summary.alfa,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.selectedDay,
    required this.today,
    required this.focus,
    required this.onDaySelected,
    required this.alarmToggles,
    required this.keyOf,
    required this.onAlarmToggle,
    required this.schedules,
  });

  final int selectedDay;
  final DateTime today;
  final _FocusClass? focus;
  final ValueChanged<int> onDaySelected;
  final Map<String, bool> alarmToggles;
  final String Function(StudentSchedule) keyOf;
  final void Function(String key, bool val) onAlarmToggle;
  final List<StudentSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    final items = schedules.where((s) => s.dayOfWeek == selectedDay).toList()
      ..sort(
        (a, b) => (_BerandaPageState._minutes(a.startTime) ?? 0).compareTo(
          _BerandaPageState._minutes(b.startTime) ?? 0,
        ),
      );
    final focus = this.focus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: selectedDay == today.weekday
              ? 'Jadwal hari ini'
              : 'Jadwal kelas',
          action: _DaySelector(
            today: today,
            selectedDay: selectedDay,
            onDaySelected: onDaySelected,
          ),
        ),
        Card(
          child: items.isEmpty
              ? const ListTile(
                  leading: Icon(PhosphorIconsRegular.calendarBlank),
                  title: Text('Tidak ada kelas'),
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(),
                      _ScheduleRow(
                        schedule: items[i],
                        hasAlarm: alarmToggles[keyOf(items[i])] ?? false,
                        isInProgress:
                            selectedDay == today.weekday &&
                            focus?.phase == _FocusPhase.ongoing &&
                            focus?.courseName.trim().toLowerCase() ==
                                items[i].courseName.trim().toLowerCase(),
                        onAlarmToggle: (val) =>
                            onAlarmToggle(keyOf(items[i]), val),
                      ),
                    ],
                  ],
                ),
        ),
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Ketuk lonceng untuk pengingat 30 menit sebelum kelas.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.inkFaint),
            ),
          ),
      ],
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.today,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime today;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  static const _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  Widget build(BuildContext context) {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return PopupMenuButton<int>(
      tooltip: 'Pilih hari jadwal',
      onSelected: onDaySelected,
      itemBuilder: (context) => [
        for (var i = 0; i < _dayNames.length; i++)
          CheckedPopupMenuItem(
            value: i + 1,
            checked: selectedDay == i + 1,
            child: Text(
              '${_dayNames[i]}, ${monday.add(Duration(days: i)).day}',
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.touch),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _dayNames[selectedDay - 1],
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppColors.brand700),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              PhosphorIconsRegular.caretDown,
              size: 14,
              color: AppColors.brand700,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.schedule,
    required this.hasAlarm,
    required this.isInProgress,
    required this.onAlarmToggle,
  });

  final StudentSchedule schedule;
  final bool hasAlarm;
  final bool isInProgress;
  final ValueChanged<bool> onAlarmToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final faint = text.bodySmall?.copyWith(color: AppColors.inkFaint);
    final place = [
      if (_hasValue(schedule.room)) schedule.room,
      if (_hasValue(schedule.lecturerName)) schedule.lecturerName,
    ].join(' · ');

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    schedule.startTime,
                    softWrap: false,
                    style: text.titleSmall?.tabular.copyWith(
                      color: isInProgress ? AppColors.brand700 : AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    schedule.endTime,
                    softWrap: false,
                    style: faint?.tabular,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    schedule.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  if (place.isNotEmpty)
                    Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: faint,
                    ),
                  if (isInProgress) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const AppStatusBadge(
                      label: 'Berlangsung',
                      tone: StatusTone.info,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => onAlarmToggle(!hasAlarm),
              tooltip: hasAlarm
                  ? 'Matikan pengingat ${schedule.courseName}'
                  : 'Nyalakan pengingat ${schedule.courseName}',
              icon: Icon(
                hasAlarm
                    ? PhosphorIconsFill.bellRinging
                    : PhosphorIconsRegular.bell,
                color: hasAlarm ? AppColors.brand600 : AppColors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
