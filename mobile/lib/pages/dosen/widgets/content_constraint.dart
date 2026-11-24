import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';

/// Membatasi lebar isi dan menaruhnya di tengah pada layar lebar.
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // Tinggi mengikuti isi, supaya aman dipakai di batang bawah Scaffold.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
