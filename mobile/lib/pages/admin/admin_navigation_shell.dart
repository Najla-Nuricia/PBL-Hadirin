import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/style/navbar_style.dart';

const _adminNavbarItems = [
  (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Beranda'),
  (icon: Icons.add, selectedIcon: Icons.add, label: 'Tambah Jadwal'),
  (
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    label: 'Jadwal',
  ),
];

class AdminNavigationShell extends StatelessWidget {
  const AdminNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: navigationShell,
      bottomNavigationBar: _AdminBottomNavigationBar(
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

class _AdminBottomNavigationBar extends StatelessWidget {
  const _AdminBottomNavigationBar({
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
                  for (var index = 0; index < _adminNavbarItems.length; index++)
                    Expanded(
                      child: index == 1
                          ? _AdminCenterNavbarLabel(
                              label: _adminNavbarItems[index].label,
                              onTap: () => onTap(index),
                            )
                          : _AdminNavbarItem(
                              icon: _adminNavbarItems[index].icon,
                              selectedIcon:
                                  _adminNavbarItems[index].selectedIcon,
                              label: _adminNavbarItems[index].label,
                              selected: currentIndex == index,
                              onTap: () => onTap(index),
                            ),
                    ),
                ],
              ),
              Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: _AdminCenterNavbarButton(onTap: () => onTap(1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavbarItem extends StatelessWidget {
  const _AdminNavbarItem({
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
          Icon(selected ? selectedIcon : icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: NavbarStyle.textSize,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCenterNavbarLabel extends StatelessWidget {
  const _AdminCenterNavbarLabel({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 23),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCenterNavbarButton extends StatelessWidget {
  const _AdminCenterNavbarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.add, color: colorScheme.onPrimary, size: 28),
        ),
      ),
    );
  }
}
