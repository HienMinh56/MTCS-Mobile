import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class FuelReportService {
  static const String _baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  /// Submits a fuel report to the server
  /// 
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
}
