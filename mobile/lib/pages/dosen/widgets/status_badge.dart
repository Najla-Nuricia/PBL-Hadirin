import 'package:flutter/material.dart';

import '../../../models/dosen/attendance_status.dart';
import 'pill_badge.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (fg, bg) = switch (status) {
      AttendanceStatus.hadir => (s.onSecondaryContainer, s.secondaryContainer),
      AttendanceStatus.izin => (s.onTertiaryContainer, s.tertiaryContainer),
      AttendanceStatus.sakit => (s.onPrimaryContainer, s.primaryContainer),
      AttendanceStatus.alfa => (s.onErrorContainer, s.errorContainer),
    };
    return PillBadge(label: status.label, foreground: fg, background: bg);
  }
}