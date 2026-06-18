import 'package:flutter_test/flutter_test.dart';

import 'package:warungkasir/core/helpers/formatters.dart';

void main() {
  group('Formatters.rupiah', () {
    test('formats zero as Rp 0', () {
      expect(Formatters.rupiah(0), 'Rp 0');
    });

    test('formats integer without decimals with id_ID locale', () {
      final out = Formatters.rupiah(125000);
      expect(out.contains('125'), isTrue);
      expect(out.contains('Rp'), isTrue);
    });
  });

  group('Formatters.generateInvoiceNumber', () {
    test('produces INV-YYYYMMDD-XXXX format', () {
      final invoice = Formatters.generateInvoiceNumber(
        date: DateTime(2026, 8, 1),
        sequence: 1,
      );
      expect(invoice, 'INV-20260801-0001');
    });

    test('pads sequence to 4 digits', () {
      final invoice = Formatters.generateInvoiceNumber(
        date: DateTime(2026, 8, 1),
        sequence: 42,
      );
      expect(invoice, 'INV-20260801-0042');
    });
  });
}
