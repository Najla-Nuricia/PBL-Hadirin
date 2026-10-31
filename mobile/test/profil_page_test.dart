import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mhs/student_account.dart';
import 'package:mobile/pages/mhs/profil_page.dart';

void main() {
  testWidgets('student can edit and save profile information', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilPage(
          account: StudentAccount(
            fullName: 'Mahasiswa Registrasi',
            nim: '9876543210',
            className: '3F-TI',
            password: 'rahasia123',
          ),
        ),
      ),
    );
    expect(find.text('Mahasiswa Registrasi'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('Belum diisi'), findsNWidgets(2));
    await tester.tap(find.text('Ubah Profil'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-name')),
      'Siti Aminah',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-nim')),
      '1234567890',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-phone')),
      '08123456789',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-email')),
      'siti.aminah@example.com',
    );
    expect(find.byKey(const ValueKey('edit-profile-role')), findsNothing);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.text('08123456789'), findsOneWidget);
    expect(find.text('siti.aminah@example.com'), findsOneWidget);
    expect(find.text('Mahasiswa'), findsOneWidget);
  });
}
