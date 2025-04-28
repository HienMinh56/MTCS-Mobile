import 'dart:convert';
import 'package:driverapp/utils/api_utils.dart';

class OrderService {
  Future<Map<String, dynamic>> getOrderByTripId(String tripId) async {
    try {
      final response = await ApiUtils.get(
        '/api/order/orders', 
        queryParams: {'tripId': tripId}
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1) {
          return data['data'][0];
        } else {
          throw Exception(data['message'] ?? 'API error occurred');
        }
      } else {
        throw Exception('Failed to load order details: ${response.statusCode}');
      }
    } catch (e) {
      throw e; // Re-throw the original exception
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
