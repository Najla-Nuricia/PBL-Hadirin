import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/dosen/dummy_lecturer_auth_repository.dart';
import 'package:mobile/routing/lecturer_route_paths.dart';
import 'package:mobile/routing/lecturer_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  late GoRouter router;

  Future<void> pumpChangePassword(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    router = createLecturerRouter();
    addTearDown(router.dispose);
    router.go(LecturerRoutePaths.changePassword);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
    matching: find.byType(TextFormField),
  );

  String currentPath() => router.state.uri.path;

  Future<void> save(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Simpan');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('validates every field before submitting', (tester) async {
    await pumpChangePassword(tester);

    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    await save(tester);

    expect(find.text('Kata sandi saat ini wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi baru wajib diisi.'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi wajib diisi.'), findsOneWidget);
    expect(currentPath(), LecturerRoutePaths.changePassword);
  });

  testWidgets('rejects a new password that matches the current one', (
    tester,
  ) async {
    await pumpChangePassword(tester);

    await tester.enterText(field('Kata Sandi Saat Ini'), 'dosen123');
    await tester.enterText(field('Kata Sandi Baru'), 'dosen123');
    await tester.enterText(field('Konfirmasi Kata Sandi Baru'), 'dosen123');
    await save(tester);

    expect(find.text('Kata sandi baru harus berbeda.'), findsOneWidget);
    expect(currentPath(), LecturerRoutePaths.changePassword);
  });

  testWidgets('shows an error when the current password is wrong', (
    tester,
  ) async {
    await pumpChangePassword(tester);

    await tester.enterText(field('Kata Sandi Saat Ini'), 'salah-banget');
    await tester.enterText(field('Kata Sandi Baru'), 'sandiBaru99');
    await tester.enterText(field('Konfirmasi Kata Sandi Baru'), 'sandiBaru99');
    await save(tester);

    expect(find.text('Kata sandi saat ini salah.'), findsOneWidget);
    expect(currentPath(), LecturerRoutePaths.changePassword);
  });

  testWidgets('changes the password and returns to the profile page', (
    tester,
  ) async {
    await pumpChangePassword(tester);
    const newPassword = 'sandiBaru99';

    await tester.enterText(
      field('Kata Sandi Saat Ini'),
      DummyLecturerAuthRepository.demoAccount.password,
    );
    await tester.enterText(field('Kata Sandi Baru'), newPassword);
    await tester.enterText(field('Konfirmasi Kata Sandi Baru'), newPassword);
    await save(tester);

    expect(find.text('Kata sandi berhasil diperbarui.'), findsOneWidget);
    expect(currentPath(), LecturerRoutePaths.profil);
    expect(find.text('Informasi Akun'), findsOneWidget);

    // The page talks to the global repository, so verify the new password
    // against it outside the fake-async zone and then restore the demo account.
    await tester.runAsync(() async {
      expect(
        await lecturerAuthRepository.login(
          email: DummyLecturerAuthRepository.demoAccount.email,
          password: newPassword,
        ),
        isNotNull,
      );

      await lecturerAuthRepository.changePassword(
        email: DummyLecturerAuthRepository.demoAccount.email,
        currentPassword: newPassword,
        newPassword: DummyLecturerAuthRepository.demoAccount.password,
      );

      expect(
        await lecturerAuthRepository.login(
          email: DummyLecturerAuthRepository.demoAccount.email,
          password: DummyLecturerAuthRepository.demoAccount.password,
        ),
        isNotNull,
      );
    });
  });
}
