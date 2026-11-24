import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/pages/admin/admin_profile_page.dart';

void main() {
  testWidgets('admin profile shows account info and account actions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdminProfilePage()));
    await tester.pumpAndSettle();

    expect(find.text('Informasi Akun'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-change-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-change-password')), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-logout')), findsOneWidget);

    // Tidak ada fitur ganti foto profil.
    expect(find.textContaining('Foto Profil'), findsNothing);
    expect(find.byIcon(Icons.add_a_photo), findsNothing);
    expect(find.byIcon(Icons.camera_alt), findsNothing);
  });

  testWidgets('admin email dialog validates and saves', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminProfilePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('admin-change-email')));
    await tester.pumpAndSettle();
    expect(find.text('Ubah Email'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('admin-email-field')),
      'admin.baru@hadirin.polinema.ac.id',
    );
    await tester.enterText(
      find.byKey(const ValueKey('admin-email-password-field')),
      'admin123',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Email berhasil diperbarui.'), findsOneWidget);
  });
}
