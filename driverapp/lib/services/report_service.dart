import 'package:driverapp/models/incident_report_model.dart';
import 'package:driverapp/models/fuel_report_model.dart';
import 'package:driverapp/models/delivery_report_model.dart';
import 'package:driverapp/utils/api_utils.dart';

class ReportService {
  Future<List<IncidentReport>> getIncidentReports(String driverId) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/IncidentReport',
        queryParams: {'driverId': driverId}
      ),
      onSuccess: (jsonData) {
        if (jsonData['data'] != null) {
          final reportsData = jsonData['data'] as List;
          return reportsData.map((data) => IncidentReport.fromJson(data)).toList();
        } else {
          return <IncidentReport>[];
        }
      },
      defaultValue: <IncidentReport>[],
      defaultErrorMessage: 'Không thể tải báo cáo sự cố'
    );
  }

  Future<List<FuelReport>> getFuelReports(String? tripId, String? driverId) async {
    // Prepare query parameters
    Map<String, String> queryParams = {};
    if (tripId?.isNotEmpty ?? false) queryParams['tripId'] = tripId!;
    if (driverId?.isNotEmpty ?? false) queryParams['driverId'] = driverId!;

    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/fuel-reports',
        queryParams: queryParams
      ).timeout(const Duration(seconds: 15)),
      onSuccess: (jsonData) {
        if (jsonData['data'] != null) {
          final reportsData = jsonData['data'] as List;
          return reportsData.map((data) => FuelReport.fromJson(data)).toList();
        } else {
          return <FuelReport>[];
        }
      },
      defaultValue: <FuelReport>[],
      defaultErrorMessage: 'Không thể tải báo cáo nhiên liệu'
    );
  }

  Future<List<DeliveryReport>> getDeliveryReports(String? tripId, String? driverId) async {
    // Prepare query parameters
    Map<String, String> queryParams = {};
    if (tripId?.isNotEmpty ?? false) queryParams['tripId'] = tripId!;
    if (driverId?.isNotEmpty ?? false) queryParams['driverId'] = driverId!;

    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/delivery-reports',
        queryParams: queryParams
      ).timeout(const Duration(seconds: 15)),
      onSuccess: (jsonData) {
        if (jsonData['data'] != null) {
          final reportsData = jsonData['data'] as List;
          return reportsData.map((data) => DeliveryReport.fromJson(data)).toList();
        } else {
          return <DeliveryReport>[];
        }
      },
      defaultValue: <DeliveryReport>[],
      defaultErrorMessage: 'Không thể tải báo cáo giao hàng'
    );
  }
}
