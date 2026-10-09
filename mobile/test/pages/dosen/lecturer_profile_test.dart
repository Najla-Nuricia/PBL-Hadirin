import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/routing/lecturer_route_paths.dart';
import 'package:mobile/routing/student_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  testWidgets('lecturer profile and navigation are available', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createStudentRouter();
    addTearDown(router.dispose);
    router.go(LecturerRoutePaths.profil);

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light),
    );
    await tester.pumpAndSettle();

    expect(find.text('Informasi Akun'), findsOneWidget);
    expect(find.text('Dr. Andi Pratama, S.T., M.Kom.'), findsOneWidget);
    expect(find.text('NIP/NIDN'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Kehadiran'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lecturer-change-password')));
    await tester.pumpAndSettle();
    expect(find.text('Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Masukkan ulang kata sandi'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      LecturerRoutePaths.profil,
    );

    await tester.tap(find.text('Kehadiran'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      LecturerRoutePaths.kehadiran,
    );
  });
}
