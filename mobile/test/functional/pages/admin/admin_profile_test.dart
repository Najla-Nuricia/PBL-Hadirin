import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/pages/admin/admin_profile_page.dart';

void main() {
  testWidgets('admin profile shows account info and account actions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdminProfilePage()));
    await tester.pumpAndSettle();

    // Tata letak mengikuti profil mahasiswa/dosen: AppBar "Profil", kartu
    // hero, bagian "Informasi Akun", kartu aksi, dan tombol keluar.
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Informasi Akun'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Belum diisi'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-change-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-change-password')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ListTile &&
            widget.key == const ValueKey('admin-change-password'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ListTile &&
            widget.key == const ValueKey('admin-change-email'),
      ),
      findsOneWidget,
    );
    // Ubah Email berada di bawah Ubah Kata Sandi, di dalam kartu aksi.
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('admin-change-email'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('admin-change-password'))).dy,
      ),
    );
    expect(find.byKey(const ValueKey('admin-logout')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedButton &&
            widget.key == const ValueKey('admin-logout'),
      ),
      findsOneWidget,
    );

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
