import 'package:intl/intl.dart';

class NumberFormatter {
  /// Format a number as currency without the currency symbol
  static String formatCurrency(dynamic value) {
    if (value == null) return '0';
    
    try {
      // Convert to double if it's a string or other numeric type
      double numericValue;
      if (value is double) {
        numericValue = value;
      } else if (value is int) {
        numericValue = value.toDouble();
      } else if (value is String) {
        numericValue = double.tryParse(value) ?? 0;
      } else {
        return '0';
      }
      
      // Format with thousands separators
      return NumberFormat('#,###', 'vi_VN').format(numericValue);
    } catch (e) {
      return '0';
    }
  }
  
  /// Format a number with specified decimal places
  static String formatNumber(dynamic value, {int decimalPlaces = 0}) {
    if (value == null) return '0';
    
    try {
      // Convert to double if it's a string or other numeric type
      double numericValue;
      if (value is double) {
        numericValue = value;
      } else if (value is int) {
        numericValue = value.toDouble();
      } else if (value is String) {
        numericValue = double.tryParse(value) ?? 0;
      } else {
        return '0';
      }
      
      // Create pattern based on decimal places
      String pattern = '#,###';
      if (decimalPlaces > 0) {
        pattern += '.' + '0' * decimalPlaces;
      }
      
      return NumberFormat(pattern, 'vi_VN').format(numericValue);
    } catch (e) {
      return '0';
    }
  }
}