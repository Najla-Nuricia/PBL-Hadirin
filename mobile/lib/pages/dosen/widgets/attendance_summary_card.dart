import 'package:flutter/material.dart';

import '../../../models/dosen/attendance_session.dart';
import '../../../models/dosen/date_id.dart';
import '../../../widgets/widgets.dart';
import 'attendance_counts_card.dart';
import 'section_card.dart';

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key, required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final course = session.courseName?.trim() ?? '';
    final className = session.className.trim();
    final summary = session.ringkasan;
    final meta = [
      if (className.isNotEmpty) className,
      formatDateId(session.date),
    ].join(' · ');

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (course.isNotEmpty) ...[
            Text(
              course,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          // Tanpa nama mata kuliah, kelas dan tanggal menjadi judul kartu.
          Text(
            meta,
            style: course.isEmpty
                ? text.titleMedium?.tabular
                : text.bodySmall?.tabular.copyWith(color: AppColors.inkFaint),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Mahasiswa',
                  style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('${summary.total}', style: text.titleSmall?.tabular),
            ],
          ),
          if (session.students.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AttendanceCountsView(summary: summary, showTotal: false),
          ],
        ],
      ),
    );
  }
}
