import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';
import 'package:mobile/data/mhs/student_data_service.dart';
import 'package:mobile/routing/student_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  tearDownAll(() => studentAuthRepository.logout());

  testWidgets(
    'live full E2E UI flow across Login, Beranda, Riwayat, Absensi, Surat, Profil, ChangePassword, and Logout',
    (tester) async {
      final originalOnError = FlutterError.onError;
      final flutterErrors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) {
        flutterErrors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = createStudentRouter(showOnboarding: false);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify wrong password shows backend rejection cleanly.
      final loginFields = find.byType(TextFormField);
      await tester.enterText(loginFields.at(0), '2341720001');
      await tester.enterText(loginFields.at(1), 'salah_banget');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('NIM atau password salah.'), findsOneWidget);

      // 2. Real login with seeded demo student against FastAPI + Supabase.
      await tester.enterText(loginFields.at(1), 'mahasiswa123');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(studentAuthRepository.hasRemoteSession, isTrue);
      expect(
        router.routeInformationProvider.value.uri.path,
        StudentRoutePaths.beranda,
      );
      expect(find.textContaining('Mahasiswa Demo'), findsWidgets);

      // 3. Navigate to Riwayat -> verify live summary & history load cleanly.
      await tester.tap(find.byIcon(Icons.attach_money));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(
        router.routeInformationProvider.value.uri.path,
        StudentRoutePaths.riwayat,
      );
      expect(find.text('Hadir'), findsWidgets);

      // 4. Navigate to Absensi -> Step 1 & Step 2 (without timer leaks or errors).
      await tester.tap(find.byIcon(Icons.videocam_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(
        router.routeInformationProvider.value.uri.path,
        StudentRoutePaths.absensi,
      );
      expect(find.textContaining('JTI Polinema'), findsOneWidget);
      await tester.ensureVisible(find.text('Lanjutkan ke Scan Wajah'));
      await tester.tap(find.text('Lanjutkan ke Scan Wajah'));
      await tester.pumpAndSettle();
      expect(find.text('Kirim Verifikasi Wajah'), findsOneWidget);

      // 5. Navigate to Surat -> test dynamic schedule dropdown + live submit + DB cleanup.
      String? createdPengajuanId;
      try {
        await tester.tap(find.byIcon(Icons.description_outlined));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(
          router.routeInformationProvider.value.uri.path,
          StudentRoutePaths.surat,
        );

        await tester.ensureVisible(
          find.byType(DropdownButtonFormField<String>),
        );
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        final popupMenuItems = find.descendant(
          of: find.byType(ListView),
          matching: find.byType(DropdownMenuItem<String>),
        );
        expect(popupMenuItems, findsWidgets);
        await tester.tap(
          find
              .descendant(
                of: popupMenuItems.first,
                matching: find.byType(Text),
              )
              .first,
        );
        await tester.pumpAndSettle();

        final alasanField = find.byType(TextFormField).first;
        await tester.ensureVisible(alasanField);
        await tester.enterText(alasanField, 'QA UI E2E Test');
        await tester.ensureVisible(find.text('Kirim Surat'));
        await tester.tap(find.text('Kirim Surat'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final list = await studentDataService.loadPengajuanList();
        for (final item in list) {
          if (item['alasan'] == 'QA UI E2E Test') {
            createdPengajuanId = item['id'] as String?;
          }
        }
        expect(createdPengajuanId, isNotNull);
        expect(find.text('Pengajuan surat berhasil dikirim!'), findsOneWidget);
      } finally {
        final pengajuanId = createdPengajuanId;
        if (pengajuanId != null) {
          await studentDataService.deletePengajuan(pengajuanId);
        }
      }

      // 6. Navigate to Profil -> verify real profile data, live edit+restore, Ubah Kata Sandi route & Keluar.
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(
        router.routeInformationProvider.value.uri.path,
        StudentRoutePaths.profil,
      );
      expect(find.text('2341720001'), findsWidgets);

      final originalProfile = await studentDataService.loadProfile();
      try {
        await tester.ensureVisible(find.text('Ubah Profil'));
        await tester.tap(find.text('Ubah Profil'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('edit-profile-phone')),
          '081299988877',
        );
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final updatedProfile = await studentDataService.loadProfile();
        expect(updatedProfile.phoneNumber, '081299988877');
      } finally {
        await studentDataService.updateMyProfile(
          fullName: originalProfile.fullName,
          email: originalProfile.email,
          phoneNumber: originalProfile.phoneNumber,
          className: originalProfile.className,
        );
      }

      final changePwBtn = find.byKey(const ValueKey('profile-change-password'));
      await tester.ensureVisible(changePwBtn);
      await tester.tap(find.text('Ubah Kata Sandi').last);
      await tester.pumpAndSettle();
      expect(find.text('Kata Sandi Baru'), findsOneWidget);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();

      // Re-open Profil tab to log out cleanly (wait for profile SnackBar to dismiss).
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Keluar'));
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(studentAuthRepository.currentAccessToken, isNull);
      expect(
        router.routeInformationProvider.value.uri.path,
        StudentRoutePaths.login,
      );

      expect(
        flutterErrors,
        isEmpty,
        reason: flutterErrors.map((e) => e.exceptionAsString()).join('\n'),
      );
    },
  );
}
