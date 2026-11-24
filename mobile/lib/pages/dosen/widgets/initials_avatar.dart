import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';
import '../../../theme/style/lecturer_style.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = LecturerStyle.rowLeadingSize,
  });

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = size >= LecturerStyle.headerAvatarSize
        ? text.titleLarge
        : text.titleSmall;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brand100,
        ),
        child: Text(
          initials,
          maxLines: 1,
          // Lingkaran berukuran tetap, jadi inisial tidak ikut skala teks.
          textScaler: TextScaler.noScaling,
          style: style?.copyWith(
            color: AppColors.brand800,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
