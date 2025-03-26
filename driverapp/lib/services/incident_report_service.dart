import 'dart:convert';
import 'package:driverapp/services/auth_service.dart';
import 'package:driverapp/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class IncidentReportService {
  final String _baseUrl = Constants.apiBaseUrl;
  final AuthService _authService = AuthService();
  
  Future<Map<String, dynamic>> submitIncidentReport({
    required String tripId,
    required String incidentType,
    required String description,
    required String location,
    required DateTime incidentTime,
    required List<File> images,
    String status = 'Pending', // Default status
    int type = 1,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/IncidentReport');
      final token = await _authService.getToken();
      final userId = await _authService.getUserId();
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers.addAll({
        'accept': 'text/plain',
        'Authorization': 'Bearer $token',
      });
      
      // Add text fields
      request.fields['TripId'] = tripId;
      request.fields['ReportedBy'] = userId ?? 'Driver';
      request.fields['IncidentType'] = incidentType;
      request.fields['Description'] = description;
      request.fields['Status'] = status;
      request.fields['Location'] = location;
      request.fields['Type'] = type.toString();
      request.fields['IncidentTime'] = incidentTime.toUtc().toIso8601String();
      request.fields['CreatedDate'] = DateTime.now().toUtc().toIso8601String();
      
      // Add image files
      for (var i = 0; i < images.length; i++) {
        final file = images[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        
        final multipartFile = http.MultipartFile(
          'Image',
          stream,
          length,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        
        request.files.add(multipartFile);
      }
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit incident report. Status code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      return {
        'status': 0,
        'message': 'Error: $e',
        'data': null
      };
    }
  }
}
