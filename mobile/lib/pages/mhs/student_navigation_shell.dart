import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/style/navbar_style.dart';

const _studentNavbarItems = [
  (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Beranda'),
  (icon: Icons.attach_money, selectedIcon: null, label: 'Riwayat'),
  (icon: Icons.videocam_outlined, selectedIcon: null, label: 'Absensi'),
  (icon: Icons.description_outlined, selectedIcon: null, label: 'Surat'),
  (icon: Icons.person_outline, selectedIcon: null, label: 'Profil'),
];

class StudentNavigationShell extends StatelessWidget {
  const StudentNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: navigationShell,
      bottomNavigationBar: _StudentBottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _StudentBottomNavigationBar extends StatelessWidget {
  const _StudentBottomNavigationBar({
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  for (
                    var index = 0;
                    index < _studentNavbarItems.length;
                    index++
                  )
                    Expanded(
                      child: index == 2
                          ? _CenterNavbarLabel(
                              label: _studentNavbarItems[index].label,
                            )
                          : _NavbarItem(
                              icon: _studentNavbarItems[index].icon,
                              selectedIcon:
                                  _studentNavbarItems[index].selectedIcon,
                              label: _studentNavbarItems[index].label,
                              selected: currentIndex == index,
                              onTap: () => onTap(index),
                            ),
                    ),
                ],
              ),
              Positioned(
                top: -22,
                left: 0,
                right: 0,
                child: Center(
                  child: _CenterNavbarButton(onTap: () => onTap(2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavbarItem extends StatelessWidget {
  const _NavbarItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData? selectedIcon;
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
            selected ? (selectedIcon ?? icon) : icon,
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

class _CenterNavbarLabel extends StatelessWidget {
  const _CenterNavbarLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: NavbarStyle.normalIconSize),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: NavbarStyle.textSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CenterNavbarButton extends StatelessWidget {
  const _CenterNavbarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NavbarStyle.centerButtonRadius),
        child: Ink(
          width: NavbarStyle.centerButtonSize,
          height: NavbarStyle.centerButtonSize,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(NavbarStyle.centerButtonRadius),
          ),
          child: Icon(
            Icons.videocam_outlined,
            color: colorScheme.onPrimary,
            size: NavbarStyle.centerIconSize,
          ),
        ),
      ),
    );
  }
}
