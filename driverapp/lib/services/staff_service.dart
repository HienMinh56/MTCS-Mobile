import 'dart:convert';
import 'package:driverapp/models/staff.dart';
import 'package:driverapp/utils/api_utils.dart';

class StaffService {
  /// Fetch the list of staff members from the API
  Future<List<Staff>> getStaffList() async {
    try {      
      final response = await ApiUtils.get('/api/Authen/staff')
        .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final staffResponse = StaffResponse.fromJson(responseData);
        
        if (staffResponse.status == 1) {
          return staffResponse.data;
        } else {
          throw Exception(staffResponse.message);
        }
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      throw e;
    }
  }
}