import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../widgets/widgets.dart';

class LecturerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LecturerAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  final String title;

  /// Bila diisi, tombol kembali tampil di kiri judul.
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + SkyAppBar.cloudEdgeHeight);

  @override
  Widget build(BuildContext context) {
    return SkyAppBar(
      automaticallyImplyLeading: false,
      leading: onBack == null
          ? null
          : IconButton(
              tooltip: 'Kembali',
              onPressed: onBack,
              icon: const Icon(PhosphorIconsRegular.arrowLeft),
            ),
      title: Text(title),
      actions: actions,
    );
  }
}
