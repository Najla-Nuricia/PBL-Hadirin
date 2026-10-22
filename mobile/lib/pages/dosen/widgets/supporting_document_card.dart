import 'package:flutter/material.dart';

import '../../../models/dosen/student_attendance.dart';
import '../../../theme/style/lecturer_style.dart';
import 'section_card.dart';

class SupportingDocumentCard extends StatelessWidget {
  const SupportingDocumentCard({
    super.key,
    required this.document,
    required this.onView,
  });

  final SupportingDocument document;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dokumen Pendukung',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.insert_drive_file_outlined,
                    size: 20, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      document.sizeLabel,
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Lihat dokumen',
                onPressed: onView,
                icon: Icon(Icons.visibility_outlined, color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Preview(url: document.previewUrl),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
        const SizedBox(height: 6),
        Text(
          'Preview Dokumen',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );

    return Container(
      height: 160,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(LecturerStyle.controlRadius),
        border: Border.all(color: scheme.outline),
      ),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}