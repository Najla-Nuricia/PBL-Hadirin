import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';
import 'package:mobile/pages/mhs/change_password_page.dart';

void main() {
  testWidgets('changes password using the current password', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = DummyStudentAuthRepository(latency: Duration.zero);
    final nim = DummyStudentAuthRepository.demoAccount.nim;
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(nim: nim, repository: repository),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('current-password-field')),
      'wrong-password',
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
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Kata sandi saat ini salah.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('current-password-field')),
      DummyStudentAuthRepository.demoAccount.password,
    );
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Kata sandi berhasil diubah.'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => repository.login(nim: nim, password: 'password-baru'),
      ),
      isNotNull,
    );
  });
}
