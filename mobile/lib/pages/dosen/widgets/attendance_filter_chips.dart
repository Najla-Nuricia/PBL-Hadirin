import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/dosen/lecturer_providers.dart';
import '../../../models/dosen/attendance_status.dart';

/// Skeleton filter status. Hapus dari halaman bila tidak dibutuhkan.
class AttendanceFilterChips extends ConsumerWidget {
  const AttendanceFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(attendanceFilterProvider);
    final notifier = ref.read(attendanceFilterProvider.notifier);

    Widget chip(String label, bool isSelected, VoidCallback onTap) {
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outline,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Semua', selected == null, () => notifier.select(null)),
          for (final status in AttendanceStatus.values) ...[
            const SizedBox(width: 8),
            chip(status.label, selected == status, () => notifier.select(status)),
          ],
        ],
      ),
    );
  }
}