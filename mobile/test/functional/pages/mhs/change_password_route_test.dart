import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';
import 'package:mobile/data/mhs/student_account.dart';
import 'package:mobile/pages/mhs/change_password_page.dart';
import 'package:mobile/routing/student_router.dart';

void main() {
  testWidgets('password route uses the account that logged in', (tester) async {
    const account = StudentAccount(
      nim: '8765432199',
      fullName: 'Pengguna Tes',
      className: '3F-TI',
      password: '12345678',
    );
    await tester.runAsync(() async {
      await studentAuthRepository.register(
        StudentRegistrationDraft(
          fullName: account.fullName,
          nim: account.nim,
          className: account.className,
          password: account.password,
        ),
        facePhotoPaths: const [],
      );
      await studentAuthRepository.login(
        nim: account.nim,
        password: account.password,
      );
    });

    final router = createStudentRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go(StudentRoutePaths.changePassword);
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordPage), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('current-password-field')),
      account.password,
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'password-baru',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password-field')),
      'password-baru',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pump();

    expect(find.text('Kata sandi berhasil diubah.'), findsOneWidget);
  });
}
