import 'dart:io';
import 'package:driverapp/utils/api_utils.dart';
import 'package:driverapp/models/expense_report_type.dart';
import 'package:driverapp/models/expense_report_model.dart';

class ExpenseReportService {
  static const String _endpoint = '/api/ExpenseReport';
  static const String _typeEndpoint = '/api/ExpenseReportType';
  
  // Cache danh sách loại báo cáo chi phí để tránh phải gọi API liên tục
  static List<ExpenseReportType>? _cachedReportTypes;  static DateTime? _lastCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 30); // Cache có hiệu lực trong 30 phút

  /// Static method to get all expense report types
  static Future<List<ExpenseReportType>> getAllExpenseReportTypes() async {
    // Kiểm tra xem cache có còn hiệu lực không
    if (_cachedReportTypes != null && _lastCacheTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastCacheTime!) < _cacheDuration) {
        // Nếu cache còn hiệu lực, trả về dữ liệu đã cache
        return _cachedReportTypes!;
      }
    }
    
    // Nếu cache không có hiệu lực hoặc chưa có cache, tải dữ liệu mới
    final types = await _fetchExpenseReportTypes();
    
    // Cập nhật cache
    _cachedReportTypes = types;
    _lastCacheTime = DateTime.now();
    
    return types;
  }

  /// Fetch data from API
  static Future<List<ExpenseReportType>> _fetchExpenseReportTypes() async {
    final instance = ExpenseReportService();
    return instance._fetchExpenseReportTypesInstance();
  }

  /// Instance implementation of _fetchExpenseReportTypes
  Future<List<ExpenseReportType>> _fetchExpenseReportTypesInstance() async {
    final result = await ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get('$_typeEndpoint/GetAllExpenseReportTypes'),
      onSuccess: (responseData) => responseData,
      defaultValue: {
        'status': 500,
        'message': 'Không thể tải loại báo cáo chi phí',
        'data': []
      },
      defaultErrorMessage: 'Không thể tải loại báo cáo chi phí'
    );
    
    if (result['status'] == 200 && result['data'] != null) {
      final List<dynamic> data = result['data'];
      final List<ExpenseReportType> types = data
          .map((json) => ExpenseReportType.fromJson(json))
          .where((type) => type.isActive == 1) // Chỉ lấy các loại đang active
          .toList();
      
      // Sắp xếp danh sách, đưa "other" (chi phí khác) xuống cuối cùng
      types.sort((a, b) {
        if (a.reportTypeId == 'other') return 1;
        if (b.reportTypeId == 'other') return -1;
        return a.reportType.compareTo(b.reportType);
      });
      
      return types;
    }
    
    return [];
  }

  /// Static version of submitExpenseReport that creates an instance internally
  static Future<Map<String, dynamic>> submitExpenseReport({
    required String tripId,
    required String reportTypeId,
    required double cost,
    required String location,
    required int isPay,
    required String description,
    required List<File> images,
  }) async {
    final instance = ExpenseReportService();
    return instance.submitExpenseReportInstance(
      tripId: tripId,
      reportTypeId: reportTypeId,
      cost: cost,
      location: location,
      isPay: isPay,
      description: description,
      images: images,
    );
  }
  
  /// Instance implementation of submitExpenseReport
  Future<Map<String, dynamic>> submitExpenseReportInstance({
    required String tripId,
    required String reportTypeId,
    required double cost,
    required String location,
    required int isPay,
    required String description,
    required List<File> images,
  }) async {
    return ApiUtils.safeMultipartApiCall(
      apiCall: () {
        // Prepare fields for multipart request
        Map<String, String> fields = {
          'TripId': tripId,
          'ReportTypeId': reportTypeId,
          'Cost': cost.toString(),
          'Location': location,
          'IsPay': isPay.toString(),
          'Description': description,
        };
        
        // Prepare files for multipart request
        Map<String, List<File>> files = {
          'Files': images,
        };
        
        return ApiUtils.multipartPost('$_endpoint/CreateExpenseReport', fields, files);
      },
      defaultErrorMessage: 'Không thể gửi báo cáo chi phí'
    );
  }
  Future<Map<String, dynamic>> getExpenseReportsByTripId(String tripId) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get('$_endpoint/GetAllExpenseReports', queryParams: {'tripId': tripId}),
      onSuccess: (responseData) => responseData,
      defaultValue: {
        'status': 500,
        'message': 'Không thể tải báo cáo chi phí',
        'data': []
      },
      defaultErrorMessage: 'Không thể tải báo cáo chi phí'
    );
  }

  Future<Map<String, dynamic>> updateExpenseReport({
    required String reportId,
    required String reportTypeId,
    required double cost,
    required String location,
    required int isPay,
    required String description,
    required List<String> fileIdsToRemove,
    required List<File> addedFiles,
  }) async {
    // Create fields map
    Map<String, String> fields = {
      'ReportId': reportId,
      'ReportTypeId': reportTypeId,
      'Cost': cost.toString(),
      'Location': location,
      'IsPay': isPay.toString(),
      'Description': description,
    };
    
    // Add file IDs to remove - use indexed format for multiple files
    if (fileIdsToRemove.isNotEmpty) {
      for (int i = 0; i < fileIdsToRemove.length; i++) {
        // Use indexed field names for each file to remove
        fields['FileIdsToRemove[$i]'] = fileIdsToRemove[i];
      }
    }
    
    // Prepare files map
    Map<String, List<File>>? files;
    if (addedFiles.isNotEmpty) {
      files = {
        'AddedFiles': addedFiles,
      };
    }
    
    return ApiUtils.safeMultipartApiCall(
      apiCall: () => ApiUtils.multipartPut('$_endpoint/UpdateExpenseReport', fields, files),
      defaultErrorMessage: 'Không thể cập nhật báo cáo chi phí'
    );
  }

  /// Static method to get all expense reports for a trip
  static Future<Map<String, dynamic>> getAllExpenseReports(String tripId) async {
    final instance = ExpenseReportService();
    return instance.getExpenseReportsByTripId(tripId);
  }

  /// Static method to get all expense reports by driver ID
  static Future<Map<String, dynamic>> getAllExpenseReportsByDriverId(String driverId) async {
    final instance = ExpenseReportService();
    return instance.getExpenseReportsByDriverId(driverId);
  }

  /// Instance method to get expense reports by driver ID
  Future<Map<String, dynamic>> getExpenseReportsByDriverId(String driverId) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get('$_endpoint/GetAllExpenseReports', queryParams: {'driverId': driverId}),
      onSuccess: (responseData) => responseData,
      defaultValue: {
        'status': 500,
        'message': 'Không thể tải báo cáo chi phí',
        'data': []
      },
      defaultErrorMessage: 'Không thể tải báo cáo chi phí'
    );
  }

  /// Static method to get all expense reports as typed models for a trip
  static Future<List<ExpenseReport>> getAllExpenseReportModels(String tripId) async {
    final response = await getAllExpenseReports(tripId);
    
    if (response['status'] == 200 && response['data'] != null) {
      final List<dynamic> data = response['data'];
      final List<ExpenseReport> reports = data
          .map((json) => ExpenseReport.fromJson(json))
          .toList();
      
      // Sort by report time (newest first)
      reports.sort((a, b) => b.reportTime.compareTo(a.reportTime));
      return reports;
    }
    
    return [];
  }
}