import 'package:flutter/material.dart';

import '../../../models/dosen/attendance_summary.dart';
import '../../../widgets/widgets.dart';
import 'section_card.dart';

/// Rekap Hadir / Izin / Sakit / Alfa dengan total dan persentase kehadiran.
class AttendanceCountsView extends StatelessWidget {
  const AttendanceCountsView({
    super.key,
    required this.summary,
    this.showTotal = true,
  });

  final AttendanceSummary summary;

  /// Matikan bila total sudah tampil di tempat lain pada kartu yang sama.
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.bodySmall?.tabular;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttendanceBar(
          hadir: summary.hadir,
          izin: summary.izin,
          sakit: summary.sakit,
          alfa: summary.alfa,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            if (showTotal)
              Expanded(
                child: Text(
                  'Total: ${summary.total} mahasiswa',
                  style: caption?.copyWith(color: AppColors.inkMuted),
                ),
              ),
            Text(
              '${summary.persentaseKehadiran}% hadir',
              style: caption?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class AttendanceCountsCard extends StatelessWidget {
  const AttendanceCountsCard({
    super.key,
    required this.summary,
    this.title = 'Ringkasan Kehadiran',
  });

  final AttendanceSummary summary;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          AttendanceCountsView(summary: summary),
        ],
      ),
    );
  }
}
