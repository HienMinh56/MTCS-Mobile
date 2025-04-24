import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/utils/constants.dart';
import 'package:driverapp/services/auth_service.dart';

class OrderService {
  final String _baseUrl = Constants.apiBaseUrl;
  
  Future<Map<String, dynamic>> getOrderByTripId(String tripId) async {
    try {
      // Retrieve the saved token from secure storage
      final token = await AuthService.getAuthToken();
      
      // Create headers with authentication token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/order/orders?tripId=$tripId'),
        headers: headers,
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
