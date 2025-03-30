import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/incident_report_model.dart';
import 'package:driverapp/models/fuel_report_model.dart';
import 'package:driverapp/models/delivery_report_model.dart';

class ReportService {
  final String baseUrl = 'https://mtcs-server.azurewebsites.net/api';

  Future<List<IncidentReport>> getIncidentReports(String driverId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/IncidentReport?driverId=$driverId'),
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

  Future<List<FuelReport>> getFuelReports(String? tripId, String? driverId) async {
  try {
    final uri = Uri.parse('$baseUrl/fuel-reports').replace(
      queryParameters: {
        if (tripId?.isNotEmpty ?? false) 'tripId': tripId,
        if (driverId?.isNotEmpty ?? false) 'driverId': driverId,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 200 && jsonData['data'] != null) {
        final reportsData = jsonData['data'] as List;
        return reportsData.map((data) => FuelReport.fromJson(data)).toList();
      } else {
        throw Exception('API error: ${jsonData['message'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('Failed to load fuel reports: Status ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching fuel reports: ${e.toString()}');
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

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 200 && jsonData['data'] != null) {
        final reportsData = jsonData['data'] as List;
        return reportsData.map((data) => DeliveryReport.fromJson(data)).toList();
      } else {
        throw Exception('API error: ${jsonData['message'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('Failed to load delivery reports: Status ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching delivery reports: ${e.toString()}');
  }
}

}
