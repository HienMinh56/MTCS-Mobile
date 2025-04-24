import 'dart:convert';
import 'package:driverapp/services/auth_service.dart';
import 'package:driverapp/utils/constants.dart';
import 'package:http/http.dart' as http;

class WorkingTimeService {
  final String _baseUrl = Constants.apiBaseUrl;
  Future<String> getWeeklyWorkingTime(String driverId) async {
    try {
      final token = await AuthService.getAuthToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/DriverWeeklySummary/weekly-time?driverId=$driverId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1) {
          return data['data'] as String;
        } else {
          return '0 giờ 0 phút';
        }
      } else {
        throw Exception('Failed to load weekly working time');
      }
    } catch (e) {
      return '0 giờ 0 phút';
    }
  }
  
  Future<String> getDailyWorkingTime(String driverId) async {
    try {
      final token = await AuthService.getAuthToken();
      
      // Format today's date as YYYY/MM/DD
      final now = DateTime.now();
      final formattedDate = '${now.year}/${now.month}/${now.day}';
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/DriverDailyWorkingTime/total-time-day?driverId=$driverId&workDate=$formattedDate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1) {
          return data['data'] as String;
        } else {
          return '0 giờ 0 phút';
        }
      } else {
        throw Exception('Failed to load daily working time');
      }
    } catch (e) {
      return '0 giờ 0 phút';
    }
  }

  Future<String> getWorkingTimeRange(String driverId, DateTime fromDate, DateTime toDate) async {
    try {
      final fromDateFormatted = '${fromDate.year}/${fromDate.month}/${fromDate.day}';
      final toDateFormatted = '${toDate.year}/${toDate.month}/${toDate.day}';
      final token = await AuthService.getAuthToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/DriverDailyWorkingTime/total-time-range?driverId=$driverId&fromDate=$fromDateFormatted&toDate=$toDateFormatted'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Không thể lấy thông tin thời gian làm việc');
        }
      } else {
        throw Exception('Lỗi kết nối: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi: ${e.toString()}');
    }
  }
}
