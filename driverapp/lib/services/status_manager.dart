import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/delivery_status.dart';

class StatusManager {
  static Map<String, String> _statusMap = {};
  static bool _isInitialized = false;
  
  static const String API_URL = 'https://mtcs-server.azurewebsites.net/api/delivery-statuses';
  
  // Get status name from cached mapping
  static String? getStatusName(String? statusId) {
    if (statusId == null) return null;
    return _statusMap[statusId];
  }
  
  // Initialize the status manager by fetching from API
  static Future<void> initialize() async {
    if (_isInitialized) return;
    await fetchStatusData();
  }
  
  // Refresh status data from API
  static Future<void> fetchStatusData() async {
    try {
      final response = await http.get(Uri.parse(API_URL));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          final statuses = data.map((item) => DeliveryStatus.fromJson(item)).toList();
          
          // Update status map - only include active statuses (isActive = 1)
          _statusMap.clear();
          for (var status in statuses) {
            if (status.isActive == 1) {
              _statusMap[status.statusId] = status.statusName;
            }
          }
          
          _isInitialized = true;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch status data');
        }
      } else {
        throw Exception('Failed to fetch delivery statuses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching delivery statuses: $e');
      throw e; // Re-throw to propagate the original error
    }
  }
}
