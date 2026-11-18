// lib/pages/admin/widgets/master_data_list_widgets.dart
import 'package:flutter/material.dart';

/// Kerangka halaman daftar master data (judul + tombol tambah + pencarian).
class MasterDataListScaffold extends StatelessWidget {
  const MasterDataListScaffold({
    super.key,
    required this.title,
    required this.searchHint,
    required this.searchController,
    required this.onAdd,
    required this.onBack,
    required this.body,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String searchHint;
  final TextEditingController searchController;
  final VoidCallback onAdd;
  final VoidCallback onBack;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: cs.primary,
                    ),
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Tambah',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: searchController,
                style: TextStyle(color: cs.onSurface, fontSize: 13),
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary),
                  ),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Kartu satu baris data master dengan aksi ubah & hapus.
class MasterDataCard extends StatelessWidget {
  const MasterDataCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.statusLabel,
    this.statusIsPositive = true,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? statusLabel;
  final bool statusIsPositive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (statusLabel != null) ...[
                      const SizedBox(width: 8),
                      _StatusBadge(
                        label: statusLabel!,
                        positive: statusIsPositive,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(height: 6), trailing!],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
            color: cs.primary,
            tooltip: 'Ubah',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            color: cs.error,
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final background = positive
        ? cs.secondaryContainer
        : cs.surfaceContainerHighest;
    final foreground = positive ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Keadaan kosong saat daftar tidak memiliki data.
class MasterDataEmptyState extends StatelessWidget {
  const MasterDataEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Dialog konfirmasi hapus; mengembalikan true bila pengguna setuju.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return result ?? false;
}
