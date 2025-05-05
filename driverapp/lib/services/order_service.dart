import 'package:driverapp/utils/api_utils.dart';

class OrderService {
  Future<Map<String, dynamic>> getOrderByTripId(String tripId) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/order/orders', 
        queryParams: {'tripId': tripId}
      ),
      onSuccess: (data) {
        if (data['status'] == 1 && data['data'] != null && data['data'].isNotEmpty) {
          return data['data'][0];
        } else {
          throw Exception(data['message'] ?? 'Không tìm thấy thông tin đơn hàng');
        }
      },
      defaultValue: <String, dynamic>{},
      defaultErrorMessage: 'Không thể tải thông tin đơn hàng'
    );
  }
  
  String getContainerType(int? type) {
    if (type == null) return 'N/A';
    switch (type) {
      case 1:
        return 'Container Thường';
      case 2:
        return 'Container Lạnh';
      default:
        return 'Loại $type';
    }
  }
  
  String getDeliveryType(int? type) {
    if (type == null) return 'N/A';
    switch (type) {
      case 1:
        return 'Giao thẳng';
      case 2:
        return 'Giao kho';
      default:
        return 'Loại $type';
    }
  }
}
