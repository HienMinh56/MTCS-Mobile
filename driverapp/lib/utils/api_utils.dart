import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driverapp/utils/constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class ApiUtils {
  static const String baseUrl = Constants.apiBaseUrl;
  
  // Default headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get authentication headers
  static Future<Map<String, String>> getAuthHeaders({bool isMultipart = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('authToken');
    
    Map<String, String> headers = {};
    
    // Only add Content-Type for non-multipart requests
    // For multipart requests, Content-Type is set by the MultipartRequest
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    } else {
      headers['Accept'] = '*/*';
    }
    
    // Add authorization token if available
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Helper for GET requests
  static Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = await getAuthHeaders();
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );
    
    return http.get(uri, headers: headers);
  }
  
  // Helper for POST requests
  static Future<http.Response> post(String endpoint, dynamic body) async {
    final headers = await getAuthHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return http.post(
      uri, 
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  // Helper for PUT requests
  static Future<http.Response> put(String endpoint, dynamic body) async {
    final headers = await getAuthHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return http.put(
      uri, 
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  // Helper for PATCH requests
  static Future<http.Response> patch(String endpoint, dynamic body) async {
    final headers = await getAuthHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return http.patch(
      uri, 
      headers: headers,
      body: jsonEncode(body),
    );
  }
  
  // Helper for DELETE requests
  static Future<http.Response> delete(String endpoint) async {
    final headers = await getAuthHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return http.delete(uri, headers: headers);
  }
  
  // Helper for multipart requests (POST)
  static Future<http.StreamedResponse> multipartPost(
    String endpoint,
    Map<String, String> fields,
    Map<String, List<File>>? files,
  ) async {
    final headers = await getAuthHeaders(isMultipart: true);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);
    
    // Add form fields
    request.fields.addAll(fields);
    
    // Add files if provided
    if (files != null) {
      for (var fileEntry in files.entries) {
        String fieldName = fileEntry.key;
        for (var file in fileEntry.value) {
          if (await file.exists()) {
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
              fieldName,
              file.path,
              contentType: MediaType.parse(mimeType),
            ));
          }
        }
      }
    }
    
    return request.send();
  }
  
  // Helper for multipart requests (PUT)
  static Future<http.StreamedResponse> multipartPut(
    String endpoint,
    Map<String, String> fields,
    Map<String, List<File>>? files,
  ) async {
    final headers = await getAuthHeaders(isMultipart: true);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    var request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(headers);
    
    // Add form fields
    request.fields.addAll(fields);
    
    // Add files if provided
    if (files != null) {
      for (var fileEntry in files.entries) {
        String fieldName = fileEntry.key;
        for (var file in fileEntry.value) {
          if (await file.exists()) {
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
              fieldName,
              file.path,
              contentType: MediaType.parse(mimeType),
            ));
          }
        }
      }
    }
    
    return request.send();
  }
  
  // Generic response handler
  static T handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic> data) onSuccess,
  ) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 200 || data['status'] == 1) {
        return onSuccess(data);
      } else {
        throw Exception(data['message'] ?? 'API error occurred');
      }
    } else {
      try {
        // Try to parse error response as JSON
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Request failed: ${response.statusCode}');
      } catch (e) {
        // If not valid JSON, return the status code
        throw Exception('Request failed: ${response.statusCode}');
      }
    }
  }
  
  // Helper method to convert StreamedResponse to Response
  static Future<http.Response> streamedResponseToResponse(http.StreamedResponse streamedResponse) async {
    final String body = await streamedResponse.stream.bytesToString();
    return http.Response(body, streamedResponse.statusCode, headers: streamedResponse.headers);
  }
}
