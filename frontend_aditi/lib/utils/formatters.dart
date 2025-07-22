import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(num amount) {
    // Using the intl package for proper currency formatting for Indian Rupees
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return format.format(amount);
  }
}