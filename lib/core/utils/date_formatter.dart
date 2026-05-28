import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'vi_VN');
  static final _shortFormat = DateFormat('dd MMM', 'vi_VN');
  static final _fullFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');

  static String format(DateTime date) => _dateFormat.format(date);
  static String formatShort(DateTime date) => _shortFormat.format(date);
  static String formatFull(DateTime date) => _fullFormat.format(date);

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) return _dateFormat.format(date);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }
}
