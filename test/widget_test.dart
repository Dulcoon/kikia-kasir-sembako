import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warungkasir/main_shell.dart';

void main() {
  testWidgets('MainShell shows 5 bottom nav items', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainShell())),
    );
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Barang'), findsWidgets);
    expect(find.text('Kasir'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Laporan'), findsWidgets);
  });
}
