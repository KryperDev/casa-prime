import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  static String money(double v) => _currency.format(v);

  static String date(DateTime d) => DateFormat('dd/MM/yyyy', 'pt_BR').format(d);

  static String dateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(d);

  static String time(DateTime d) => DateFormat('HH:mm', 'pt_BR').format(d);

  static String monthYear(DateTime d) =>
      DateFormat('MMMM yyyy', 'pt_BR').format(d);
}