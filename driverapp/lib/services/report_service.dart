import 'dart:convert';
import 'package:driverapp/models/incident_report_model.dart';
import 'package:driverapp/models/fuel_report_model.dart';
import 'package:driverapp/models/delivery_report_model.dart';
import 'package:driverapp/utils/api_utils.dart';

class ReportService {
  Future<List<IncidentReport>> getIncidentReports(String driverId) async {
    try {
      final response = await ApiUtils.get(
        '/api/IncidentReport',
        queryParams: {'driverId': driverId}
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
    } catch (e) {
      throw e; // Re-throw the original exception
    }
  }

  Future<List<FuelReport>> getFuelReports(String? tripId, String? driverId) async {
    try {
      // Prepare query parameters
      Map<String, String> queryParams = {};
      if (tripId?.isNotEmpty ?? false) queryParams['tripId'] = tripId!;
      if (driverId?.isNotEmpty ?? false) queryParams['driverId'] = driverId!;

      final response = await ApiUtils.get(
        '/api/fuel-reports',
        queryParams: queryParams
      ).timeout(const Duration(seconds: 15));

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
      // Prepare query parameters
      Map<String, String> queryParams = {};
      if (tripId?.isNotEmpty ?? false) queryParams['tripId'] = tripId!;
      if (driverId?.isNotEmpty ?? false) queryParams['driverId'] = driverId!;

      final response = await ApiUtils.get(
        '/api/delivery-reports',
        queryParams: queryParams
      ).timeout(const Duration(seconds: 15));

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
