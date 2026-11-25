import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/pages/admin/ruangan_qr_page.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  testWidgets('RuanganQrPage displays room static QR cards and search filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const RuanganQrPage()),
    );
    await tester.pumpAndSettle();

    // Verify title and notice
    expect(find.text('QR Statis Pintu Ruangan'), findsOneWidget);
    expect(
      find.textContaining('QR Statis bersifat permanen'),
      findsOneWidget,
    );

    // Verify initial visible room items
    expect(find.text('J301'), findsWidgets);

    // Test search filter for RPL 1
    await tester.enterText(find.byType(TextField), 'RPL 1');
    await tester.pumpAndSettle();

    expect(find.text('Ruang RPL 1'), findsOneWidget);
    expect(find.text('HADIRIN:ROOM:RPL1'), findsOneWidget);
    expect(find.text('J301'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.text('J301'), findsWidgets);

    // Open door poster dialog
    await tester.tap(find.text('Cetak Poster Pintu').first);
    await tester.pumpAndSettle();

    expect(find.text('Pratinjau Poster Pintu Kelas'), findsOneWidget);
    expect(find.text('HADIRIN • PRESENSI PINTU KELAS'), findsOneWidget);
    expect(find.text('PETUNJUK MAHASISWA:'), findsOneWidget);
    expect(find.text('Cetak Poster'), findsOneWidget);

    // Close dialog
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.byIcon(Icons.close)));
    await tester.pumpAndSettle();
    expect(find.text('Pratinjau Poster Pintu Kelas'), findsNothing);

    // Open batch print dialog
    await tester.tap(find.byIcon(Icons.print_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cetak Kolektif QR Pintu'), findsOneWidget);
    expect(find.text('Cetak Semua Kartu Pintu'), findsOneWidget);

    // Close batch print
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.byIcon(Icons.close)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cetak Kolektif QR Pintu'), findsNothing);
  });
}
