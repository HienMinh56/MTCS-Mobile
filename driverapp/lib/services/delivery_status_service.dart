import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/utils/api_utils.dart';

class DeliveryStatusService {
  Future<List<DeliveryStatus>> getDeliveryStatuses() async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get('/api/delivery-statuses'),
      onSuccess: (jsonData) {
        if (jsonData['data'] != null) {
          return (jsonData['data'] as List)
              .map((item) => DeliveryStatus.fromJson(item))
              .toList();
        } else {
          return <DeliveryStatus>[];
        }
      },
      defaultValue: <DeliveryStatus>[],
      defaultErrorMessage: 'Không thể tải trạng thái giao hàng'
    );
  }
  
  Future<DeliveryStatus?> getNextTripStatus(String currentStatusId) async {
    try {
      final allStatuses = await getDeliveryStatuses();
      
      // Find current status
      DeliveryStatus? currentStatus = allStatuses
          .firstWhere((status) => status.statusId == currentStatusId, 
                     orElse: () => DeliveryStatus(statusId: '', statusName: '', statusIndex: -1, isActive: 0));
      
      if (currentStatus.statusId.isNotEmpty) {
        int currentIndex = currentStatus.statusIndex;
        // Find next normal status
        for (var status in allStatuses) {
          if (status.statusId != 'canceled' && 
              status.statusId != 'delaying' && 
              status.statusIndex == currentIndex + 1 &&
              status.isActive == 1) {
            return status;
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Lỗi khi lấy trạng thái tiếp theo: $e');
      return null;
    }
  }
  
  // Method to check if status has a next status
  Future<bool> hasNextStatus(String statusId) async {
    try {
      final allStatuses = await getDeliveryStatuses();
      
      // Find current status
      DeliveryStatus? currentStatus = allStatuses
          .firstWhere((status) => status.statusId == statusId, 
                     orElse: () => DeliveryStatus(statusId: '', statusName: '', statusIndex: -1, isActive: 0));
      
      if (currentStatus.statusId.isNotEmpty) {
        int currentIndex = currentStatus.statusIndex;
        // Check if any normal status has a higher index
        return allStatuses.any((status) => 
          status.statusId != 'canceled' && 
          status.statusId != 'delaying' && 
          status.statusIndex > currentIndex);
      }
      return false;
    } catch (e) {
      print('❌ Lỗi khi kiểm tra trạng thái tiếp theo: $e');
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
