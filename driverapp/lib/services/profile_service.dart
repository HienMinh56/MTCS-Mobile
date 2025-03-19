import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/driver_profile.dart';

class ProfileService {
  final String baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  Future<DriverProfile> getDriverProfile(String driverId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Driver/$driverId/profile'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final profileResponse = DriverProfileResponse.fromJson(responseData);
      
      if (profileResponse.success && profileResponse.data != null) {
        return profileResponse.data!;
      } else {
        throw Exception(profileResponse.message);
      }
    } else {
      throw Exception('Không thể tải hồ sơ tài xế: ${response.statusCode}');
    }
  }

  // Helper method to format working time from minutes to hours and minutes
  String formatWorkingTime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '$hours hrs $remainingMinutes mins';
    } else {
      return '$remainingMinutes mins';
    }
  }

  // Helper method to format working time in Vietnamese
  String formatWorkingTimeVietnamese(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '$hours giờ $remainingMinutes phút';
    } else {
      return '$remainingMinutes phút';
    }
  }
}
