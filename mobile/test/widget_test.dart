import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/demo_counter_app.dart';
import 'package:mobile/main.dart';
import 'package:mobile/routing/student_router.dart';

void main() {
  testWidgets('student navbar and pages navigate correctly', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const HadirinApp());
    await tester.pumpAndSettle();

    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.beranda,
    );
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Absensi'), findsWidgets);
    expect(find.text('Surat'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);

    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();
    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.riwayat,
    );

    await tester.tap(find.text('Profil').first);
    await tester.pumpAndSettle();
    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.profil,
    );
    expect(find.text('Informasi Akun'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-change-password')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('profile-change-password')));
    await tester.pumpAndSettle();
    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.changePassword,
    );
    expect(find.text('Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.beranda,
    );

    await tester.tap(find.text('Surat').first);
    await tester.pumpAndSettle();
    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.surat,
    );
    expect(find.text('Upload Surat'), findsOneWidget);
    expect(find.text('Pilih mata kuliah...'), findsOneWidget);
    expect(find.text('Kirim Surat'), findsOneWidget);

    await tester.tap(find.text('Upload Surat Kompensasi'));
    await tester.pumpAndSettle();
    expect(find.text('Unggah surat kompensasi'), findsOneWidget);
  });

  testWidgets('counter demo still increments', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
