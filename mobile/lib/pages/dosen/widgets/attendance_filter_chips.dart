import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/dosen/lecturer_providers.dart';
import '../../../models/dosen/attendance_status.dart';
import '../../../theme/app_tokens.dart';

/// Filter status daftar kehadiran.
class AttendanceFilterChips extends ConsumerWidget {
  const AttendanceFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(attendanceFilterProvider);
    final notifier = ref.read(attendanceFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Saat digeser, chip boleh melewati jarak tepi layar.
      clipBehavior: Clip.none,
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Semua'),
            selected: selected == null,
            onSelected: (_) => notifier.select(null),
          ),
          for (final status in AttendanceStatus.values)
            ChoiceChip(
              label: Text(status.label),
              selected: selected == status,
              onSelected: (_) => notifier.select(status),
            ),
        ],
      ),
    );
  }
}
