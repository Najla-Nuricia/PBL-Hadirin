import 'package:flutter/material.dart';

import '../../../models/dosen/date_id.dart';
import '../../../models/dosen/student_attendance.dart';
import '../../../theme/style/lecturer_style.dart';
import '../../../widgets/widgets.dart';
import 'section_card.dart';
import 'status_badge.dart';

class PresenceInfoCard extends StatelessWidget {
  const PresenceInfoCard({
    super.key,
    required this.student,
    required this.date,
  });

  final StudentAttendance student;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final value = Theme.of(context).textTheme.titleSmall?.tabular;

    return SectionCard(
      padding: LecturerStyle.detailCardInsets,
      child: Column(
        children: [
          AppKeyValueRow(
            label: 'Status',
            trailing: StatusBadge(status: student.status),
          ),
          const Divider(),
          AppKeyValueRow(
            label: 'Tanggal',
            trailing: Text(
              formatDateId(date),
              textAlign: TextAlign.right,
              style: value,
            ),
          ),
          const Divider(),
          AppKeyValueRow(
            label: 'Jam Absen',
            trailing: Text(student.checkInTime ?? '-', style: value),
          ),
        ],
      ),
    );
  }
}
