import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class FuelReportService {
  static const String _baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  /// Get authentication headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  /// Submits a fuel report to the server
  /// Returns a Map with 'success' boolean and 'message' string
  static Future<Map<String, dynamic>> submitFuelReport({
    required String tripId,
    required double refuelAmount,
    required double fuelCost,
    required String location,
    required List<File> images,
  }) async {
    try {
      var uri = Uri.parse('$_baseUrl/fuel-reports');
      var request = http.MultipartRequest('POST', uri);
      
      // Add form fields
      request.fields['TripId'] = tripId;
      request.fields['RefuelAmount'] = refuelAmount.toString();
      request.fields['FuelCost'] = fuelCost.toString();
      request.fields['Location'] = location;
      
      // Add image files
      for (var imageFile in images) {
        var fileName = path.basename(imageFile.path);
        var fileExtension = path.extension(fileName).toLowerCase();
        String mimeType;
        
        if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
          mimeType = 'image/jpeg';
        } else if (fileExtension == '.png') {
          mimeType = 'image/png';
        } else {
          mimeType = 'image/jpeg'; // Default
        }
        
        request.files.add(await http.MultipartFile.fromPath(
          'files',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ));
      }
      
      // Send the request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Báo cáo đổ nhiên liệu đã được gửi thành công',
          'data': jsonData['data']
        };
      } else {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Không thể gửi báo cáo',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi gửi báo cáo: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getFuelReportsByTripId(String tripId) async {
    try {
      final uri = Uri.parse('$_baseUrl/fuel-reports?tripId=$tripId');
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'status': 500,
        'message': 'Error fetching fuel reports: $e',
        'data': []
      };
    }
  }

  Future<Map<String, dynamic>> updateFuelReport({
    required String reportId,
    required double refuelAmount,
    required double fuelCost,
    required String location,
    required List<String> fileIdsToRemove,
    required List<File> addedFiles,
  }) async {
    try {
      // Check if there's anything to update
      if (fileIdsToRemove.isEmpty && addedFiles.isEmpty && 
          refuelAmount == 0 && fuelCost == 0 && location.isEmpty) {
        return {
          'status': 400,
          'message': 'No changes to update',
          'data': []
        };
      }
      
      // Using http directly instead of http.MultipartRequest to ensure proper handling of multiple fields
      final uri = Uri.parse('$_baseUrl/fuel-reports');
      
      // Create a unique boundary for multipart form data
      var boundary = '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
      
      // Get headers and set the Content-Type for multipart
      var headers = await _getHeaders();
      headers['Content-Type'] = 'multipart/form-data; boundary=$boundary';
      
      // Build the request body manually to ensure proper handling of multiple fields with the same name
      var requestBody = <int>[];
      
      // Helper function to add text fields
      void addFormField(String name, String value) {
        requestBody.addAll(utf8.encode('--$boundary\r\n'));
        requestBody.addAll(utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'));
        requestBody.addAll(utf8.encode(value));
        requestBody.addAll(utf8.encode('\r\n'));
      }
      
      // Add basic fields
      addFormField('ReportId', reportId);
      addFormField('RefuelAmount', refuelAmount.toString());
      addFormField('FuelCost', fuelCost.toString());
      addFormField('Location', location);
      
      // Add file IDs to remove - each as a separate field with the same name
      for (var fileId in fileIdsToRemove) {
        addFormField('FileIdsToRemove', fileId);
      }
      
      // Add files
      for (var file in addedFiles) {
        var fileName = path.basename(file.path);
        var fileExtension = path.extension(fileName).toLowerCase();
        
        String mimeType;
        if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
          mimeType = 'image/jpeg';
        } else if (fileExtension == '.png') {
          mimeType = 'image/png';
        } else {
          mimeType = 'application/octet-stream';
        }
        
        requestBody.addAll(utf8.encode('--$boundary\r\n'));
        requestBody.addAll(utf8.encode('Content-Disposition: form-data; name="AddedFiles"; filename="$fileName"\r\n'));
        requestBody.addAll(utf8.encode('Content-Type: $mimeType\r\n\r\n'));
        
        // Add file bytes
        requestBody.addAll(await file.readAsBytes());
        requestBody.addAll(utf8.encode('\r\n'));
      }
      
      // Add closing boundary
      requestBody.addAll(utf8.encode('--$boundary--\r\n'));
      
      // Create and send the request
      var request = http.Request('PUT', uri);
      request.headers.addAll(headers);
      request.bodyBytes = requestBody;
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'status': 500,
        'message': 'Error updating fuel report: $e',
        'data': []
      };
    }
  }
}
