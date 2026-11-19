import 'package:flutter/material.dart';

import '../../../models/dosen/attendance_session.dart';
import '../../../models/dosen/date_id.dart';
import '../../../theme/style/lecturer_style.dart';
import 'section_card.dart';

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key, required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(LecturerStyle.controlRadius),
            ),
            child: Icon(Icons.groups_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line(label: 'Kelas', value: session.className),
                const SizedBox(height: 2),
                _Line(label: 'Tanggal', value: formatDateId(session.date)),
                const SizedBox(height: 2),
                _Line(label: 'Total Mahasiswa', value: '${session.total}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}