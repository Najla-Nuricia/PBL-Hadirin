import 'package:flutter/material.dart';

import '../../../theme/style/lecturer_style.dart';

/// Kartu selebar isi layar dengan jarak dalam baku.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = LecturerStyle.cardInsets,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        // Label dan nilai dibaca satu per satu, tidak dilebur menjadi satu
        // simpul semantik sekartu; pembaca layar dan Appium mencarinya
        // per teks.
        semanticContainer: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
