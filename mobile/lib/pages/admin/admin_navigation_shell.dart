import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/style/navbar_style.dart';

/// Bottom navigation Admin: Beranda, Jadwal, Akun.
/// Tombol Tambah Jadwal tidak berada di sini — hanya di halaman Jadwal.
const _adminNavbarItems = [
  (
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Beranda',
  ),
  (
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    label: 'Jadwal',
  ),
  (
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: 'Akun',
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
          child: Row(
            children: [
              for (var index = 0; index < _adminNavbarItems.length; index++)
                Expanded(
                  child: _AdminNavbarItem(
                    icon: _adminNavbarItems[index].icon,
                    selectedIcon: _adminNavbarItems[index].selectedIcon,
                    label: _adminNavbarItems[index].label,
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
