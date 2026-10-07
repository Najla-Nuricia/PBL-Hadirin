import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'navbar_style.dart';

final studentRouter = GoRouter(
  initialLocation: StudentRoutePaths.beranda,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return StudentNavigationShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.beranda,
              builder: (context, state) =>
                  const _StudentPagePlaceholder(title: 'Beranda'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.riwayat,
              builder: (context, state) =>
                  const _StudentPagePlaceholder(title: 'Riwayat'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.absensi,
              builder: (context, state) =>
                  const _StudentPagePlaceholder(title: 'Absensi'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.surat,
              builder: (context, state) =>
                  const _StudentPagePlaceholder(title: 'Surat'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.profil,
              builder: (context, state) =>
                  const _StudentPagePlaceholder(title: 'Profil'),
            ),
          ],
        ),
      ],
    ),
  ],
);

abstract final class StudentRoutePaths {
  static const beranda = '/mhs/beranda';
  static const riwayat = '/mhs/riwayat';
  static const absensi = '/mhs/absensi';
  static const surat = '/mhs/surat';
  static const profil = '/mhs/profil';
}

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
    return Scaffold(
      backgroundColor: NavbarStyle.scaffoldBackground,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: NavbarStyle.navbarDecoration,
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
    final color = selected ? NavbarStyle.activeItem : NavbarStyle.inactiveItem;

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
            style: selected ? NavbarStyle.activeText : NavbarStyle.inactiveText,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: NavbarStyle.normalIconSize),
        const SizedBox(height: 4),
        Text(label, style: NavbarStyle.inactiveText),
      ],
    );
  }
}

class _CenterNavbarButton extends StatelessWidget {
  const _CenterNavbarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NavbarStyle.centerButtonRadius),
        child: Ink(
          width: NavbarStyle.centerButtonSize,
          height: NavbarStyle.centerButtonSize,
          decoration: NavbarStyle.centerButtonDecoration,
          child: const Icon(
            Icons.videocam_outlined,
            color: Colors.white,
            size: NavbarStyle.centerIconSize,
          ),
        ),
      ),
    );
  }
}

class _StudentPagePlaceholder extends StatelessWidget {
  const _StudentPagePlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}
