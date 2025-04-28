import 'dart:convert';
import 'package:driverapp/models/driver_profile.dart';
import 'package:driverapp/utils/api_utils.dart';

class ProfileService {
  Future<DriverProfile> getDriverProfile(String driverId) async {
    try {
      // Use updated API endpoint with ApiUtils
      final response = await ApiUtils.get(
        '/api/Driver/profile',
        queryParams: {'driverId': driverId}
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
        
        // Convert string values to integers where needed
        if (responseData['data'] != null) {
          var data = responseData['data'];
          
          // Ensure status is an integer
          if (data['status'] != null) {
            try {
              // First handle if it's a string
              if (data['status'] is String) {
                data['status'] = int.tryParse(data['status']) ?? 0;
              } 
              // If it's not an int at this point, set default value
              else if (data['status'] is! int) {
                data['status'] = 0;
              }
            } catch (e) {
              print("Error converting status: $e");
              data['status'] = 0;
            }
          } else {
            // Status is null, set default
            data['status'] = 0;
          }
          
          // Ensure totalWorkingTime is an integer
          if (data['totalWorkingTime'] != null) {
            try {
              if (data['totalWorkingTime'] is String) {
                data['totalWorkingTime'] = int.tryParse(data['totalWorkingTime']) ?? 0;
              } else if (data['totalWorkingTime'] is! int) {
                data['totalWorkingTime'] = 0;
              }
            } catch (e) {
              data['totalWorkingTime'] = 0;
            }
          }
          
          // Ensure currentWeekWorkingTime is an integer
          if (data['currentWeekWorkingTime'] != null) {
            try {
              if (data['currentWeekWorkingTime'] is String) {
                data['currentWeekWorkingTime'] = int.tryParse(data['currentWeekWorkingTime']) ?? 0;
              } else if (data['currentWeekWorkingTime'] is! int) {
                data['currentWeekWorkingTime'] = 0;
              }
            } catch (e) {
              data['currentWeekWorkingTime'] = 0;
            }
          }
          
          // Ensure totalOrder is an integer
          if (data['totalOrder'] != null) {
            try {
              if (data['totalOrder'] is String) {
                data['totalOrder'] = int.tryParse(data['totalOrder']) ?? 0;
              } else if (data['totalOrder'] is! int) {
                data['totalOrder'] = 0;
              }
            } catch (e) {
              data['totalOrder'] = 0;
            }
          }
        }
        
        // Enhanced debugging
        print("Processed data before creating response: ${responseData['data']}");
        
        final profileResponse = DriverProfileResponse.fromJson(responseData);
        
        if (profileResponse.success && profileResponse.data != null) {
          return profileResponse.data!;
        } else {
          throw Exception(profileResponse.message);
        }
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      throw e; // Re-throw the original exception
    }
  }

  Future<String> getDriverName(String driverId) async {
    try {
      final profile = await getDriverProfile(driverId);
      return profile.fullName;
    } catch (e) {
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
    // Create fields map for multipart request
    Map<String, String> fields = {
      'FullName': fullName,
      'Email': email,
      'PhoneNumber': phoneNumber,
    };
    
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
      fields['DateOfBirth'] = dateOfBirth;
    }
    
    if (password != null && password.isNotEmpty) {
      fields['Password'] = password;
    }
    
    try {
      // Use ApiUtils for multipart PUT request
      final streamedResponse = await ApiUtils.multipartPut(
        '/api/Driver/$driverId',
        fields,
        null // No files to upload
      );
      
      final response = await ApiUtils.streamedResponseToResponse(streamedResponse);
      
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
