import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';
import 'package:mobile/main.dart';
import 'package:mobile/routing/student_router.dart';

void main() {
  testWidgets('student navbar navigates between persistent branches', (
    tester,
  ) async {
    await tester.pumpWidget(const HadirinApp());
    await tester.pumpAndSettle();

    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.login,
    );
    final loginFields = find.byType(TextFormField);
    await tester.enterText(
      loginFields.at(0),
      DummyStudentAuthRepository.demoAccount.nim,
    );
    await tester.enterText(
      loginFields.at(1),
      DummyStudentAuthRepository.demoAccount.password,
    );
    await tester.tap(find.text('Masuk'));
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

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();

    expect(
      studentRouter.routeInformationProvider.value.uri.path,
      StudentRoutePaths.profil,
    );
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Absensi'), findsWidgets);
    expect(find.text('Surat'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);

    await tester.tap(find.text('Surat').last);
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
