import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../widgets/widgets.dart';

const _adminNavbarItems = [
  (
    icon: PhosphorIconsRegular.house,
    selectedIcon: PhosphorIconsFill.house,
    label: 'Beranda',
  ),
  (
    icon: PhosphorIconsRegular.plusCircle,
    selectedIcon: PhosphorIconsFill.plusCircle,
    label: 'Tambah Jadwal',
  ),
  (
    icon: PhosphorIconsRegular.calendarBlank,
    selectedIcon: PhosphorIconsFill.calendarBlank,
    label: 'Jadwal',
  ),
];

class AdminNavigationShell extends StatelessWidget {
  const AdminNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: GlassDock(
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            for (final item in _adminNavbarItems)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }
}
