import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static String format(num amount) {
    return _formatter.format(amount);
  }

  static String formatShort(num amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      if (millions == millions.truncateToDouble()) {
        return '${millions.toInt()} triệu/tháng';
      }
      return '${millions.toStringAsFixed(1)} triệu/tháng';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k/tháng';
    }
    return '${amount.toStringAsFixed(0)}đ/tháng';
  }
}
