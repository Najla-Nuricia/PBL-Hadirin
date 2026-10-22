import 'package:flutter/material.dart';

import '../../../models/dosen/date_id.dart';
import '../../../models/dosen/student_attendance.dart';
import 'section_card.dart';
import 'status_badge.dart';

class PresenceInfoCard extends StatelessWidget {
  const PresenceInfoCard({super.key, required this.student, required this.date});

  final StudentAttendance student;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Presensi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _Row(label: 'Tanggal', value: _bold(formatDateId(date))),
          const Divider(height: 1),
          _Row(label: 'Jam Absen', value: _bold(student.checkInTime ?? '-')),
          const Divider(height: 1),
          _Row(label: 'Status', value: StatusBadge(status: student.status)),
          const Divider(height: 1),
          _Row(label: 'Keterangan', value: _bold(student.note ?? '-')),
        ],
      ),
    );
  }

  Widget _bold(String text) => Text(
        text,
        textAlign: TextAlign.end,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Align(alignment: Alignment.centerRight, child: value)),
        ],
      ),
    );
  }
}