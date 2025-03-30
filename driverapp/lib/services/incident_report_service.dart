import 'dart:convert';
import 'dart:io';
import 'package:driverapp/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
  static const String _baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  /// Submits an incident report with optional images
  Future<IncidentReportResponse> submitIncidentReport({
    required String tripId,
    required String incidentType,
    required String description,
    required String location,
    required int type, // 1 = On Site, 2 = Change Vehicle
    required String status, // 'Resolved' or 'Unresolved'
    String? resolutionDetails,
    List<File> images = const [],
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/IncidentReport'),
      );
      
      // Add text fields
      request.fields['TripId'] = tripId;
      request.fields['IncidentType'] = incidentType;
      request.fields['Description'] = description;
      request.fields['Location'] = location;
      request.fields['Type'] = type.toString();
      request.fields['ImageType'] = '1'; // Default to 1 as requested
      request.fields['Status'] = "Handling";
      
      // Add resolution details if provided
      if (resolutionDetails != null && resolutionDetails.isNotEmpty) {
        request.fields['ResolutionDetails'] = resolutionDetails;
      }
      
      // Add all images
      for (var image in images) {
        if (await image.exists()) {
          final fileName = image.path.split('/').last;
          final bytes = await image.readAsBytes();
          
          // Determine content type based on file extension
          String contentType = 'image/jpeg';
          if (fileName.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          } else if (fileName.toLowerCase().endsWith('.gif')) {
            contentType = 'image/gif';
          }
          
          // Fixed: Use MediaType from http_parser package
          final parsedContentType = contentType.split('/');
          
          request.files.add(
            http.MultipartFile.fromBytes(
              'Image',
              bytes,
              filename: fileName,
              contentType: MediaType(parsedContentType[0], parsedContentType[1]),
            ),
          );
        }
      }
      
      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      Map<String, dynamic> jsonResponse;
      
      try {
        jsonResponse = json.decode(responseBody);
      } catch (e) {
        return IncidentReportResponse(
          success: false,
          message: 'Lỗi phân tích dữ liệu: $responseBody',
        );
      }
      
      // Check response status
      if (response.statusCode == 200 && jsonResponse['status'] == 1) {
        return IncidentReportResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Báo cáo đã được gửi thành công',
          data: jsonResponse['data'],
        );
      } else {
        return IncidentReportResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Lỗi khi gửi báo cáo',
          data: jsonResponse['data'],
        );
      }
    } on SocketException {
      return IncidentReportResponse(
        success: false,
        message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
      );
    } catch (e) {
      return IncidentReportResponse(
        success: false,
        message: 'Đã xảy ra lỗi: $e',
      );
    }
  }

  Future<Map<String, dynamic>> getIncidentReportsByTripId(String tripId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/IncidentReport?tripId=$tripId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Error: HTTP ${response.statusCode}', 'data': []};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Error: $e', 'data': []};
    }
  }

  /// Updates an existing incident report with resolution details
  Future<Map<String, dynamic>> updateIncidentReport({
    required String reportId,
    required String tripId,
    required String incidentType,
    String? description,
    String? location,
    required String status,
    String? resolutionDetails,
    String? handledBy,
    DateTime? handledTime,
    List<File>? resolutionImages, // Type 2
    List<File>? receiptImages,    // Type 3
    int? type,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/IncidentReport');
      
      // Create multipart request
      var request = http.MultipartRequest('PUT', uri);
      
      // Add text fields
      request.fields['ReportId'] = reportId;
      request.fields['TripId'] = tripId;
      request.fields['IncidentType'] = incidentType;
      request.fields['Status'] = status;
      
      if (description != null) {
        request.fields['Description'] = description;
      }
      
      if (location != null) {
        request.fields['Location'] = location;
      }
      
      if (resolutionDetails != null) {
        request.fields['ResolutionDetails'] = resolutionDetails;
      }
      
      if (handledBy != null) {
        request.fields['HandledBy'] = handledBy;
      }
      
      if (handledTime != null) {
        // Format date as ISO 8601 string
        request.fields['HandledTime'] = handledTime.toUtc().toIso8601String();
      }
      
      if (type != null) {
        request.fields['Type'] = type.toString();
      }
      
      // Add image types for resolution images (Type 2)
      if (resolutionImages != null && resolutionImages.isNotEmpty) {
        for (int i = 0; i < resolutionImages.length; i++) {
          request.fields['ImageType'] = '2'; // 2 for resolution images
        }
      }
      
      // Add image types for receipt images (Type 3)
      if (receiptImages != null && receiptImages.isNotEmpty) {
        for (int i = 0; i < receiptImages.length; i++) {
          request.fields['ImageType'] = '3'; // 3 for receipt images
        }
      }
      
      // Add resolution images (Type 2)
      if (resolutionImages != null) {
        for (var file in resolutionImages) {
          await _addImageToRequest(request, file, 'AddedImage');
        }
      }
      
      // Add receipt images (Type 3)
      if (receiptImages != null) {
        for (var file in receiptImages) {
          await _addImageToRequest(request, file, 'AddedImage');
        }
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Error updating incident report: ${response.body}');
        return {
          'status': response.statusCode,
          'message': 'Error updating incident report: ${response.body}',
        };
      }
    } catch (e) {
      print('Exception during incident report update: $e');
      return {
        'status': 500,
        'message': 'Exception during incident report update: $e',
      };
    }
  }
  
  // Helper method to add images to multipart request
  Future<void> _addImageToRequest(http.MultipartRequest request, File file, String fieldName) async {
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();
    String mimeType;
    
    // Determine mime type based on file extension
    switch (fileExtension) {
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break;
      case 'png':
        mimeType = 'image/png';
        break;
      case 'gif':
        mimeType = 'image/gif';
        break;
      default:
        mimeType = 'application/octet-stream';
    }
    
    final multipartFile = await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: MediaType.parse(mimeType),
    );
    request.files.add(multipartFile);
  }
}