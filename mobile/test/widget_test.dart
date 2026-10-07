import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/routing/student_router.dart';

void main() {
  testWidgets('student navbar navigates between persistent branches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const HadirinApp());
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Absensi'), findsWidgets);
    expect(find.text('Surat'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.beranda,
    );

    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();

    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.riwayat,
    );
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Absensi'), findsWidgets);
    expect(find.text('Surat'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);

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
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Absensi'), findsWidgets);
    expect(find.text('Surat'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('profile-change-password')));
    await tester.pumpAndSettle();

    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.changePassword,
    );
    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    expect(find.text('Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.profil,
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
}
