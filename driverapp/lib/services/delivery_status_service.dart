import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/utils/constants.dart';
import 'package:driverapp/utils/api_utils.dart';

class DeliveryStatusService {
  final String _baseUrl = Constants.apiBaseUrl; 
  
  // Cache delivery statuses to avoid repeated API calls
  List<DeliveryStatus>? _deliveryStatuses;
  
  // Get all delivery statuses from API
  Future<List<DeliveryStatus>> getDeliveryStatuses() async {
    // Return cached data if available
    if (_deliveryStatuses != null) {
      return _deliveryStatuses!;
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/delivery-statuses'),
        headers: ApiUtils.headers,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 200) {
          final List<dynamic> statusesJson = data['data'];
          final statuses = statusesJson
              .map((json) => DeliveryStatus.fromJson(json))
              .where((status) => 
                  // Filter out statuses that users can't update to
                  status.statusId != 'delaying' && 
                  status.statusId != 'canceled')
              .toList();
          
          // Sort by status index for correct sequence
          statuses.sort((a, b) => a.statusIndex.compareTo(b.statusIndex));
          
          // Cache the result
          _deliveryStatuses = statuses;
          return statuses;
        } else {
          throw Exception('API error: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load delivery statuses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load delivery statuses: $e');
    }
  }
  
  // Get the next status based on current status ID
  Future<DeliveryStatus?> getNextTripStatus(String currentStatusId) async {
    final statuses = await getDeliveryStatuses();
    
    // Find current status in the sequence
    final currentIndex = statuses.indexWhere(
      (status) => status.statusId == currentStatusId
    );
    
    // If current status not found or it's the last one, return null
    if (currentIndex == -1 || currentIndex >= statuses.length - 1) {
      return null;
    }
    
    // Return the next status in the sequence
    return statuses[currentIndex + 1];
  }
  
  // Add this method to check if a status has a next status
  Future<bool> hasNextStatus(String statusId) async {
    try {
      final nextStatus = await getNextTripStatus(statusId);
      return nextStatus != null;
    } catch (e) {
      return false;
    }
  }
  
  // Get status name by ID
  Future<String> getStatusName(String? statusId) async {
    if (statusId == null) return 'N/A';
    
    try {
      final statuses = await getDeliveryStatuses();
      final status = statuses.firstWhere(
        (s) => s.statusId == statusId,
        orElse: () => DeliveryStatus(
          statusId: statusId,
          statusName: statusId,
          statusIndex: -1,
          isActive: false
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
