import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/routing/admin_router.dart';
import 'package:mobile/routing/student_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  testWidgets('menu master data membuka list dan form Ruangan/Dosen/Kelas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAdminRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light),
    );
    await tester.pumpAndSettle();

    // Masuk ke area admin (fallback demo aktif di environment flutter test).
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'admin');
    await tester.enterText(loginFields.at(1), '123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.dataAkademik,
    );

    // Ruangan: list -> form -> kembali.
    await tester.ensureVisible(find.text('Ruangan').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ruangan').first);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.ruangan,
    );
    expect(find.text('Tambah'), findsOneWidget);
    expect(find.byTooltip('Kembali'), findsOneWidget);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Ruangan'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.ruangan,
    );
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    // Dosen: list -> form dengan field sesuai kontrak API.
    await tester.ensureVisible(find.text('Dosen').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dosen').first);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.dosen,
    );
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Dosen'), findsOneWidget);
    // NIP, Nama, Email, No. HP — tanpa prodi/status yang bukan field API.
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    // Kelas: list -> form dengan validasi kapasitas/tingkat/status.
    await tester.ensureVisible(find.text('Kelas').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kelas').first);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.kelas,
    );
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Kelas'), findsOneWidget);
    // Nama + kapasitas, serta 4 dropdown: tahun ajaran, prodi, tingkat, status.
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
      findsNWidgets(4),
    );
  });

  testWidgets('default studentRouter memuat rute list Ruangan/Dosen/Kelas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Aplikasi-default memakai studentRouter (APP_ROLE=student), yang juga
    // mendaftarkan seluruh rute admin — termasuk tiga halaman list baru.
    final router = createStudentRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light),
    );
    await tester.pumpAndSettle();

    const modules = {
      'Ruangan': AdminRoutePaths.ruangan,
      'Dosen': AdminRoutePaths.dosen,
      'Kelas': AdminRoutePaths.kelas,
    };
    for (final entry in modules.entries) {
      router.go(AdminRoutePaths.dataAkademik);
      await tester.pumpAndSettle();

      final menu = find.text(entry.key).first;
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        entry.value,
        reason: 'Menu ${entry.key} harus membuka ${entry.value}',
      );
      expect(find.text('Tambah'), findsOneWidget);
      expect(find.byTooltip('Kembali'), findsOneWidget);
    }
  });
}
