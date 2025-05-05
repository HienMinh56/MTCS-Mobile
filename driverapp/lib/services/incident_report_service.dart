import 'dart:io';
import 'package:driverapp/utils/api_utils.dart';

class IncidentReportResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  IncidentReportResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

class IncidentReportService {
  /// Submits an incident report with optional images
  Future<IncidentReportResponse> submitIncidentReport({
    required String tripId,
    required String incidentType,
    required String description,
    required String location,
    required int type, // 1 = On Site, 2 = Change Vehicle
    required int vehicleType, // 1 = Head, 2 = Trailer
    required String status, // 'Resolved' or 'Unresolved'
    String? resolutionDetails,
    List<File> images = const [],
  }) async {
    // Create map of fields for multipart request
    Map<String, String> fields = {
      'TripId': tripId,
      'IncidentType': incidentType,
      'Description': description,
      'Location': location,
      'Type': type.toString(),
      'VehicleType': vehicleType.toString(),
      'Status': "Handling",
    };
    
    // Add resolution details if provided
    if (resolutionDetails != null && resolutionDetails.isNotEmpty) {
      fields['ResolutionDetails'] = resolutionDetails;
    }
    
    // Add images
    Map<String, List<File>> files = {};
    if (images.isNotEmpty) {
      files['Image'] = images;
    }
    
    final result = await ApiUtils.safeMultipartApiCall(
      apiCall: () => ApiUtils.multipartPost(
        '/api/IncidentReport/IncidentImage',
        fields,
        files
      ),
      defaultErrorMessage: 'Không thể gửi báo cáo sự cố'
    );
    
    return IncidentReportResponse(
      success: result['success'],
      message: result['message'],
      data: result['data'],
    );
  }

  Future<Map<String, dynamic>> getIncidentReportsByTripId(String tripId) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/IncidentReport',
        queryParams: {'tripId': tripId}
      ),
      onSuccess: (data) => data,
      defaultValue: {'status': 0, 'message': 'Không thể tải báo cáo sự cố', 'data': []},
      defaultErrorMessage: 'Không thể tải báo cáo sự cố'
    );
  }

  /// Uploads billing images for an incident report
  Future<Map<String, dynamic>> uploadBillingImages({
    required String reportId,
    required List<File> images,
  }) async {
    print('DEBUG: Starting uploadBillingImages');
    print('DEBUG: Report ID: $reportId');
    print('DEBUG: Number of images: ${images.length}');
    
    // List image paths for debugging
    for (int i = 0; i < images.length; i++) {
      print('DEBUG: Image $i path: ${images[i].path}');
    }
    
    // Create fields and files maps
    Map<String, String> fields = {
      'ReportId': reportId,
    };
    
    Map<String, List<File>> files = {
      'Image': images,
    };
    
    print('DEBUG: Sending API request to /api/IncidentReport/BillImage');
    final result = await ApiUtils.safeMultipartApiCall(
      apiCall: () => ApiUtils.multipartPost(
        '/api/IncidentReport/BillImage',
        fields,
        files
      ),
      defaultErrorMessage: 'Không thể tải lên hình ảnh hóa đơn'
    );
    
    print('DEBUG: API response received');
    print('DEBUG: Success: ${result['success']}');
    print('DEBUG: Message: ${result['message']}');
    print('DEBUG: Status: ${result['status']}');
    
    return result;
  }
  
  /// Uploads exchange/resolution images for an incident report
  Future<Map<String, dynamic>> uploadExchangeImages({
    required String reportId,
    required List<File> images,
  }) async {
    // Create fields and files maps
    Map<String, String> fields = {
      'ReportId': reportId,
    };
    
    Map<String, List<File>> files = {
      'Image': images,
    };
    
    return ApiUtils.safeMultipartApiCall(
      apiCall: () => ApiUtils.multipartPost(
        '/api/IncidentReport/ExchangeImage',
        fields,
        files
      ),
      defaultErrorMessage: 'Không thể tải lên hình ảnh giải quyết'
    );
  }

  /// Resolve an incident report (with optional resolution images)
  Future<Map<String, dynamic>> resolveIncidentReport({
    required String reportId,
    String? resolutionDetails,
    List<File>? resolutionImages,
  }) async {
    try {
      // First upload resolution images if available
      if (resolutionImages != null && resolutionImages.isNotEmpty) {
        await uploadExchangeImages(
          reportId: reportId,
          images: resolutionImages,
        );
      }
      
      // Create request body with reportId and optional resolutionDetails
      final Map<String, dynamic> requestBody = {
        'reportId': reportId,
      };
      
      // Add resolution details if provided
      if (resolutionDetails != null && resolutionDetails.isNotEmpty) {
        requestBody['resolutionDetails'] = resolutionDetails;
      }
      
      return ApiUtils.safeApiCall(
        apiCall: () => ApiUtils.patch('/api/IncidentReport', requestBody),
        onSuccess: (data) => data,
        defaultValue: {
          'status': 0,
          'message': 'Không thể giải quyết báo cáo sự cố',
          'data': null,
        },
        defaultErrorMessage: 'Không thể giải quyết báo cáo sự cố'
      );
    } catch (e) {
      print('❌ Lỗi khi giải quyết sự cố: $e');
      return {
        'status': 0,
        'message': 'Lỗi: $e',
        'data': null,
      };
    }
  }

  // Add method to update an existing incident report
  Future<Map<String, dynamic>> updateIncidentReport({
    required String reportId,
    String? incidentType,
    int? vehicleType,
    String? description,
    String? location,
    int? type,
    List<String>? fileIdsToRemove, // These are actually file URLs, not IDs
    List<File>? addedFiles,
  }) async {
    // Create fields map
    Map<String, String> fields = {
      'ReportId': reportId,
    };
    
    // Add optional fields if provided
    if (incidentType != null) fields['IncidentType'] = incidentType;
    if (description != null) fields['Description'] = description;
    if (location != null) fields['Location'] = location;
    if (vehicleType != null) fields['VehicleType'] = vehicleType.toString();
    if (type != null) fields['Type'] = type.toString();
    
    // Add file URLs to remove - use indexed format for multiple files
    if (fileIdsToRemove != null && fileIdsToRemove.isNotEmpty) {
      for (int i = 0; i < fileIdsToRemove.length; i++) {
        // Use indexed field names with URLs for each image to remove
        fields['RemovedImage[$i]'] = fileIdsToRemove[i];
      }
    }
    
    // Prepare files map
    Map<String, List<File>>? files;
    if (addedFiles != null && addedFiles.isNotEmpty) {
      files = {
        'AddedImage': addedFiles,
      };
    }
    
    return ApiUtils.safeMultipartApiCall(
      apiCall: () => ApiUtils.multipartPut(
        '/api/IncidentReport/mo',
        fields,
        files
      ),
      defaultErrorMessage: 'Không thể cập nhật báo cáo sự cố'
    );
  }
}