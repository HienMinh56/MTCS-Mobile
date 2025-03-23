import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/delivery_report.dart';
import 'package:driverapp/utils/constants.dart';

class DeliveryReportService {
  Future<List<DeliveryReport>> getDeliveryReports(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/delivery-reports/get-delivery-reports?driverId=$driverId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 200 && 
            responseData['data'] != null && 
            responseData['data']['\$values'] != null) {
          
          List<dynamic> reportsJson = responseData['data']['\$values'];
          return reportsJson.map((json) => DeliveryReport.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load delivery reports');
      }
    } catch (e) {
      throw Exception('Error fetching delivery reports: $e');
    }
  }
}
