import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/utils/constants.dart';

class DeliveryStatusService {
final String _baseUrl = Constants.apiBaseUrl; 
  
  // Method to get all delivery statuses
  Future<List<DeliveryStatus>> getAllDeliveryStatuses() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/delivery-statuses'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 200 && jsonResponse['data'] != null) {
          List<dynamic> statusList = jsonResponse['data'];
          return statusList.map((status) => DeliveryStatus.fromJson(status)).toList();
        } else {
          throw Exception('Failed to load delivery statuses: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load delivery statuses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting delivery statuses: $e');
    }
  }
  
  // This method can remain for backward compatibility but should be updated
  // to use the new approach internally
  Future<DeliveryStatus?> getNextTripStatus(String currentStatusId) async {
    try {
      final allStatuses = await getAllDeliveryStatuses();
      
      // Find current status
      DeliveryStatus? currentStatus;
      for (var status in allStatuses) {
        if (status.statusId == currentStatusId) {
          currentStatus = status;
          break;
        }
      }
      
      if (currentStatus != null) {
        int currentIndex = currentStatus.statusIndex;
        // Find next normal status
        for (var status in allStatuses) {
          if (status.statusId != 'canceled' && 
              status.statusId != 'delaying' && 
              status.statusIndex == currentIndex + 1) {
            return status;
          }
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error getting next trip status: $e');
    }
  }
  
  // Method to check if status has a next status
  Future<bool> hasNextStatus(String statusId) async {
    try {
      final allStatuses = await getAllDeliveryStatuses();
      
      // Find current status
      DeliveryStatus? currentStatus;
      for (var status in allStatuses) {
        if (status.statusId == statusId) {
          currentStatus = status;
          break;
        }
      }
      
      if (currentStatus != null) {
        int currentIndex = currentStatus.statusIndex;
        // Check if any normal status has a higher index
        for (var status in allStatuses) {
          if (status.statusId != 'canceled' && 
              status.statusId != 'delaying' && 
              status.statusIndex > currentIndex) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Get status name by ID
  Future<String> getStatusName(String? statusId) async {
    if (statusId == null) return 'N/A';
    
    try {
      final statuses = await getAllDeliveryStatuses();
      final status = statuses.firstWhere(
        (s) => s.statusId == statusId,
        orElse: () => DeliveryStatus(
          statusId: statusId,
          statusName: statusId,
          statusIndex: -1,
          isActive: 1
        )
      );
      return status.statusName;
    } catch (_) {
      // Fallback to hardcoded values if API fails
      return getStatusNameFallback(statusId);
    }
  }
  
  // Fallback status names
  String getStatusNameFallback(String? status) {
    if (status == null) return 'N/A';
    
    switch (status) {
      case 'not_started':
        return 'Chưa bắt đầu';
      case 'going_to_port':
        return 'Đang đến cảng';
      case 'picking_up_goods':
        return 'Đang lấy hàng';
      case 'is_delivering':
        return 'Đang giao hàng';
      case 'at_delivery_point':
        return 'Đã đến điểm giao hàng';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return status;
    }
  }
}
