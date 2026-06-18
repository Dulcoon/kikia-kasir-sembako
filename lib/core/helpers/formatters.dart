import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final DateFormat _dateLong = DateFormat('dd MMMM yyyy', 'id_ID');
  static final DateFormat _dateShort = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateForInvoice = DateFormat('yyyyMMdd');

  static String rupiah(num value) => _rupiah.format(value);

  static String rupiahRaw(num value) => value.toStringAsFixed(0);

  static String dateLong(DateTime dt) => _dateLong.format(dt);

  static String dateShort(DateTime dt) => _dateShort.format(dt);

  static String dateTime(DateTime dt) => _dateTime.format(dt);

  static String dateForInvoice(DateTime dt) => _dateForInvoice.format(dt);

  static String generateInvoiceNumber({
    required DateTime date,
    required int sequence,
  }) {
    final datePart = _dateForInvoice.format(date);
    final seqPart = sequence.toString().padLeft(4, '0');
    return 'INV-$datePart-$seqPart';
  }
}
