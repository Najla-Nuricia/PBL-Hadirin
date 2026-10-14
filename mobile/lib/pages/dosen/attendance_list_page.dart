// lib/pages/dosen/attendance_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/dosen/lecturer_providers.dart';
import '../../routing/lecturer_route_paths.dart';
import '../../theme/style/lecturer_style.dart';
import 'widgets/attendance_filter_chips.dart';
import 'widgets/attendance_summary_card.dart';
import 'widgets/content_constraint.dart';
import 'widgets/info_banner.dart';
import 'widgets/lecturer_app_bar.dart';
import 'widgets/rounded_back_button.dart';
import 'widgets/student_attendance_tile.dart';

class AttendanceListPage extends ConsumerWidget {
  const AttendanceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final session = ref.watch(attendanceSessionProvider);
    final students = ref.watch(filteredStudentsProvider);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: LecturerAppBar(
        title: 'Daftar Kehadiran',
        leading: RoundedBackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(LecturerRoutePaths.beranda),
        ),
      ),
      body: ContentConstraint(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LecturerStyle.pagePadding,
                LecturerStyle.pagePadding,
                LecturerStyle.pagePadding,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AttendanceSummaryCard(session: session),
                  const SizedBox(height: 12),
                  const AttendanceFilterChips(),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            if (students.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Tidak ada mahasiswa dengan status ini.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LecturerStyle.pagePadding,
                ),
                sliver: SliverList.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: LecturerStyle.listGap),
                  itemBuilder: (context, i) {
                    final s = students[i];
                    return StudentAttendanceTile(
                      student: s,
                      onTap: () =>
                          context.push(LecturerRoutePaths.studentDetail(s.id)),
                    );
                  },
                ),
              ),
            const SliverPadding(
              padding: EdgeInsets.all(LecturerStyle.pagePadding),
              sliver: SliverToBoxAdapter(
                child: InfoBanner(
                  message: 'Ketuk nama mahasiswa untuk melihat detail.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
