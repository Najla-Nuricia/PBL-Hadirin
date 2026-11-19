import 'package:flutter/material.dart';

import '../../../theme/style/lecturer_style.dart';

class LecturerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LecturerAppBar({
    super.key,
    required this.title,
    this.leading,
    this.titleSize = LecturerStyle.appBarTitleSize,
  });

  final String title;
  final Widget? leading;
  final double titleSize;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      leading: leading,
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: scheme.outline)),
      title: Text(
        title,
        style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w700),
      ),
    );
  }
}