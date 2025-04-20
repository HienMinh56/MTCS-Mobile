import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart'; // Import AuthService

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
    required int vehicleType, // 1 = Head, 2 = Trailer
    required String status, // 'Resolved' or 'Unresolved'
    String? resolutionDetails,
    List<File> images = const [],
  }) async {
    try {
      // Get authentication token
      String? authToken = await AuthService.getAuthToken();
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/IncidentReport/IncidentImage'), // Updated endpoint
      );
      
      // Add authorization header
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Add text fields
      request.fields['TripId'] = tripId;
      request.fields['IncidentType'] = incidentType;
      request.fields['Description'] = description;
      request.fields['Location'] = location;
      request.fields['Type'] = type.toString();
      request.fields['VehicleType'] = vehicleType.toString(); // Default to 1 as requested
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
          message: 'Response parsing error: $responseBody',
        );
      }
      
      // Return the response directly from server
      return IncidentReportResponse(
        success: response.statusCode == 200 && jsonResponse['status'] == 1,
        message: jsonResponse['message'] ?? 'Unknown server response',
        data: jsonResponse['data'],
      );
    } on SocketException {
      return IncidentReportResponse(
        success: false,
        message: 'Network connection error',
      );
    } catch (e) {
      return IncidentReportResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> getIncidentReportsByTripId(String tripId) async {
    try {
      // Get authentication token
      String? authToken = await AuthService.getAuthToken();
      
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Add authorization header if token exists
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/IncidentReport?tripId=$tripId'),
        headers: headers,
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

  
  /// Uploads billing images for an incident report
  Future<Map<String, dynamic>> uploadBillingImages({
    required String reportId,
    required List<File> images,
  }) async {
    try {
      // Get authentication token
      String? authToken = await AuthService.getAuthToken();
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/IncidentReport/BillImage'),
      );
      
      // Add authorization header
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Add report ID
      request.fields['ReportId'] = reportId;
      
      // Add all images
      for (var image in images) {
        if (await image.exists()) {
          await _addImageToRequest(request, image, 'Image');
        }
      }
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error uploading billing images: ${response.body}');
        return {
          'status': response.statusCode,
          'message': 'Error uploading billing images: ${response.body}',
        };
      }
    } catch (e) {
      print('Exception during billing image upload: $e');
      return {
        'status': 500,
        'message': 'Exception during billing image upload: $e',
      };
    }
  }
  
  /// Uploads exchange/resolution images for an incident report
  Future<Map<String, dynamic>> uploadExchangeImages({
    required String reportId,
    required List<File> images,
  }) async {
    try {
      // Get authentication token
      String? authToken = await AuthService.getAuthToken();
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/IncidentReport/ExchangeImage'),
      );
      
      // Add authorization header
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Add report ID
      request.fields['ReportId'] = reportId;
      
      // Add all images
      for (var image in images) {
        if (await image.exists()) {
          await _addImageToRequest(request, image, 'Image');
        }
      }
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error uploading exchange images: ${response.body}');
        return {
          'status': response.statusCode,
          'message': 'Error uploading exchange images: ${response.body}',
        };
      }
    } catch (e) {
      print('Exception during exchange image upload: $e');
      return {
        'status': 500,
        'message': 'Exception during exchange image upload: $e',
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
      
      // Now mark the incident as resolved using PATCH endpoint
      final url = Uri.parse('$_baseUrl/IncidentReport');
      
      // Create request body with reportId and optional resolutionDetails
      final Map<String, dynamic> requestBody = {
        'reportId': reportId,
      };
      
      // Add resolution details if provided
      if (resolutionDetails != null && resolutionDetails.isNotEmpty) {
        requestBody['resolutionDetails'] = resolutionDetails;
      }
      
      // Get authentication token
      final token = await AuthService.getAuthToken();
      
      // Make the PATCH request
      final response = await http.patch(
        url,
        headers: {
          'accept': 'text/plain',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        print('Failed to resolve incident report: ${response.body}');
        return {
          'status': 0,
          'message': 'Failed to resolve incident report. Status code: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      print('Exception during incident resolution: $e');
      return {
        'status': 0,
        'message': 'Error: $e',
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
    List<String>? fileIdsToRemove,
    List<File>? addedFiles,
  }) async {
    try {
      // Create a boundary string that is very unlikely to appear in the content
      final String boundary = '----${DateTime.now().millisecondsSinceEpoch}';
      final Uri url = Uri.parse('$_baseUrl/IncidentReport/mo');
      final token = await AuthService.getAuthToken();
      
      // Build request manually for better control over the multipart format
      final request = http.Request('PUT', url);
      request.headers['Content-Type'] = 'multipart/form-data; boundary=$boundary';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Start building request body
      final List<int> body = [];
      
      // Add text fields
      _addFormField(body, boundary, 'ReportId', reportId);
      if (incidentType != null) _addFormField(body, boundary, 'IncidentType', incidentType);
      if (description != null) _addFormField(body, boundary, 'Description', description);
      if (location != null) _addFormField(body, boundary, 'Location', location);
      _addFormField(body, boundary, 'Type', type?.toString() ?? '1');
      _addFormField(body, boundary, 'VehicleType', vehicleType?.toString() ?? '1'); // Default to 1 as requested
      
      // Add file IDs to remove
      if (fileIdsToRemove != null && fileIdsToRemove.isNotEmpty) {
        print('Files to remove: $fileIdsToRemove');
        for (final fileId in fileIdsToRemove) {
          _addFormField(body, boundary, 'RemovedImage', fileId);
        }
      }
      
      // Add new image files
      if (addedFiles != null && addedFiles.isNotEmpty) {
        for (final file in addedFiles) {
          await _addFilePart(body, boundary, 'AddedImage', file);
        }
      }
      
      // Close the request body
      body.addAll(utf8.encode('--$boundary--\r\n'));
      
      // Set the request body
      request.bodyBytes = body;
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Parse and return the response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Error updating incident report: ${response.statusCode}, ${response.body}');
        return {
          'status': 0,
          'message': 'Error: ${response.statusCode} ${response.reasonPhrase}',
          'data': null
        };
      }
    } catch (e) {
      print('Exception while updating incident report: $e');
      return {
        'status': 0,
        'message': 'Exception: $e',
        'data': null
      };
    }
  }
  
  // Helper method to add a form field to the request body
  void _addFormField(List<int> body, String boundary, String name, String value) {
    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'));
    body.addAll(utf8.encode('$value\r\n'));
  }
  
  // Helper method to add a file part to the request body
  Future<void> _addFilePart(List<int> body, String boundary, String name, File file) async {
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();
    
    String contentType;
    if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
      contentType = 'image/jpeg';
    } else if (fileExtension == 'png') {
      contentType = 'image/png';
    } else {
      contentType = 'application/octet-stream';
    }
    
    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="$name"; filename="$fileName"\r\n'));
    body.addAll(utf8.encode('Content-Type: $contentType\r\n\r\n'));
    body.addAll(bytes);
    body.addAll(utf8.encode('\r\n'));
  }
}