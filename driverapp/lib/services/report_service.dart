import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/incident_report_model.dart';
import 'package:driverapp/models/fuel_report_model.dart';
import 'package:driverapp/models/delivery_report_model.dart';

class ReportService {
  final String baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  Future<List<IncidentReport>> getIncidentReports(String driverId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/IncidentReport/driver/$driverId'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        final reportsData = jsonData['data'] as List;
        return reportsData.map((data) => IncidentReport.fromJson(data)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load incident reports');
    }
  }

  Future<List<FuelReport>> getFuelReports(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fuel-reports?driverId=$driverId'),
      ).timeout(const Duration(seconds: 15)); // Add timeout

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 200 && jsonData['data'] != null) {
          final reportsData = jsonData['data'] as List;
          return reportsData.map((data) => FuelReport.fromJson(data)).toList();
        } else if (jsonData['status'] != 200) {
          throw Exception('API error: ${jsonData['message'] ?? 'Unknown error'}');
        }
        return [];
      } else {
        throw Exception('Failed to load fuel reports: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching fuel reports: ${e.toString()}');
    }
  }

  Future<List<DeliveryReport>> getDeliveryReports(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/delivery-reports?driverId=$driverId'),
      ).timeout(const Duration(seconds: 15)); // Add timeout

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 200 && jsonData['data'] != null) {
          final reportsData = jsonData['data'] as List;
          return reportsData.map((data) => DeliveryReport.fromJson(data)).toList();
        } else if (jsonData['status'] != 200) {
          throw Exception('API error: ${jsonData['message'] ?? 'Unknown error'}');
        }
        return [];
      } else {
        throw Exception('Failed to load delivery reports: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching delivery reports: ${e.toString()}');
    }
  }
}
