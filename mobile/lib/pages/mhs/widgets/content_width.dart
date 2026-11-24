import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';

/// Menjaga isi halaman selebar [AppSizes.contentMaxWidth] dan di tengah pada
/// tablet atau desktop.
class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // Tanpa ini Align memenuhi tinggi induknya saat dipakai di bilah bawah.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: child,
      ),
    );
  }
}
