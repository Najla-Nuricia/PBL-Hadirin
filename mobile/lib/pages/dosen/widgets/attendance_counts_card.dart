import 'package:flutter/material.dart';

import '../../../models/dosen/attendance_summary.dart';
import '../../../theme/style/lecturer_style.dart';
import 'section_card.dart';

/// Ringkasan jumlah Hadir / Izin / Sakit / Alfa + persentase kehadiran.
class AttendanceCountsView extends StatelessWidget {
  const AttendanceCountsView({super.key, required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = [
      ('Hadir', summary.hadir, scheme.primary),
      ('Izin', summary.izin, Colors.orange),
      ('Sakit', summary.sakit, Colors.blue),
      ('Alfa', summary.alfa, scheme.error),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value, color) in entries)
              _CountChip(label: label, value: value, color: color),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Total: ${summary.total} mahasiswa',
                style: TextStyle(
                  fontSize: LecturerStyle.captionSize,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '${summary.persentaseKehadiran}% hadir',
              style: TextStyle(
                fontSize: LecturerStyle.captionSize,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
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
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          AttendanceCountsView(summary: summary),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(LecturerStyle.controlRadius),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label '),
            TextSpan(text: '$value', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        style: TextStyle(fontSize: LecturerStyle.captionSize, color: scheme.onSurface),
      ),
    );
  }
}
