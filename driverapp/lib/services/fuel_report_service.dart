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
    final String? token = prefs.getString('authToken');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
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
    try {
      var uri = Uri.parse('$_baseUrl/fuel-reports');
      var request = http.MultipartRequest('POST', uri);
      
      // Get headers with authorization token
      final headers = await _getHeaders();
      
      // Add headers to request (except Content-Type which is set by MultipartRequest)
      headers.forEach((key, value) {
        if (key != 'Content-Type') {
          request.headers[key] = value;
        }
      });
      
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
      
      // Return the raw response from server
      return {
        'success': response.statusCode == 200 && (jsonData['status'] == 200 || jsonData['status'] == 1),
        'message': jsonData['message'] ?? 'Unknown response',
        'data': jsonData['data'],
        'statusCode': response.statusCode
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'statusCode': 500
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
      
      final uri = Uri.parse('$_baseUrl/fuel-reports');
      
      // Create a MultipartRequest
      var request = http.MultipartRequest('PUT', uri);
      
      // Add authorization headers
      final headers = await _getHeaders();
      headers.forEach((key, value) {
        if (key != 'Content-Type') {
          request.headers[key] = value;
        }
      });
      
      // Add form fields
      request.fields['ReportId'] = reportId;
      request.fields['RefuelAmount'] = refuelAmount.toString();
      request.fields['FuelCost'] = fuelCost.toString();
      request.fields['Location'] = location;
      
      // Add file IDs to remove - each as a separate field with the same name
      for (int i = 0; i < fileIdsToRemove.length; i++) {
        request.fields['FileIdsToRemove[$i]'] = fileIdsToRemove[i];
      }
      
      // Add new files
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
        
        request.files.add(await http.MultipartFile.fromPath(
          'AddedFiles',
          file.path,
          contentType: MediaType.parse(mimeType),
        ));
      }
      
      // Send request and process response
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
