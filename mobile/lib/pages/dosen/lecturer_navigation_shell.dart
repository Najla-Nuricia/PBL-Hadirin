import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/style/navbar_style.dart';

const _lecturerNavbarItems = [
  (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Beranda'),
  (
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check,
    label: 'Kehadiran',
  ),
  (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profil'),
];

class LecturerNavigationShell extends StatelessWidget {
  const LecturerNavigationShell({
    required this.navigationShell,
    this.showNavbar = true,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final bool showNavbar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: navigationShell,
      bottomNavigationBar: showNavbar
          ? _LecturerBottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            )
          : null,
    );
  }
}

class _LecturerBottomNavigationBar extends StatelessWidget {
  const _LecturerBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: NavbarStyle.navbarHeight,
          child: Row(
            children: [
              for (var index = 0; index < _lecturerNavbarItems.length; index++)
                Expanded(
                  child: _LecturerNavbarItem(
                    icon: _lecturerNavbarItems[index].icon,
                    selectedIcon: _lecturerNavbarItems[index].selectedIcon,
                    label: _lecturerNavbarItems[index].label,
                    selected: currentIndex == index,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LecturerNavbarItem extends StatelessWidget {
  const _LecturerNavbarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? selectedIcon : icon,
            size: NavbarStyle.normalIconSize,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: NavbarStyle.textSize,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
