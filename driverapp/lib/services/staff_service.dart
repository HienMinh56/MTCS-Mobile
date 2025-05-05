import 'package:driverapp/models/staff.dart';
import 'package:driverapp/utils/api_utils.dart';

class StaffService {
  /// Fetch the list of staff members from the API
  Future<List<Staff>> getStaffList() async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get('/api/Authen/staff')
        .timeout(const Duration(seconds: 15)),
      onSuccess: (responseData) {
        final staffResponse = StaffResponse.fromJson(responseData);
        
        if (staffResponse.status == 1) {
          return staffResponse.data;
        } else {
          throw Exception(staffResponse.message);
        }
      },
      defaultValue: <Staff>[],
      defaultErrorMessage: 'Không thể tải danh sách nhân viên'
    );
  }
}