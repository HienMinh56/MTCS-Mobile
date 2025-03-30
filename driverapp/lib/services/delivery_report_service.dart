import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

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
}
