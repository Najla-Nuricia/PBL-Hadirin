import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../widgets/widgets.dart';

const _lecturerNavbarItems = [
  (
    icon: PhosphorIconsRegular.clipboardText,
    selectedIcon: PhosphorIconsFill.clipboardText,
    label: 'Kehadiran',
    branchIndex: 1,
  ),
  (
    icon: PhosphorIconsRegular.userCircle,
    selectedIcon: PhosphorIconsFill.userCircle,
    label: 'Profil',
    branchIndex: 2,
  ),
];

class LecturerNavigationShell extends StatelessWidget {
  const LecturerNavigationShell({
    required this.navigationShell,
    this.showNavbar = true,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final bool showNavbar;

  /// Cabang Beranda menampilkan layar yang sama dengan Kehadiran, jadi tab
  /// Kehadiran yang ditandai saat cabang itu aktif.
  int get _selectedIndex {
    final index = _lecturerNavbarItems.indexWhere(
      (item) => item.branchIndex == navigationShell.currentIndex,
    );
    return index < 0 ? 0 : index;
  }

  void _select(int index) {
    final branchIndex = _lecturerNavbarItems[index].branchIndex;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: showNavbar
          ? GlassDock(
              child: NavigationBar(
                selectedIndex: selectedIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: _select,
                destinations: [
                  for (final (index, item) in _lecturerNavbarItems.indexed)
                    // Appium memilih tab lewat accessibility id yang sama
                    // persis dengan labelnya. Semantik bawaan menambahkan
                    // urutan tab ke label, jadi diganti di sini.
                    Semantics(
                      container: true,
                      button: true,
                      selected: index == selectedIndex,
                      label: item.label,
                      onTap: () => _select(index),
                      excludeSemantics: true,
                      child: NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
