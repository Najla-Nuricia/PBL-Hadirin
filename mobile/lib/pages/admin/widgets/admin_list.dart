import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../widgets/widgets.dart';

/// Kotak ikon bergradien di awal baris daftar.
class AdminIconSquare extends StatelessWidget {
  const AdminIconSquare(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppRadius.control,
        boxShadow: AppColors.shadowBrand,
      ),
      child: Icon(icon, size: 21, color: Colors.white),
    );
  }
}

/// Satu kartu berisi baris-baris yang dipisahkan garis tipis.
class AdminListCard extends StatelessWidget {
  const AdminListCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const Divider(),
            children[index],
          ],
        ],
      ),
    );
  }
}

/// Baris daftar: kotak ikon, judul, keterangan, lalu aksi di kanan.
class AdminListRow extends StatelessWidget {
  const AdminListRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
    this.titleMaxLines = 1,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Lencana status di bawah keterangan.
  final Widget? badge;

  /// Tombol aksi di kanan. Tanpa ini baris menampilkan panah bila [onTap]
  /// diisi.
  final Widget? trailing;
  final VoidCallback? onTap;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          // Tombol ikon sudah membawa ruang sentuhnya sendiri.
          trailing == null ? AppSpacing.lg : AppSpacing.xs,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            AdminIconSquare(icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.tabular.copyWith(
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                  if (badge != null) ...[const SizedBox(height: 6), badge!],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: AppColors.inkFaint,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(onTap: onTap, child: row),
      ),
    );
  }
}

/// Lencana status data master: hijau untuk aktif, netral untuk lainnya.
class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    required this.label,
    required this.active,
    super.key,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: label,
      tone: active ? StatusTone.success : StatusTone.neutral,
      icon: active
          ? PhosphorIconsRegular.checkCircle
          : PhosphorIconsRegular.minusCircle,
    );
  }
}

/// Kolom pencarian di atas daftar, dengan tombol hapus saat terisi.
class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    required this.controller,
    required this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(PhosphorIconsRegular.x),
                ),
        ),
      ),
    );
  }
}
