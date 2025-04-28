import 'dart:convert';
import 'dart:io';
import 'package:driverapp/utils/api_utils.dart';

class FuelReportService {
  static const String _endpoint = '/api/fuel-reports';


  
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
      // Prepare fields for multipart request
      Map<String, String> fields = {
        'TripId': tripId,
        'RefuelAmount': refuelAmount.toString(),
        'FuelCost': fuelCost.toString(),
        'Location': location,
      };
      
      // Prepare files for multipart request
      Map<String, List<File>> files = {
        'files': images,
      };
      
      // Use the ApiUtils to make the request
      var streamedResponse = await ApiUtils.multipartPost(_endpoint, fields, files);
      var response = await ApiUtils.streamedResponseToResponse(streamedResponse);
      var jsonData = jsonDecode(response.body);
      
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
      final response = await ApiUtils.get(_endpoint, queryParams: {'tripId': tripId});
      
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
      
      // Prepare fields for multipart request
      Map<String, String> fields = {
        'ReportId': reportId,
        'RefuelAmount': refuelAmount.toString(),
        'FuelCost': fuelCost.toString(),
        'Location': location,
      };
      
      // Add file IDs to remove - each as a separate field with the same name
      for (int i = 0; i < fileIdsToRemove.length; i++) {
        fields['FileIdsToRemove[$i]'] = fileIdsToRemove[i];
      }
      
      // Prepare files for multipart request
      Map<String, List<File>> files = {
        'AddedFiles': addedFiles,
      };
      
      // Use the ApiUtils to make the request
      var streamedResponse = await ApiUtils.multipartPut(_endpoint, fields, files);
      var response = await ApiUtils.streamedResponseToResponse(streamedResponse);
      
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
