import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../models/dosen/student_attendance.dart';
import '../../../widgets/widgets.dart';

/// Baris dokumen pendukung, dipasang di dalam kartu pengajuan.
class SupportingDocumentCard extends StatelessWidget {
  const SupportingDocumentCard({
    super.key,
    required this.document,
    this.onView,
  });

  final SupportingDocument document;

  /// Membuka dokumen. Tanpa aksi, tombol lihat tampil nonaktif.
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fileName = document.fileName.trim();
    final caption = [
      if (fileName.isNotEmpty) 'Dokumen Pendukung',
      if (document.sizeLabel.isNotEmpty) document.sizeLabel,
    ].join(' · ');
    final previewUrl = document.previewUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceInset,
            borderRadius: AppRadius.control,
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.fileText, color: AppColors.inkMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fileName.isEmpty ? 'Dokumen Pendukung' : fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    if (caption.isNotEmpty)
                      Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.tabular.copyWith(
                          color: AppColors.inkFaint,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Lihat dokumen',
                onPressed: onView,
                color: scheme.primary,
                icon: const Icon(PhosphorIconsRegular.eye),
              ),
            ],
          ),
        ),
        if (previewUrl != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.control,
            child: Image.network(
              previewUrl,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ],
    );
  }
}
