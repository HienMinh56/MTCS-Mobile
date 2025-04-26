import 'dart:convert';
import 'package:driverapp/models/staff.dart';
import 'package:driverapp/services/auth_service.dart';
import 'package:http/http.dart' as http;

class StaffService {
  final String baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  /// Fetch the list of staff members from the API
  Future<List<Staff>> getStaffList() async {
    try {
      final token = await AuthService.getAuthToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/Authen/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final staffResponse = StaffResponse.fromJson(responseData);
        
        if (staffResponse.status == 1) {
          return staffResponse.data;
        } else {
          throw Exception(staffResponse.message);
        }
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in getStaffList: $e");
      throw e;
    }
  }
}