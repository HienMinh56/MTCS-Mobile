import 'package:driverapp/utils/api_utils.dart';

class WorkingTimeService {
  Future<String> getWeeklyWorkingTime(String driverId) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/DriverWeeklySummary/weekly-time', 
        queryParams: {'driverId': driverId}
      ),
      onSuccess: (data) => data['data'] as String,
      defaultValue: '0 giờ 0 phút',
      defaultErrorMessage: 'Không thể tải thông tin thời gian làm việc'
    );
  }
  
  Future<String> getDailyWorkingTime(String driverId) async {
    // Format today's date as YYYY/MM/DD
    final now = DateTime.now();
    final formattedDate = '${now.year}/${now.month}/${now.day}';
    
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/DriverDailyWorkingTime/total-time-day', 
        queryParams: {
          'driverId': driverId,
          'workDate': formattedDate
        }
      ),
      onSuccess: (data) => data['data'] as String,
      defaultValue: '0 giờ 0 phút',
      defaultErrorMessage: 'Không thể tải thông tin thời gian làm việc hôm nay'
    );
  }

  Future<String> getWorkingTimeRange(String driverId, DateTime fromDate, DateTime toDate) async {
    final fromDateFormatted = '${fromDate.year}/${fromDate.month}/${fromDate.day}';
    final toDateFormatted = '${toDate.year}/${toDate.month}/${toDate.day}';
    
    try {
      final response = await ApiUtils.get(
        '/api/DriverDailyWorkingTime/total-time-range', 
        queryParams: {
          'driverId': driverId,
          'fromDate': fromDateFormatted,
          'toDate': toDateFormatted
        }
      );
      
      return ApiUtils.handleResponse(
        response, 
        (data) => data['data'] as String,
        defaultErrorMessage: 'Không thể lấy thông tin thời gian làm việc trong khoảng thời gian này'
      );
    } catch (e) {
      throw Exception('Lỗi: ${e.toString()}');
    }
  }
}
