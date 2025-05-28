import 'dart:convert';
import 'package:driverapp/utils/api_utils.dart';

class OrderService {  Future<Map<String, dynamic>> getOrderByTripId(String tripId) async {
    try {
      final response = await ApiUtils.get(
        '/api/OrderDetail', 
        queryParams: {'tripId': tripId}
      );
      
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        // The new API returns a direct array
        if (responseBody is List && responseBody.isNotEmpty) {
          return responseBody[0] as Map<String, dynamic>;
        } else {
          throw Exception('Không tìm thấy thông tin đơn hàng');
        }
      } else {
        throw Exception('Lỗi kết nối: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error: $e');
      throw Exception('Không thể tải thông tin đơn hàng: $e');
    }
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
