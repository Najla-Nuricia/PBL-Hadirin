// lib/pages/dosen/attendance_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/dosen/lecturer_providers.dart';
import '../../models/dosen/attendance_session.dart';
import '../../routing/lecturer_route_paths.dart';
import '../../theme/style/lecturer_style.dart';
import '../../widgets/widgets.dart';
import 'widgets/attendance_filter_chips.dart';
import 'widgets/attendance_summary_card.dart';
import 'widgets/content_constraint.dart';
import 'widgets/info_banner.dart';
import 'widgets/lecturer_app_bar.dart';
import 'widgets/load_state.dart';
import 'widgets/section_card.dart';
import 'widgets/student_attendance_tile.dart';

class AttendanceListPage extends ConsumerWidget {
  const AttendanceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(attendanceSessionProvider);

    final Widget body;
    if (sessionAsync.showsError) {
      body = Center(
        child: SingleChildScrollView(
          child: AppErrorState(
            message: lecturerErrorMessage(sessionAsync.error!),
            onRetry: () => ref.invalidate(attendanceSessionProvider),
          ),
        ),
      );
    } else if (sessionAsync.isLoading || !sessionAsync.hasValue) {
      // Termasuk saat memuat ulang: daftar kelas lain tidak boleh sempat
      // terlihat sebelum data pilihan baru tiba.
      body = const _LoadingBody();
    } else {
      body = _SessionBody(session: sessionAsync.requireValue);
    }

    return Scaffold(
      appBar: LecturerAppBar(
        title: 'Daftar Kehadiran',
        onBack: () => context.canPop()
            ? context.pop()
            : context.go(LecturerRoutePaths.beranda),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(filteredStudentsProvider);
    final noAttendanceYet = session.isDemo && session.students.isEmpty;

    return SingleChildScrollView(
      padding: LecturerStyle.pageInsets,
      child: ContentConstraint(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session.isDemo && !noAttendanceYet) ...[
              const AppBanner(
                tone: StatusTone.neutral,
                message:
                    'Belum ada data sesi presensi. Menampilkan data contoh.',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AttendanceSummaryCard(session: session),
            const SizedBox(height: AppSpacing.lg),
            const AttendanceFilterChips(),
            const SizedBox(height: AppSpacing.md),
            if (students.isEmpty)
              AppEmptyState(
                icon: PhosphorIconsRegular.usersThree,
                title: noAttendanceYet
                    ? 'Belum ada mahasiswa yang absen.'
                    : 'Tidak ada mahasiswa dengan status ini.',
                message: noAttendanceYet
                    ? 'Daftar mahasiswa tampil di sini setelah ada yang '
                          'presensi.'
                    : null,
              )
            else ...[
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (index, student) in students.indexed) ...[
                      if (index > 0) const Divider(),
                      StudentAttendanceTile(
                        student: student,
                        onTap: () => context.push(
                          LecturerRoutePaths.studentDetail(student.id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const InfoBanner(
                message: 'Ketuk nama mahasiswa untuk melihat detail.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: LecturerStyle.pageInsets,
      child: ContentConstraint(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: 180, height: 16),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton(width: 140, height: 12),
                  SizedBox(height: AppSpacing.lg),
                  AppSkeleton(height: 10),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            AppSkeletonList(rows: 6),
          ],
        ),
      ),
    );
  }
}
