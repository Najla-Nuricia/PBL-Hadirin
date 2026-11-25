import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_attendance.dart';
import '../../data/mhs/student_data_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/chip_scroller.dart';
import 'widgets/content_width.dart';
import 'widgets/friendly_error.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  static const _semesters = ['Ganjil 2026/2027', 'Genap 2025/2026'];

  String _selectedSemester = 'Ganjil 2026/2027';
  AttendanceStatus? _selectedStatus;
  List<StudentAttendanceRecord> _records = const [];
  StudentAttendanceSummary _summary = const StudentAttendanceSummary(
    hadir: 0,
    izin: 0,
    sakit: 0,
    alfa: 0,
  );
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!studentAuthRepository.hasRemoteSession) {
      setState(() {
        _records = dummyAttendanceRecords;
        _summary = dummyAttendanceSummary;
        _loadError = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        studentDataService.loadAttendanceSummary(),
        studentDataService.loadAttendanceHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as StudentAttendanceSummary;
        _records = results[1] as List<StudentAttendanceRecord>;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = friendlyError(
          error,
          fallback: 'Periksa koneksi internet, lalu coba lagi.',
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = _records
        .where(
          (record) =>
              _selectedStatus == null || record.status == _selectedStatus,
        )
        .toList();

    return Scaffold(
      appBar: SkyAppBar(
        title: const Text('Riwayat'),
        titleSpacing: AppSpacing.page,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
            tooltip: 'Muat ulang',
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
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              child: ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isLoading) ...const [
                      AppSkeleton(height: 132, radius: AppRadius.lg),
                      SizedBox(height: AppSpacing.lg),
                      AppSkeletonList(rows: 4),
                    ] else if (_loadError != null)
                      AppErrorState(message: _loadError!, onRetry: _loadData)
                    else ...[
                      _SummaryCard(
                        semesters: _semesters,
                        selectedSemester: _selectedSemester,
                        onSemesterChanged: (value) =>
                            setState(() => _selectedSemester = value),
                        summary: _summary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _StatusFilter(
                        selected: _selectedStatus,
                        onChanged: (status) =>
                            setState(() => _selectedStatus = status),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: records.isEmpty
                            ? AppEmptyState(
                                icon: PhosphorIconsRegular.fileText,
                                title: _selectedStatus == null
                                    ? 'Belum ada riwayat kehadiran.'
                                    : 'Belum ada riwayat untuk status ini.',
                                message:
                                    'Catatan kehadiranmu akan tampil di sini.',
                              )
                            : Column(
                                children: [
                                  for (var i = 0; i < records.length; i++) ...[
                                    if (i > 0) const Divider(),
                                    _RecordRow(record: records[i]),
                                  ],
                                ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.semesters,
    required this.selectedSemester,
    required this.onSemesterChanged,
    required this.summary,
  });

  final List<String> semesters;
  final String selectedSemester;
  final ValueChanged<String> onSemesterChanged;
  final StudentAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total =
        summary.hadir + summary.izin + summary.sakit + summary.alfa;
    final percent = total == 0 ? 0 : (summary.hadir * 100 / total).round();

    return Card(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEDF3FF), Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          'kehadiran semester ini',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    initialValue: selectedSemester,
                    onSelected: onSemesterChanged,
                    tooltip: 'Pilih semester',
                    position: PopupMenuPosition.under,
                    itemBuilder: (context) => [
                      for (final semester in semesters)
                        PopupMenuItem(value: semester, child: Text(semester)),
                    ],
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: AppRadius.pill,
                        border: Border.all(color: AppColors.lineStrong),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedSemester,
                            style: text.labelMedium?.tabular.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            PhosphorIconsRegular.caretDown,
                            size: 14,
                            color: AppColors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: AttendanceBar(
                hadir: summary.hadir,
                izin: summary.izin,
                sakit: summary.sakit,
                alfa: summary.alfa,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.selected, required this.onChanged});

  final AttendanceStatus? selected;
  final ValueChanged<AttendanceStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ChipScroller(
      children: [
        ChoiceChip(
          label: const Text('Semua'),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final status in AttendanceStatus.values)
          ChoiceChip(
            label: Text(AttendanceVisual.of(status.name).label),
            selected: selected == status,
            onSelected: (_) => onChanged(status),
          ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final StudentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final faint = text.bodySmall?.copyWith(color: AppColors.inkFaint);
    final showDocument =
        (record.status == AttendanceStatus.izin ||
            record.status == AttendanceStatus.alfa) &&
        record.hasDocument;
    final hasTime = record.time.isNotEmpty && record.time != '-';

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 28),
              child: Text(
                record.date,
                softWrap: false,
                style: text.titleSmall?.tabular,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    record.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  if (hasTime)
                    Text(record.time, style: faint?.tabular)
                  else if (!showDocument)
                    Text('Waktu tidak tercatat', style: faint),
                  if (showDocument)
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.paperclip,
                          size: 16,
                          color: AppColors.brand700,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Surat: ${record.documentName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: AppColors.brand700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppStatusBadge.attendance(record.status.name),
          ],
        ),
      ),
    );

    if (!showDocument) return row;
    return MergeSemantics(
      child: InkWell(onTap: () => _showDocument(context, record), child: row),
    );
  }
}

void _showDocument(BuildContext context, StudentAttendanceRecord record) {
  final url = record.dokumenUrl!;
  final name = record.documentName;
  final isImage =
      RegExp(
        r'\.(jpg|jpeg|png|webp)(\?|$)',
        caseSensitive: false,
      ).hasMatch(name) ||
      RegExp(
        r'\.(jpg|jpeg|png|webp)(\?|$)',
        caseSensitive: false,
      ).hasMatch(url);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(PhosphorIconsRegular.x),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (isImage)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.control,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const AppSkeleton(
                          height: 200,
                          radius: AppRadius.md,
                        );
                      },
                      // Tanpa ini banner ikut memenuhi tinggi area pratinjau.
                      errorBuilder: (_, _, _) => const UnconstrainedBox(
                        constrainedAxis: Axis.horizontal,
                        child: AppBanner(
                          tone: StatusTone.danger,
                          message: 'Pratinjau surat gagal dimuat.',
                        ),
                      ),
                    ),
                  ),
                )
              else
                const AppBanner(
                  message: 'Pratinjau PDF belum tersedia. Salin tautan di bawah untuk membuka surat.',
                ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Tautan surat disalin.')),
                    );
                },
                child: const Text('Salin tautan surat'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
