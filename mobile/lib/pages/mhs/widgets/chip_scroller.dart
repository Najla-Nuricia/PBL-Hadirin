import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';

/// Deret chip pilihan yang bisa digulir mendatar.
class ChipScroller extends StatelessWidget {
  const ChipScroller({required this.children, this.controller, super.key});

  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    // Di ponsel isi halaman selebar layar, jadi chip yang tergulir dibiarkan
    // terlihat sampai tepi layar. Di layar lebar deret dipotong selebar isi.
    final fillsScreen =
        MediaQuery.sizeOf(context).width <=
        AppSizes.contentMaxWidth + AppSpacing.page * 2;

    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      clipBehavior: fillsScreen ? Clip.none : Clip.hardEdge,
      child: Row(spacing: AppSpacing.sm, children: children),
    );
  }
}
