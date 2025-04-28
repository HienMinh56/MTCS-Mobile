import 'dart:convert';
import 'package:driverapp/utils/api_utils.dart';

class WorkingTimeService {
  Future<String> getWeeklyWorkingTime(String driverId) async {
    try {
      final response = await ApiUtils.get(
        '/api/DriverWeeklySummary/weekly-time', 
        queryParams: {'driverId': driverId}
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
      // Format today's date as YYYY/MM/DD
      final now = DateTime.now();
      final formattedDate = '${now.year}/${now.month}/${now.day}';
      
      final response = await ApiUtils.get(
        '/api/DriverDailyWorkingTime/total-time-day', 
        queryParams: {
          'driverId': driverId,
          'workDate': formattedDate
        }
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
      
      final response = await ApiUtils.get(
        '/api/DriverDailyWorkingTime/total-time-range', 
        queryParams: {
          'driverId': driverId,
          'fromDate': fromDateFormatted,
          'toDate': toDateFormatted
        }
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
