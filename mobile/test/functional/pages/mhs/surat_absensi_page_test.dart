import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';
import 'package:mobile/pages/mhs/absensi_page.dart';
import 'package:mobile/pages/mhs/surat_page.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  setUp(() {
    studentAuthRepository.logout();
  });

  testWidgets('SuratPage displays Sakit/Izin radios and Kompensasi tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const SuratPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Izin/Sakit'), findsOneWidget);
    expect(find.text('Upload Surat Kompensasi'), findsOneWidget);
    expect(find.text('Sakit'), findsOneWidget);
    expect(find.text('Izin'), findsOneWidget);

    await tester.tap(find.text('Sakit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upload Surat Kompensasi'));
    await tester.pumpAndSettle();
    expect(find.text('Sakit'), findsNothing);
    expect(find.text('Izin'), findsNothing);

    await tester.ensureVisible(find.text('Kirim Surat'));
    await tester.tap(find.text('Kirim Surat'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih mata kuliah terlebih dahulu.'), findsOneWidget);
  });

  testWidgets('AbsensiPage enters camera step gracefully when camera plugin unavailable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AbsensiPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('JTI Polinema'), findsOneWidget);
    await tester.ensureVisible(find.text('Lanjutkan ke Scan Wajah'));
    await tester.tap(find.text('Lanjutkan ke Scan Wajah'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Kirim Verifikasi Wajah'), findsOneWidget);
    expect(find.text('Pilih Foto dari Galeri / File'), findsOneWidget);
  });
}

