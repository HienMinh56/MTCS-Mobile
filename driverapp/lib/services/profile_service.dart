import 'dart:convert';
import 'package:driverapp/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/driver_profile.dart';

class ProfileService {
  final String baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  Future<DriverProfile> getDriverProfile(String driverId) async {
    try {
      final token = await AuthService.getAuthToken();
      
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
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in getDriverProfile: $e");
      throw e; // Re-throw the original exception
    }
  }

  Future<String> getDriverName(String driverId) async {
    try {
      final profile = await getDriverProfile(driverId);
      return profile.fullName;
    } catch (e) {
      print("Exception in getDriverName: $e");
      throw Exception('Lỗi khi tải tên tài xế: $e');
    }
  }

  Future<DriverProfile> updateDriverProfile(
    String driverId, 
    String fullName, 
    String email, 
    String phoneNumber, 
    String? dateOfBirth,
    {String? password}
  ) async {
    final url = Uri.parse('${baseUrl}/Driver/$driverId');
    
    // Create multipart request
    final request = http.MultipartRequest('PUT', url);
    
    // Add authorization header
    final authToken = await AuthService.getAuthToken();
    request.headers['Authorization'] = 'Bearer $authToken';
    
    // Add form fields
    request.fields['FullName'] = fullName;
    request.fields['Email'] = email;
    request.fields['PhoneNumber'] = phoneNumber;
    
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
      request.fields['DateOfBirth'] = dateOfBirth;
    }
    
    if (password != null && password.isNotEmpty) {
      request.fields['Password'] = password;
    }
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true) {
          return DriverProfile.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['messageVN'] ?? 'Lỗi khi cập nhật thông tin');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['messageVN'] ?? 'Lỗi khi cập nhật thông tin');
      }
    } catch (e) {
      throw Exception('Không thể cập nhật hồ sơ: $e');
    }
  }
}
