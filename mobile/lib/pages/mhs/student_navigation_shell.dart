import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../widgets/widgets.dart';

const _absensiIndex = 2;

const _studentNavbarItems = [
  (
    icon: PhosphorIconsRegular.house,
    selectedIcon: PhosphorIconsFill.house,
    label: 'Beranda',
  ),
  (
    icon: PhosphorIconsRegular.clockCounterClockwise,
    selectedIcon: PhosphorIconsFill.clockCounterClockwise,
    label: 'Riwayat',
  ),
  (
    icon: PhosphorIconsRegular.scan,
    selectedIcon: PhosphorIconsFill.scan,
    label: 'Absensi',
  ),
  (
    icon: PhosphorIconsRegular.fileText,
    selectedIcon: PhosphorIconsFill.fileText,
    label: 'Surat',
  ),
  (
    icon: PhosphorIconsRegular.userCircle,
    selectedIcon: PhosphorIconsFill.userCircle,
    label: 'Profil',
  ),
];

class StudentNavigationShell extends StatelessWidget {
  const StudentNavigationShell({
    required this.navigationShell,
    this.showNavbar = true,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final bool showNavbar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: showNavbar
          ? GlassDock(
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
                  for (final (index, item) in _studentNavbarItems.indexed)
                    if (index == _absensiIndex)
                      // Aksi utama mahasiswa ditonjolkan sebagai tombol bulat
                      // bergradien di tengah dock, terpilih atau tidak.
                      NavigationDestination(
                        icon: _ScanOrb(icon: item.icon),
                        selectedIcon: _ScanOrb(icon: item.selectedIcon),
                        label: item.label,
                      )
                    else
                      NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                ],
              ),
            )
          : null,
    );
  }
}

class _ScanOrb extends StatelessWidget {
  const _ScanOrb({required this.icon});

  final IconData icon;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    // Tempat yang dipesan tetap seukuran ikon biasa supaya label "Absensi"
    // sebaris dengan label lain; bulatan meluber ke atas tanpa menggeser.
    return SizedBox.square(
      dimension: 24,
      child: OverflowBox(
        maxWidth: _size,
        maxHeight: _size,
        child: Transform.translate(
          offset: const Offset(0, -3),
          child: Container(
            width: _size,
            height: _size,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
              boxShadow: AppColors.shadowBrand,
            ),
            child: Icon(icon, size: 21, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
