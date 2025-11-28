import 'package:intl/intl.dart';

class DateFormatter {
  static final _date = DateFormat('dd-MMM-yyyy');
  static final _time = DateFormat('hh:mm a');

  static String formatDate(DateTime date) => _date.format(date);

  static String formatTime(Duration? duration) {
    if (duration == null) return '--';
    final dt = DateTime(0).add(duration);
    return _time.format(dt);
  }

  static String formatHours(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

