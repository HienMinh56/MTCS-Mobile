import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    
    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month/${dateTime.year} $hour:$minute';
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    
    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    
    return '$day/$month/${dateTime.year}';
  }
  
  static String formatDateFromString(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr);
      return formatDate(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }
  
  static String formatDateTimeFromString(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return formatDateTime(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }
}

class CurrencyFormatter {
  static String formatVND(dynamic price) {
    if (price == null) return 'N/A';
    try {
      return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")} VNĐ';
    } catch (e) {
      return 'N/A';
    }
  }
}

class NumberFormatter {
  static String formatCurrency(dynamic value) {
    if (value == null) return '0';
    
    try {
      final num numValue = num.parse(value.toString());
      final formatter = NumberFormat('#,###', 'vi_VN');
      return formatter.format(numValue);
    } catch (e) {
      return value.toString();
    }
  }
}
