import 'dart:io';
import 'package:driverapp/utils/api_utils.dart';

class FuelReportService {
  static const String _endpoint = '/api/fuel-reports';

  /// Static version of submitFuelReport that creates an instance internally
  static Future<Map<String, dynamic>> submitFuelReport({
    required String tripId,
    required double refuelAmount,
    required double fuelCost,
    required String location,
    required List<File> images,
  }) async {
    final instance = FuelReportService();
    return instance.submitFuelReportInstance(
      tripId: tripId,
      refuelAmount: refuelAmount,
      fuelCost: fuelCost,
      location: location,
      images: images,
    );
  }
  
  /// Instance implementation of submitFuelReport
  Future<Map<String, dynamic>> submitFuelReportInstance({
    required String tripId,
    required double refuelAmount,
    required double fuelCost,
    required String location,
    required List<File> images,
  }) async {
    return ApiUtils.safeMultipartApiCall(
      apiCall: () {
        // Prepare fields for multipart request
        Map<String, String> fields = {
          'TripId': tripId,
          'RefuelAmount': refuelAmount.toString(),
          'FuelCost': fuelCost.toString(),
          'Location': location,
        };
        
        // Prepare files for multipart request
        Map<String, List<File>> files = {
          'files': images,
        };
        
        return ApiUtils.multipartPost(_endpoint, fields, files);
      },
      defaultErrorMessage: 'Không thể gửi báo cáo nhiên liệu'
    );
  }

  Future<Map<String, dynamic>> getFuelReportsByTripId(String tripId) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(_endpoint, queryParams: {'tripId': tripId}),
      onSuccess: (responseData) => responseData,
      defaultValue: {
        'status': 500,
        'message': 'Không thể tải báo cáo nhiên liệu',
        'data': []
      },
      defaultErrorMessage: 'Không thể tải báo cáo nhiên liệu'
    );
  }

  Future<Map<String, dynamic>> updateFuelReport({
    required String reportId,
    required double refuelAmount,
    required double fuelCost,
    required String location,
    required List<String> fileIdsToRemove,
    required List<File> addedFiles,
  }) async {
    // Create fields map
    Map<String, String> fields = {
      'ReportId': reportId,
      'RefuelAmount': refuelAmount.toString(),
      'FuelCost': fuelCost.toString(),
      'Location': location,
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
      apiCall: () => ApiUtils.multipartPut(_endpoint, fields, files),
      defaultErrorMessage: 'Không thể cập nhật báo cáo nhiên liệu'
    );
  }
}
