import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/routing/admin_route_paths.dart';
import 'package:mobile/routing/admin_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  testWidgets('tahun ajaran page and tambah tahun ajaran back buttons work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAdminRouter();
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light),
    );
    await tester.pumpAndSettle();

    // Login to reach admin area
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'admin');
    await tester.enterText(loginFields.at(1), '123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.dataAkademik,
    );

    // Open Tahun Ajaran module
    await tester.tap(find.text('Tahun Ajaran'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.tahunAjaran,
    );
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    // Test back button on TahunAjaranListPage -> returns to data akademik
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.dataAkademik,
    );

    // Go back to Tahun Ajaran module
    await tester.tap(find.text('Tahun Ajaran'));
    await tester.pumpAndSettle();

    // Open Tambah Tahun Ajaran page
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Tahun Ajaran'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    // Test back button on TambahTahunAjaranPage -> returns to TahunAjaranListPage
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Tahun Ajaran'), findsWidgets);
    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.tahunAjaran,
    );
  });
}
