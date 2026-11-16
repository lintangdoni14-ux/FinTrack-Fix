import 'package:intl/intl.dart';

class DateFormatter {
  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Returns full Indonesian date e.g., "Minggu, 15 November 2026"
  static String formatFullDate(DateTime date) {
    final dayName = _dayNames[date.weekday - 1];
    final monthName = _monthNames[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  /// Returns medium date e.g., "15 Nov 2026"
  static String formatMediumDate(DateTime date) {
    final monthName = _monthNames[date.month - 1].substring(0, 3);
    return '${date.day} $monthName ${date.year}';
  }

  /// Returns day and month e.g., "15 Nov"
  static String formatShortDate(DateTime date) {
    final monthName = _monthNames[date.month - 1].substring(0, 3);
    return '${date.day} $monthName';
  }

  /// Returns friendly relative date: "Hari Ini", "Kemarin", or formatted date
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Hari Ini';
    } else if (target == today.subtract(const Duration(days: 1))) {
      return 'Kemarin';
    } else {
      return formatFullDate(date);
    }
  }

  /// Returns time greeting based on current hour in Indonesian
  static String getGreeting([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat sore';
    } else {
      return 'Selamat malam';
    }
  }
}
