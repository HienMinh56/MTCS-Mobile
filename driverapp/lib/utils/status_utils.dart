import 'package:flutter/material.dart';

class StatusUtils {
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'handling':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'handling':
        return Icons.pending_actions;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.info;
    }
  }
}
