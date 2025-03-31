import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/utils/constants.dart';
import 'package:driverapp/utils/api_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripService {
  final String _baseUrl = Constants.apiBaseUrl;
  
  Future<List<Trip>> getDriverTrips(String driverId, {required String status}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/trips?driverId=$driverId&status=$status'),
      headers: ApiUtils.headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 200) {
        final List<dynamic> tripsJson = data['data'];
        return tripsJson.map((json) => Trip.fromJson(json)).toList();
      } else {
        throw Exception('API error: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load trips: ${response.statusCode}');
    }
  }

  // Method to get detailed information about a specific trip
  Future<Map<String, dynamic>> getTripDetail(String tripId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/trips?tripId=$tripId'),
        headers: ApiUtils.headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load trip details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load trip details: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderByTripId(String tripId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/order/orders?tripId=$tripId'),
        headers: ApiUtils.headers,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1) {
          return data['data'][0];
        } else {
          throw Exception('API error: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load order details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load order details: $e');
    }
  }

  Future<Map<String, dynamic>> updateTripStatus(String tripId, String newStatus) async {
    final url = '$_baseUrl/api/trips/$tripId/status';
    
    try {
      // Retrieve the saved token from secure storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      
      // Create headers with authentication token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: json.encode(newStatus),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': data['status'] == 200,
          'message': data['message'],
          'newStatus': newStatus,
        };
      } else {
        throw Exception('Failed to update trip status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update trip status: $e');
    }
  }
}
