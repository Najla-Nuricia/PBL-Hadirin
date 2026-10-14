import 'package:flutter/material.dart';

import '../../../models/dosen/student_attendance.dart';
import '../../../theme/style/lecturer_style.dart';
import 'initials_avatar.dart';
import 'status_badge.dart';

class StudentAttendanceTile extends StatelessWidget {
  const StudentAttendanceTile({
    super.key,
    required this.student,
    required this.onTap,
  });

  final StudentAttendance student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = student.checkInTime ?? '-';
    final radius = BorderRadius.circular(LecturerStyle.tileRadius);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${student.name}, NIM ${student.nim}, '
          'status ${student.status.label}, '
          '${student.checkInTime == null ? "belum absen" : "jam $time"}. '
          'Ketuk untuk melihat detail.',
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outline),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                InitialsAvatar(initials: student.initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: LecturerStyle.bodySize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        student.nim,
                        style: TextStyle(
                          fontSize: LecturerStyle.captionSize,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 10),
                StatusBadge(status: student.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}