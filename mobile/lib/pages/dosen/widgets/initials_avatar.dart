import 'package:flutter/material.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    this.fontSize = 12,
    this.bordered = false,
  });

  final String initials;
  final double size;
  final double fontSize;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bordered ? scheme.surface : scheme.primaryContainer,
        border: bordered ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}