import 'dart:convert';
import 'dart:io';
import 'package:driverapp/utils/api_utils.dart';

class IncidentReportResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  IncidentReportResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

class IncidentReportService {
  /// Submits an incident report with optional images
  Future<IncidentReportResponse> submitIncidentReport({
    required String tripId,
    required String incidentType,
    required String description,
    required String location,
    required int type, // 1 = On Site, 2 = Change Vehicle
    required int vehicleType, // 1 = Head, 2 = Trailer
    required String status, // 'Resolved' or 'Unresolved'
    String? resolutionDetails,
    List<File> images = const [],
  }) async {
    try {
      // Create map of fields for multipart request
      Map<String, String> fields = {
        'TripId': tripId,
        'IncidentType': incidentType,
        'Description': description,
        'Location': location,
        'Type': type.toString(),
        'VehicleType': vehicleType.toString(),
        'Status': "Handling",
      };
      
      // Add resolution details if provided
      if (resolutionDetails != null && resolutionDetails.isNotEmpty) {
        fields['ResolutionDetails'] = resolutionDetails;
      }
      
      // Add images
      Map<String, List<File>> files = {};
      if (images.isNotEmpty) {
        files['Image'] = images;
      }
      
      // Send the request using ApiUtils
      var streamedResponse = await ApiUtils.multipartPost(
        '/api/IncidentReport/IncidentImage',
        fields,
        files
      );
      
      // Convert streamedResponse to Response
      var response = await ApiUtils.streamedResponseToResponse(streamedResponse);
      var responseBody = response.body;
      Map<String, dynamic> jsonResponse;
      
      try {
        jsonResponse = json.decode(responseBody);
      } catch (e) {
        return IncidentReportResponse(
          success: false,
          message: 'Response parsing error: $responseBody',
        );
      }
      
      // Return the response directly from server
      return IncidentReportResponse(
        success: response.statusCode == 200 && jsonResponse['status'] == 1,
        message: jsonResponse['message'] ?? 'Unknown server response',
        data: jsonResponse['data'],
      );
    } on SocketException {
      return IncidentReportResponse(
        success: false,
        message: 'Network connection error',
      );
    } catch (e) {
      return IncidentReportResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> getIncidentReportsByTripId(String tripId) async {
    try {
      final response = await ApiUtils.get(
        '/api/IncidentReport',
        queryParams: {'tripId': tripId}
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Error: HTTP ${response.statusCode}', 'data': []};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Error: $e', 'data': []};
    }
  }

  
  /// Uploads billing images for an incident report
  Future<Map<String, dynamic>> uploadBillingImages({
    required String reportId,
    required List<File> images,
  }) async {
    try {
      // Create fields and files maps
      Map<String, String> fields = {
        'ReportId': reportId,
      };
      
      Map<String, List<File>> files = {
        'Image': images,
      };
      
      // Send the request using ApiUtils
      var streamedResponse = await ApiUtils.multipartPost(
        '/api/IncidentReport/BillImage',
        fields,
        files
      );
      
      // Convert to regular response and parse
      var response = await ApiUtils.streamedResponseToResponse(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error uploading billing images: ${response.body}');
        return {
          'status': response.statusCode,
          'message': 'Error uploading billing images: ${response.body}',
        };
      }
    } catch (e) {
      print('Exception during billing image upload: $e');
      return {
        'status': 500,
        'message': 'Exception during billing image upload: $e',
      };
    }
  }
  
  /// Uploads exchange/resolution images for an incident report
  Future<Map<String, dynamic>> uploadExchangeImages({
    required String reportId,
    required List<File> images,
  }) async {
    try {
      // Create fields and files maps
      Map<String, String> fields = {
        'ReportId': reportId,
      };
      
      Map<String, List<File>> files = {
        'Image': images,
      };
      
      // Send the request using ApiUtils
      var streamedResponse = await ApiUtils.multipartPost(
        '/api/IncidentReport/ExchangeImage',
        fields,
        files
      );
      
      // Convert to regular response and parse
      var response = await ApiUtils.streamedResponseToResponse(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error uploading exchange images: ${response.body}');
        return {
          'status': response.statusCode,
          'message': 'Error uploading exchange images: ${response.body}',
        };
      }
    } catch (e) {
      print('Exception during exchange image upload: $e');
      return {
        'status': 500,
        'message': 'Exception during exchange image upload: $e',
      };
    }
  }

  /// Resolve an incident report (with optional resolution images)
  Future<Map<String, dynamic>> resolveIncidentReport({
    required String reportId,
    String? resolutionDetails,
    List<File>? resolutionImages,
  }) async {
    try {
      // First upload resolution images if available
      if (resolutionImages != null && resolutionImages.isNotEmpty) {
        await uploadExchangeImages(
          reportId: reportId,
          images: resolutionImages,
        );
      }
      
      // Create request body with reportId and optional resolutionDetails
      final Map<String, dynamic> requestBody = {
        'reportId': reportId,
      };
      
      // Add resolution details if provided
      if (resolutionDetails != null && resolutionDetails.isNotEmpty) {
        requestBody['resolutionDetails'] = resolutionDetails;
      }
      
      // Make the PATCH request using ApiUtils
      final response = await ApiUtils.patch(
        '/api/IncidentReport',
        requestBody
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        print('Failed to resolve incident report: ${response.body}');
        return {
          'status': 0,
          'message': 'Failed to resolve incident report. Status code: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      print('Exception during incident resolution: $e');
      return {
        'status': 0,
        'message': 'Error: $e',
        'data': null,
      };
    }
  }

  // Add method to update an existing incident report
  Future<Map<String, dynamic>> updateIncidentReport({
    required String reportId,
    String? incidentType,
    int? vehicleType,
    String? description,
    String? location,
    int? type,
    List<String>? fileIdsToRemove, // These are actually file URLs, not IDs
    List<File>? addedFiles,
  }) async {
    try {
      // Create fields map
      Map<String, String> fields = {
        'ReportId': reportId,
      };
      
      // Add optional fields if provided
      if (incidentType != null) fields['IncidentType'] = incidentType;
      if (description != null) fields['Description'] = description;
      if (location != null) fields['Location'] = location;
      if (vehicleType != null) fields['VehicleType'] = vehicleType.toString();
      if (type != null) fields['Type'] = type.toString();
      
      // Add file URLs to remove - use indexed format for multiple files
      if (fileIdsToRemove != null && fileIdsToRemove.isNotEmpty) {
        for (int i = 0; i < fileIdsToRemove.length; i++) {
          // Use indexed field names with URLs for each image to remove
          fields['RemovedImage[$i]'] = fileIdsToRemove[i];
        }
        
        // Debug info
        print('Removing ${fileIdsToRemove.length} image(s): $fileIdsToRemove');
      }
      
      // Prepare files map
      Map<String, List<File>>? files;
      if (addedFiles != null && addedFiles.isNotEmpty) {
        files = {
          'AddedImage': addedFiles,
        };
      }
      
      // Use ApiUtils to make the request
      var streamedResponse = await ApiUtils.multipartPut(
        '/api/IncidentReport/mo',
        fields,
        files
      );
      
      var response = await ApiUtils.streamedResponseToResponse(streamedResponse);
      
      // Debug info
      print('Update response: ${response.statusCode}, body: ${response.body}');
      
      // Parse and return the response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'status': 0,
          'message': 'Error: ${response.statusCode} ${response.reasonPhrase}',
          'data': null
        };
      }
    } catch (e) {
      print('Exception in updateIncidentReport: $e');
      return {
        'status': 0,
        'message': 'Exception: $e',
        'data': null
      };
    }
  }
}