import 'package:intl/intl.dart';

class DateFormatter {
  /// Formats a timestamp to 'HH:mm dd/MM/yyyy' format
  static String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Không xác định";
    
    DateTime dateTime;
    
    try {
      // Handle different timestamp formats
      if (timestamp is int) {
        // Unix timestamp in milliseconds
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        // ISO string format
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
        // Firestore timestamp
        dateTime = DateTime.fromMillisecondsSinceEpoch(
          timestamp.millisecondsSinceEpoch,
        );
      } else {
        return "Không xác định";
      }
      
      // Format the date
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return "Không xác định";
    }
  }
}
