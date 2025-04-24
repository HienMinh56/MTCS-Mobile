import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/incident_report_model.dart';
import 'package:driverapp/models/fuel_report_model.dart';
import 'package:driverapp/models/delivery_report_model.dart';
import 'package:driverapp/services/auth_service.dart';

class ReportService {
  final String baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  // Helper method to get headers with authentication token
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<IncidentReport>> getIncidentReports(String driverId) async {
    final headers = await _getHeaders();
    
    final response = await http.get(
      Uri.parse('$baseUrl/IncidentReport?driverId=$driverId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        final reportsData = jsonData['data'] as List;
        return reportsData.map((data) => IncidentReport.fromJson(data)).toList();
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to get incident reports');
      }
    } else {
      throw Exception('Failed to load incident reports: ${response.statusCode}');
    }
  }

  Future<List<FuelReport>> getFuelReports(String? tripId, String? driverId) async {
    try {
      final uri = Uri.parse('$baseUrl/fuel-reports').replace(
        queryParameters: {
          if (tripId?.isNotEmpty ?? false) 'tripId': tripId,
          if (driverId?.isNotEmpty ?? false) 'driverId': driverId,
        },
      );

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 200 && jsonData['data'] != null) {
          final reportsData = jsonData['data'] as List;
          return reportsData.map((data) => FuelReport.fromJson(data)).toList();
        } else {
          throw Exception(jsonData['message'] ?? 'API error occurred');
        }
      } else {
        throw Exception('Failed to load fuel reports: Status ${response.statusCode}');
      }
    } catch (e) {
      throw e; // Re-throw the original exception
    }
  }

  Future<List<DeliveryReport>> getDeliveryReports(String? tripId, String? driverId) async {
    try {
      final uri = Uri.parse('$baseUrl/delivery-reports').replace(
        queryParameters: {
          if (tripId?.isNotEmpty ?? false) 'tripId': tripId,
          if (driverId?.isNotEmpty ?? false) 'driverId': driverId,
        },
      );

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 200 && jsonData['data'] != null) {
          final reportsData = jsonData['data'] as List;
          return reportsData.map((data) => DeliveryReport.fromJson(data)).toList();
        } else {
          throw Exception(jsonData['message'] ?? 'API error occurred');
        }
      } else {
        throw Exception('Failed to load delivery reports: Status ${response.statusCode}');
      }
    } catch (e) {
      throw e; // Re-throw the original exception
    }
  }
}
