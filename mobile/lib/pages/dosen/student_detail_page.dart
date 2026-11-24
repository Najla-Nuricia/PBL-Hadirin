// lib/pages/dosen/student_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/dosen/lecturer_providers.dart';
import '../../models/dosen/student_attendance.dart';
import '../../routing/lecturer_route_paths.dart';
import '../../theme/style/lecturer_style.dart';
import '../../widgets/widgets.dart';
import 'widgets/content_constraint.dart';
import 'widgets/decision_action_bar.dart';
import 'widgets/initials_avatar.dart';
import 'widgets/lecturer_app_bar.dart';
import 'widgets/load_state.dart';
import 'widgets/presence_info_card.dart';
import 'widgets/section_card.dart';
import 'widgets/supporting_document_card.dart';

class StudentDetailPage extends ConsumerWidget {
  const StudentDetailPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentByIdProvider(studentId));
    final sessionAsync = ref.watch(attendanceSessionProvider);
    final decision = ref.watch(leaveDecisionProvider)[studentId];

    final Widget body;
    if (student != null) {
      body = _StudentDetail(
        student: student,
        date: sessionAsync.value?.date ?? DateTime.now(),
      );
    } else if (sessionAsync.showsError) {
      body = Center(
        child: SingleChildScrollView(
          child: AppErrorState(
            message: lecturerErrorMessage(sessionAsync.error!),
            onRetry: () => ref.invalidate(attendanceSessionProvider),
          ),
        ),
      );
    } else if (sessionAsync.isLoading) {
      body = const _LoadingBody();
    } else {
      body = const Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            icon: PhosphorIconsRegular.userFocus,
            title: 'Data mahasiswa tidak ditemukan.',
            message: 'Kembali ke daftar kehadiran, lalu pilih mahasiswa lagi.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: LecturerAppBar(
        title: 'Detail Mahasiswa',
        onBack: () => context.canPop()
            ? context.pop()
            : context.go(LecturerRoutePaths.beranda),
      ),
      body: SafeArea(top: false, child: body),
      bottomNavigationBar: (student != null && student.status.needsReview)
          ? DecisionActionBar(
              decision: decision,
              onAccept: () => _decide(context, ref, LeaveDecision.accepted),
              onReject: () => _decide(context, ref, LeaveDecision.rejected),
            )
          : null,
    );
  }

  void _decide(BuildContext context, WidgetRef ref, LeaveDecision d) {
    ref.read(leaveDecisionProvider.notifier).decide(studentId, d);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          d == LeaveDecision.accepted
              ? 'Pengajuan diterima.'
              : 'Pengajuan ditolak.',
        ),
      ),
    );
  }
}

class _StudentDetail extends StatelessWidget {
  const _StudentDetail({required this.student, required this.date});

  final StudentAttendance student;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final document = student.document;
    final needsReview = student.status.needsReview;
    final hasRequest = needsReview || student.note != null || document != null;
    final identity = [
      'NIM ${student.nim}',
      if (student.className.isNotEmpty) 'Kelas ${student.className}',
    ].join(' · ');

    return SingleChildScrollView(
      padding: LecturerStyle.pageInsets,
      child: ContentConstraint(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                InitialsAvatar(
                  initials: student.initials,
                  size: LecturerStyle.headerAvatarSize,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        student.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        identity,
                        style: text.bodyMedium?.tabular.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const AppSectionHeader(title: 'Informasi Presensi'),
            PresenceInfoCard(student: student, date: date),
            if (hasRequest) ...[
              // Catatan tanpa pengajuan tetap tampil, hanya tanpa judul.
              if (needsReview) ...[
                const SizedBox(height: AppSpacing.sm),
                const AppSectionHeader(title: 'Pengajuan'),
              ] else
                const SizedBox(height: AppSpacing.md),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Keterangan',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.inkFaint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(student.note ?? '-', style: text.bodyMedium),
                    if (document != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      // Pratinjau dokumen belum tersedia, jadi tombol
                      // lihatnya tampil nonaktif.
                      SupportingDocumentCard(document: document),
                    ],
                  ],
                ),
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
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                AppSkeleton(
                  width: LecturerStyle.headerAvatarSize,
                  height: LecturerStyle.headerAvatarSize,
                  radius: LecturerStyle.headerAvatarSize / 2,
                ),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 180, height: 20),
                      SizedBox(height: AppSpacing.sm),
                      AppSkeleton(width: 140),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xxl),
            AppSkeletonList(),
          ],
        ),
      ),
    );
  }
}
