import 'package:flutter/material.dart';

import '../../../models/dosen/attendance_status.dart';
import '../../../widgets/widgets.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge.attendance(status.name);
  }
}
