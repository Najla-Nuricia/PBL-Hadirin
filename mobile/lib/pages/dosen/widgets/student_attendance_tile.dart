import 'package:flutter/material.dart';

import '../../../models/dosen/student_attendance.dart';
import '../../../theme/style/lecturer_style.dart';
import '../../../widgets/widgets.dart';
import 'initials_avatar.dart';
import 'status_badge.dart';

/// Satu baris mahasiswa di dalam kartu daftar kehadiran.
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
    final text = Theme.of(context).textTheme;
    final time = student.checkInTime ?? '-';
    final subtitle = student.checkInTime == null
        ? student.nim
        : '${student.nim} · $time';

    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label:
          '${student.name}, NIM ${student.nim}, '
          'status ${student.status.label}, '
          '${student.checkInTime == null ? "belum absen" : "jam $time"}. '
          'Ketuk untuk melihat detail.',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: LecturerStyle.rowMinHeight,
          ),
          child: Padding(
            padding: LecturerStyle.rowInsets,
            child: Row(
              children: [
                InitialsAvatar(initials: student.initials),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.tabular.copyWith(
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                StatusBadge(status: student.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
