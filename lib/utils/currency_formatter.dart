import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Formats an integer amount as Indonesian Rupiah, e.g., Rp2.500.000
  static String format(num amount) {
    // NumberFormat in id_ID formats with space or non-breaking space after symbol,
    // e.g., "Rp 2.500.000" or "Rp2.500.000". We ensure clean "Rp2.500.000" formatting.
    final formatted = _formatter.format(amount).replaceAll(' ', '');
    return formatted;
  }

  /// Formats signed amount e.g. -Rp550.000 or +Rp3.000.000
  static String formatWithSign(num amount, {bool isExpense = false}) {
    final absFormatted = format(amount.abs());
    if (amount < 0 || isExpense) {
      return '-$absFormatted';
    } else {
      return '+$absFormatted';
    }
  }

  /// Parses an Indonesian formatted string into raw integer amount
  static int parse(String text) {
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return 0;
    return int.tryParse(digitsOnly) ?? 0;
  }
}
