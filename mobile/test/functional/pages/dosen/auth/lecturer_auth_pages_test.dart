import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/dosen/dummy_lecturer_auth_repository.dart';
import 'package:mobile/pages/dosen/auth/lecturer_login_page.dart';
import 'package:mobile/routing/lecturer_route_paths.dart';
import 'package:mobile/routing/lecturer_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  late GoRouter router;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    router = createLecturerRouter();
    addTearDown(router.dispose);
    router.go(LecturerRoutePaths.login);

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

  Future<void> tapButton(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('login', () {
    testWidgets('shows validation errors for empty fields', (tester) async {
      await pumpApp(tester);

      expect(find.text('Login Dosen'), findsOneWidget);
      await tapButton(tester, find.widgetWithText(FilledButton, 'Masuk'));

      expect(find.text('Email wajib diisi.'), findsOneWidget);
      expect(find.text('Password wajib diisi.'), findsOneWidget);
      expect(currentPath(), LecturerRoutePaths.login);
    });

    testWidgets('rejects a malformed email address', (tester) async {
      await pumpApp(tester);

      await tester.enterText(field('Email'), 'dosen.hadirin.id');
      await tapButton(tester, find.widgetWithText(FilledButton, 'Masuk'));

      expect(find.text('Email tidak valid.'), findsOneWidget);
      expect(currentPath(), LecturerRoutePaths.login);
    });

    testWidgets('rejects wrong credentials', (tester) async {
      await pumpApp(tester);

      await tester.enterText(field('Email'), 'dosen@hadirin.id');
      await tester.enterText(field('Password'), 'salah-password');
      await tapButton(tester, find.widgetWithText(FilledButton, 'Masuk'));

      expect(find.text('Email atau password salah.'), findsOneWidget);
      expect(currentPath(), LecturerRoutePaths.login);
    });

    testWidgets('logs in with the demo account and opens beranda', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.enterText(
        field('Email'),
        DummyLecturerAuthRepository.demoAccount.email,
      );
      await tester.enterText(
        field('Password'),
        DummyLecturerAuthRepository.demoAccount.password,
      );
      await tapButton(tester, find.widgetWithText(FilledButton, 'Masuk'));

      expect(currentPath(), LecturerRoutePaths.beranda);
    });

    testWidgets('Daftar opens the lecturer registration page', (tester) async {
      await pumpApp(tester);

      await tapButton(tester, find.widgetWithText(OutlinedButton, 'Daftar'));

      expect(currentPath(), LecturerRoutePaths.register);
      expect(find.text('Registrasi Dosen'), findsOneWidget);
    });
  });

  group('register', () {
    Future<void> openRegister(WidgetTester tester) async {
      await pumpApp(tester);
      router.go(LecturerRoutePaths.register);
      await tester.pumpAndSettle();
    }

    testWidgets('validates the form before registering', (tester) async {
      await openRegister(tester);

      await tapButton(tester, find.widgetWithText(FilledButton, 'Daftar'));

      expect(find.text('Nama dosen wajib diisi.'), findsOneWidget);
      expect(find.text('NIP wajib diisi.'), findsOneWidget);
      expect(find.text('Email wajib diisi.'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
      expect(find.text('Konfirmasi kata sandi wajib diisi.'), findsOneWidget);
      expect(currentPath(), LecturerRoutePaths.register);
    });

    testWidgets('rejects a password shorter than eight characters', (
      tester,
    ) async {
      await openRegister(tester);

      await tester.enterText(field('Nama Dosen'), 'Dra. Siti Rahmawati, M.Pd.');
      await tester.enterText(field('NIP'), '1987012020150420');
      await tester.enterText(field('Email'), 'siti.rahmawati@univ.ac.id');
      await tester.enterText(field('Kata Sandi'), 'pendek');
      await tester.enterText(field('Konfirmasi Kata Sandi'), 'pendek');
      await tapButton(tester, find.widgetWithText(FilledButton, 'Daftar'));

      expect(
        find.text('Kata sandi minimal 8 karakter.'),
        findsOneWidget,
      );
      expect(currentPath(), LecturerRoutePaths.register);
    });

    testWidgets('rejects a mismatched password confirmation', (tester) async {
      await openRegister(tester);

      await tester.enterText(field('Nama Dosen'), 'Dra. Siti Rahmawati, M.Pd.');
      await tester.enterText(field('NIP'), '1987012020150420');
      await tester.enterText(field('Email'), 'siti.rahmawati@univ.ac.id');
      await tester.enterText(field('Kata Sandi'), 'rahasia123');
      await tester.enterText(field('Konfirmasi Kata Sandi'), 'beda123456');
      await tapButton(tester, find.widgetWithText(FilledButton, 'Daftar'));

      expect(find.text('Konfirmasi kata sandi tidak sama.'), findsOneWidget);
      expect(currentPath(), LecturerRoutePaths.register);
    });

    testWidgets('rejects an email that is already registered', (tester) async {
      await openRegister(tester);

      await tester.enterText(field('Nama Dosen'), 'Dosen Demo');
      await tester.enterText(field('NIP'), '1987012020150420');
      await tester.enterText(
        field('Email'),
        DummyLecturerAuthRepository.demoAccount.email,
      );
      await tester.enterText(field('Kata Sandi'), 'rahasia123');
      await tester.enterText(field('Konfirmasi Kata Sandi'), 'rahasia123');
      await tapButton(tester, find.widgetWithText(FilledButton, 'Daftar'));

      expect(find.text('Email sudah terdaftar. Silakan login.'), findsOneWidget);
      expect(currentPath(), LecturerRoutePaths.register);
    });

    testWidgets('registers a new lecturer and returns to login', (
      tester,
    ) async {
      await openRegister(tester);

      await tester.enterText(field('Nama Dosen'), 'Dra. Siti Rahmawati, M.Pd.');
      await tester.enterText(field('NIP'), '1987012020150420');
      await tester.enterText(field('Email'), 'siti.rahmawati@univ.ac.id');
      await tester.enterText(field('Kata Sandi'), 'rahasia123');
      await tester.enterText(field('Konfirmasi Kata Sandi'), 'rahasia123');
      await tapButton(tester, find.widgetWithText(FilledButton, 'Daftar'));

      expect(currentPath(), LecturerRoutePaths.login);
      expect(
        find.text('Registrasi dosen berhasil. Silakan login.'),
        findsOneWidget,
      );
      expect(find.byType(LecturerLoginPage), findsOneWidget);
    });
  });
}
