import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppDateUtils {
  /// Định dạng ngày giờ chuẩn: HH:mm dd/MM/yyyy
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
  }
  
  /// Định dạng chỉ ngày: dd/MM/yyyy
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
  
  /// Định dạng ngày từ timestamp Firestore
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
  
  /// Định dạng "thời gian trước đây" cho notification
  static String formatRelativeTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays == 0) {
        // Today, show time
        return 'Hôm nay ${DateFormat('HH:mm').format(dateTime)}';
      } else if (difference.inDays == 1) {
        // Yesterday
        return 'Hôm qua';
      } else if (difference.inDays < 7) {
        // Within a week
        return '${difference.inDays} ngày trước';
      } else {
        // More than a week
        return DateFormat('dd/MM/yy').format(dateTime);
      }
    } else {
      return '';
    }
  }
  
  /// Định dạng ngày từ chuỗi ISO
  static String formatISOString(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return "Không xác định";
    }
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return "Không xác định";
    }
  }
}
