import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiUtils {
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

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
}
