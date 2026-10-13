import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/routing/admin_route_paths.dart';
import 'package:mobile/routing/admin_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  testWidgets('admin login opens academic data and admin navbar works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = adminRouter;
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.login,
    );
    expect(find.text('Login Sekretaris Jurusan'), findsOneWidget);
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'admin');
    await tester.enterText(loginFields.at(1), '123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.dataAkademik,
    );
    expect(find.text('Data Akademik'), findsOneWidget);
    expect(find.text('Tahun Ajaran'), findsOneWidget);
    expect(find.text('Mata Kuliah'), findsOneWidget);
    expect(find.text('Dosen'), findsOneWidget);
    expect(find.text('Kelas'), findsOneWidget);
    expect(find.text('Ruangan'), findsOneWidget);
    expect(find.text('Tambah Jadwal'), findsOneWidget);

    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.jadwal,
    );

    await tester.tap(find.text('Tambah Jadwal'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.tambahJadwal,
    );
  });
}
