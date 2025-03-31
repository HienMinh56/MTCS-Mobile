import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'auth_service.dart';

class DeliveryReportService {
  final String _baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  /// Submit a delivery report with optional notes and images
  Future<Map<String, dynamic>> submitDeliveryReport({
    required String tripId,
    String? notes,
    List<File>? imageFiles,
  }) async {
    final uri = Uri.parse('$_baseUrl/delivery-reports');
    final request = http.MultipartRequest('POST', uri);
    
    // Add authorization header
    final token = await AuthService.getAuthToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add text fields
    request.fields['TripId'] = tripId;
    if (notes != null && notes.isNotEmpty) {
      request.fields['Notes'] = notes;
    }
    
    // Add files if provided
    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (var imageFile in imageFiles) {
        final fileName = path.basename(imageFile.path);
        final fileExtension = path.extension(fileName).toLowerCase();
        final mimeType = fileExtension == '.png' 
            ? 'image/png' 
            : fileExtension == '.jpg' || fileExtension == '.jpeg' 
                ? 'image/jpeg' 
                : 'application/octet-stream';
                
        final file = await http.MultipartFile.fromPath(
          'files',
          imageFile.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(file);
      }
    }
    
    // Send the request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    // Process response
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return {
        'success': jsonResponse['status'] == 200,
        'message': jsonResponse['message'] ?? '',
        'data': jsonResponse['data']
      };
    } else {
      throw Exception('Server returned status code: ${response.statusCode}');
    }
  }
  
  /// Get delivery reports by trip ID
  Future<Map<String, dynamic>> getDeliveryReportsByTripId(String tripId) async {
    try {
      final uri = Uri.parse('$_baseUrl/delivery-reports?tripId=$tripId');
      
      // Get auth token
      final token = await AuthService.getAuthToken();
      
      // Make request with auth header
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        throw Exception('Failed to load delivery reports. Status: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'status': 0, 
        'message': 'Error loading delivery reports: $e',
        'data': []
      };
    }
  }
}
