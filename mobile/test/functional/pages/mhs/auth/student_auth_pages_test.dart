import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';
import 'package:mobile/data/mhs/student_account.dart';
import 'package:mobile/routing/student_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  late GoRouter router;

  Future<void> pumpApp(WidgetTester tester) async {
    router = createStudentRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find
        .ancestor(of: find.text(label), matching: find.byType(Column))
        .first,
    matching: find.byType(TextFormField),
  );

  String currentPath() => router.state.uri.path;

  testWidgets('login shows validation errors for empty fields', (tester) async {
    await pumpApp(tester);

    expect(find.text('Login Mahasiswa'), findsOneWidget);
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('NIM wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
    expect(currentPath(), StudentRoutePaths.login);
  });

  testWidgets('login rejects wrong credentials', (tester) async {
    await pumpApp(tester);

    await tester.enterText(field('NIM'), '2341720001');
    await tester.enterText(field('Password'), 'salah-password');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('NIM atau password salah.'), findsOneWidget);
    expect(currentPath(), StudentRoutePaths.login);
  });

  testWidgets('login with the dummy account opens beranda', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      field('NIM'),
      DummyStudentAuthRepository.demoAccount.nim,
    );
    await tester.enterText(
      field('Password'),
      DummyStudentAuthRepository.demoAccount.password,
    );
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(currentPath(), StudentRoutePaths.beranda);
  });

  testWidgets('beranda shows the account that logged in', (tester) async {
    const account = StudentAccount(
      nim: '9876501234',
      fullName: 'Nama Mahasiswa Terdaftar',
      className: '4A-TI',
      password: 'rahasia123',
    );
    await tester.runAsync(
      () => studentAuthRepository.register(
        StudentRegistrationDraft(
          fullName: account.fullName,
          nim: account.nim,
          className: account.className,
          password: account.password,
        ),
        facePhotoPaths: const [],
      ),
    );
    await pumpApp(tester);

    await tester.enterText(field('NIM'), account.nim);
    await tester.enterText(field('Password'), account.password);
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(currentPath(), StudentRoutePaths.beranda);
    expect(find.text(account.fullName), findsOneWidget);
    expect(find.text('${account.nim} · ${account.className}'), findsOneWidget);
  });

  testWidgets('register validates the form before the face scan', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(currentPath(), StudentRoutePaths.register);

    await tester.enterText(field('Nama Lengkap'), 'Joni Mahasiswa');
    await tester.enterText(field('NIM'), '2341720050');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TI-3A').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Kata Sandi'), 'rahasia123');
    await tester.enterText(field('Konfirmasi Kata Sandi'), 'beda12345');
    await tester.ensureVisible(find.text('Lanjut ke Scan Wajah →'));
    await tester.tap(find.text('Lanjut ke Scan Wajah →'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi kata sandi tidak sama.'), findsOneWidget);
    expect(currentPath(), StudentRoutePaths.register);

    await tester.enterText(field('Konfirmasi Kata Sandi'), 'rahasia123');
    await tester.ensureVisible(find.text('Lanjut ke Scan Wajah →'));
    await tester.tap(find.text('Lanjut ke Scan Wajah →'));
    await tester.pumpAndSettle();

    expect(currentPath(), StudentRoutePaths.registerFaceScan);
    expect(find.text('Scan wajah'), findsOneWidget);
    expect(find.text('Hadap lurus ke depan'), findsOneWidget);
    expect(find.text('Foto 1 dari 5'), findsOneWidget);

    final captureButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Ambil Foto'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(captureButton.onPressed, isNull);
  });

  testWidgets('keyboard next skips the password visibility toggle', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    await tester.showKeyboard(field('Kata Sandi'));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final confirmationField = tester.widget<EditableText>(
      find.descendant(
        of: field('Konfirmasi Kata Sandi'),
        matching: find.byType(EditableText),
      ),
    );
    expect(confirmationField.focusNode.hasFocus, isTrue);
  });

  testWidgets('register rejects a NIM that is already registered', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Nama Lengkap'), 'Mahasiswa Demo');
    await tester.enterText(
      field('NIM'),
      DummyStudentAuthRepository.demoAccount.nim,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TI-3A').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Kata Sandi'), 'rahasia123');
    await tester.enterText(field('Konfirmasi Kata Sandi'), 'rahasia123');
    await tester.ensureVisible(find.text('Lanjut ke Scan Wajah →'));
    await tester.tap(find.text('Lanjut ke Scan Wajah →'));
    await tester.pumpAndSettle();

    expect(find.text('NIM sudah terdaftar. Silakan login.'), findsOneWidget);
    expect(currentPath(), StudentRoutePaths.register);
  });

  testWidgets('face scan route without registration data redirects back', (
    tester,
  ) async {
    await pumpApp(tester);

    router.go(StudentRoutePaths.registerFaceScan);
    await tester.pumpAndSettle();

    expect(currentPath(), StudentRoutePaths.register);
  });
}
