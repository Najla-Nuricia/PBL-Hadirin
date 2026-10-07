import 'package:flutter/material.dart';

abstract final class NavbarStyle {
  static const Color scaffoldBackground = Color(0xFFF8F9FA);
  static const Color navbarBackground = Color(0xFFFFFFFF);
  static const Color activeItem = Color(0xFF2D7CFF);
  static const Color inactiveItem = Color(0xFF9E9E9E);
  static const Color centerButton = Color(0xFF1C75FF);

  static const double navbarHeight = 70;
  static const double normalIconSize = 26;
  static const double centerIconSize = 30;
  static const double centerButtonSize = 56;
  static const double centerButtonRadius = 16;
  static const double textSize = 11;

  static const TextStyle activeText = TextStyle(
    color: activeItem,
    fontSize: textSize,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle inactiveText = TextStyle(
    color: inactiveItem,
    fontSize: textSize,
    fontWeight: FontWeight.w500,
  );

  static final BoxDecoration navbarDecoration = BoxDecoration(
    color: navbarBackground,
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, -5),
      ),
    ],
  );

  static final BoxDecoration centerButtonDecoration = BoxDecoration(
    color: centerButton,
    borderRadius: BorderRadius.circular(centerButtonRadius),
    // boxShadow: [
    //   BoxShadow(
    //     color: centerButton.withValues(alpha: 0.4),
    //     blurRadius: 10,
    //     offset: const Offset(0, 4),
    //   ),
    // ],
  );
}
