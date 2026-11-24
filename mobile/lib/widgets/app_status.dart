import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/app_tokens.dart';

/// Tampilan baku satu status kehadiran. Dicari lewat nama enum
/// (`hadir`, `izin`, `sakit`, `alfa`) supaya enum mahasiswa dan dosen
/// memakai sumber yang sama.
class AttendanceVisual {
  const AttendanceVisual(this.label, this.icon, this.tone);

  final String label;
  final IconData icon;
  final StatusTone tone;

  static const hadir = AttendanceVisual(
    'Hadir',
    PhosphorIconsRegular.checkCircle,
    StatusTone.hadir,
  );
  static const izin = AttendanceVisual(
    'Izin',
    PhosphorIconsRegular.notePencil,
    StatusTone.izin,
  );
  static const sakit = AttendanceVisual(
    'Sakit',
    PhosphorIconsRegular.firstAidKit,
    StatusTone.sakit,
  );
  static const alfa = AttendanceVisual(
    'Alfa',
    PhosphorIconsRegular.xCircle,
    StatusTone.alfa,
  );

  static const all = [hadir, izin, sakit, alfa];

  static AttendanceVisual of(String statusName) =>
      switch (statusName.toLowerCase()) {
        'hadir' => hadir,
        'izin' => izin,
        'sakit' => sakit,
        _ => alfa,
      };
}

/// Lencana status: selalu ikon, teks, dan warna sekaligus.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    super.key,
  });

  /// Lencana kehadiran dari nama status (`hadir`, `izin`, `sakit`, `alfa`).
  factory AppStatusBadge.attendance(String statusName, {Key? key}) {
    final visual = AttendanceVisual.of(statusName);
    return AppStatusBadge(
      key: key,
      label: visual.label,
      icon: visual.icon,
      tone: visual.tone,
    );
  }

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 11 : 9, 5, 11, 5),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: tone.ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: tone.ink, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rekap kehadiran: batang bertumpuk dengan empat angka di bawahnya.
class AttendanceBar extends StatelessWidget {
  const AttendanceBar({
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alfa,
    super.key,
  });

  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final counts = [hadir, izin, sakit, alfa];
    final total = counts.fold<int>(0, (sum, n) => sum + n);

    return Semantics(
      label:
          'Rekap kehadiran: hadir $hadir, izin $izin, sakit $sakit, alfa $alfa',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: SizedBox(
              height: 8,
              child: total == 0
                  ? const ColoredBox(color: AppColors.surfaceInset)
                  : Row(
                      spacing: 2,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < counts.length; i++)
                          if (counts[i] > 0)
                            Expanded(
                              flex: counts[i],
                              child: ColoredBox(
                                color: AttendanceVisual.all[i].tone.solid,
                              ),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (index, visual) in AttendanceVisual.all.indexed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(visual.icon, size: 15, color: visual.tone.ink),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${counts[index]}',
                        style: text.labelMedium?.tabular.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        visual.label,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
