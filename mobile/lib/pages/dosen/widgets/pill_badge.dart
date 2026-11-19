import 'package:flutter/material.dart';

import '../../../theme/style/lecturer_style.dart';

class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.fontSize = LecturerStyle.badgeSize,
  });

  final String label;
  final Color foreground;
  final Color background;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}