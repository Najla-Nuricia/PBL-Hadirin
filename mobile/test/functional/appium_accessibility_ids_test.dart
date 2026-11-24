import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/pages/admin/auth/admin_login_page.dart';
import 'package:mobile/pages/onboarding_page.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: page));
    await tester.pumpAndSettle();
  }

  testWidgets('landing CTA exposes exactly "Mulai"', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const OnboardingWelcomePage());
    expect(find.bySemanticsLabel('Mulai'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('role page exposes Mahasiswa, Dosen, admin link', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const OnboardingRolePage());
    expect(find.bySemanticsLabel('Mahasiswa'), findsOneWidget);
    expect(find.bySemanticsLabel('Dosen'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Login Sebagai Sekretaris Jurusan'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('admin login submit exposes exactly "Masuk"', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const AdminLoginPage());
    expect(find.bySemanticsLabel('Masuk'), findsOneWidget);
    handle.dispose();
  });
}
