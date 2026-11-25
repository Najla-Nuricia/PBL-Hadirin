import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:go_router/go_router.dart';

class LecturerShellPage extends StatelessWidget {
  const LecturerShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.house),
              selectedIcon: Icon(PhosphorIconsFill.house),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.clipboardText),
              selectedIcon: Icon(PhosphorIconsFill.clipboardText),
              label: 'Kehadiran',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.user),
              selectedIcon: Icon(PhosphorIconsFill.user),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
