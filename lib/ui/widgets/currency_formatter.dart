import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compactFormatter = NumberFormat.compact(locale: 'en_US');

  static String format(double amount, {String symbol = 'Ks'}) {
    return '$symbol ${_formatter.format(amount)}';
  }

  static String formatNumberOnly(double amount) {
    return _formatter.format(amount);
  }

  static String formatCompact(double amount, {String symbol = 'Ks'}) {
    return '$symbol ${_compactFormatter.format(amount)}';
  }
}
