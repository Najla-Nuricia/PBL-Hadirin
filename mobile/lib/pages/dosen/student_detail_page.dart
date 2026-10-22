// lib/pages/dosen/student_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/dosen/lecturer_providers.dart';
import '../../routing/lecturer_route_paths.dart';
import '../../theme/style/lecturer_style.dart';
import 'widgets/content_constraint.dart';
import 'widgets/decision_action_bar.dart';
import 'widgets/initials_avatar.dart';
import 'widgets/lecturer_app_bar.dart';
import 'widgets/presence_info_card.dart';
import 'widgets/rounded_back_button.dart';
import 'widgets/supporting_document_card.dart';

class StudentDetailPage extends ConsumerWidget {
  const StudentDetailPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final student = ref.watch(studentByIdProvider(studentId));
    final session = ref.watch(attendanceSessionProvider);
    final decision = ref.watch(leaveDecisionProvider)[studentId];

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: LecturerAppBar(
        title: 'Detail Mahasiswa',
        leading: RoundedBackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(LecturerRoutePaths.beranda),
        ),
      ),
      body: student == null
          ? const Center(child: Text('Data mahasiswa tidak ditemukan.'))
          : ContentConstraint(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(LecturerStyle.pagePadding),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    InitialsAvatar(
                      initials: student.initials,
                      size: 80,
                      fontSize: 26,
                      bordered: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      student.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIM ${student.nim} · Kelas ${student.className}',
                      style: TextStyle(
                        fontSize: LecturerStyle.captionSize,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PresenceInfoCard(student: student, date: session.date),
                    if (student.document != null) ...[
                      const SizedBox(height: 12),
                      SupportingDocumentCard(
                        document: student.document!,
                        onView: () {},
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
