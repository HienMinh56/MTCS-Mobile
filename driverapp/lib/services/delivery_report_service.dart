import 'dart:io';
import 'package:driverapp/utils/api_utils.dart';

class DeliveryReportService {

  /// Submit a delivery report with optional notes and images
  Future<Map<String, dynamic>> submitDeliveryReport({
    required String tripId,
    String? notes,
    List<File>? imageFiles,
  }) async {
    // Prepare fields map
    Map<String, String> fields = {
      'TripId': tripId,
    };
    
    if (notes != null && notes.isNotEmpty) {
      fields['Notes'] = notes;
    }
    
    // Prepare files map
    Map<String, List<File>>? files;
    if (imageFiles != null && imageFiles.isNotEmpty) {
      files = {
        'files': imageFiles,
      };
    }
    
    return ApiUtils.safeMultipartApiCall(
      apiCall: () {
        return ApiUtils.multipartPost(
          '/api/delivery-reports',
          fields,
          files
        );
      },
      defaultErrorMessage: 'Không thể gửi báo cáo giao hàng'
    );
  }
  
  /// Get delivery reports by trip ID
  Future<Map<String, dynamic>> getDeliveryReportsByTripId(String tripId) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/delivery-reports',
        queryParams: {'tripId': tripId}
      ),
      onSuccess: (jsonResponse) => jsonResponse,
      defaultValue: {
        'status': 0, 
        'message': 'Không thể tải báo cáo giao hàng',
        'data': []
      },
      defaultErrorMessage: 'Không thể tải báo cáo giao hàng'
    );
  }
}