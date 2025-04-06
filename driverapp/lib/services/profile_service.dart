import 'dart:convert';
import 'package:driverapp/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/driver_profile.dart';

class ProfileService {
  final String baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  Future<DriverProfile> getDriverProfile(String driverId) async {
    try {
      final token =await AuthService.getAuthToken();
      
      // Use updated API endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/Driver/profile?driverId=$driverId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print("API response status code: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("API response body received");
        
        // Fix fileUrls structure before creating the response object
        if (responseData['data'] != null && responseData['data']['fileUrls'] != null) {
          var fileUrls = responseData['data']['fileUrls'];
          if (fileUrls is Map && fileUrls.containsKey('\$values')) {
            // Replace the map with just the values array
            responseData['data']['fileUrls'] = fileUrls['\$values'] ?? [];
          }
        }
        
        final profileResponse = DriverProfileResponse.fromJson(responseData);
        
        if (profileResponse.success && profileResponse.data != null) {
          print("Profile parsed successfully. Total working time: ${profileResponse.data!.totalWorkingTime}");
          return profileResponse.data!;
        } else {
          print("API success=false or no data: ${profileResponse.message}");
          throw Exception(profileResponse.message);
        }
      } else {
        print("API error: HTTP status ${response.statusCode}");
        print("Token: ${token}");  
        throw Exception('Không thể tải hồ sơ tài xế: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in getDriverProfile: $e");
      throw Exception('Lỗi khi tải hồ sơ tài xế: $e');
    }
  }
}
