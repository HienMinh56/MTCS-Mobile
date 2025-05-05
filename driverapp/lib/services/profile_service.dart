import 'dart:io';
import 'package:driverapp/models/driver_profile.dart';
import 'package:driverapp/utils/api_utils.dart';

class ProfileService {
  Future<DriverProfile> getDriverProfile(String driverId, {bool loadFiles = true}) async {
    // Always load files by default now since the API returns them anyway
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/Driver/profile',
        queryParams: {'driverId': driverId}
      ).timeout(const Duration(seconds: 15)),
      onSuccess: (responseData) {
        final profileResponse = DriverProfileResponse.fromJson(responseData);
        
        if (profileResponse.success && profileResponse.data != null) {
          return profileResponse.data!;
        } else {
          throw Exception(profileResponse.messageVN ?? profileResponse.message);
        }
      },
      defaultValue: DriverProfile(
        driverId: driverId,
        fullName: 'Unknown Driver',
        email: '',
        phoneNumber: '',
        status: 0,
        totalOrder: 0,
      ),
      defaultErrorMessage: 'Không thể tải thông tin tài xế'
    );
  }

  Future<String> getDriverName(String driverId) async {
    try {
      final profile = await getDriverProfile(driverId);
      return profile.fullName;
    } catch (e) {
      return 'Unknown Driver';
    }
  }

  // Get driver avatar image or CCCD front image if available
  Future<String?> getDriverImage(String driverId) async {
    try {
      final profile = await getDriverProfile(driverId);
      if (profile.files.isNotEmpty) {
        // First try to find avatar image
        final avatarImage = profile.files.firstWhere(
          (file) => file.description.toLowerCase().contains('avatar') || 
                   file.description.toLowerCase().contains('profile'),
          orElse: () => profile.files.firstWhere(
            (file) => file.description == 'CCCD_Front',
            orElse: () => profile.files.isNotEmpty ? profile.files.first : 
              DriverFile(
                fileId: '',
                fileName: '',
                fileUrl: '',
                fileType: '',
                description: '',
                uploadDate: '',
                uploadBy: '',
              ),
          ),
        );
        
        return avatarImage.fileUrl.isNotEmpty ? avatarImage.fileUrl : null;
      }
      return null;
    } catch (e) {
      print('❌ Lỗi khi lấy hình ảnh tài xế: $e');
      return null;
    }
  }

  // Get file from driver profile by description
  Future<DriverFile?> getFileByDescription(String driverId, String description) async {
    try {
      final profile = await getDriverProfile(driverId);
      final file = profile.files.firstWhere(
        (file) => file.description == description,
        orElse: () => DriverFile(
          fileId: '',
          fileName: '',
          fileUrl: '',
          fileType: '',
          description: '',
          uploadDate: '',
          uploadBy: '',
        ),
      );
      
      return file.fileUrl.isNotEmpty ? file : null;
    } catch (e) {
      print('❌ Lỗi khi lấy file: $e');
      return null;
    }
  }

  // Get all files for a driver
  Future<List<DriverFile>> getDriverFiles(String driverId) async {
    try {
      final profile = await getDriverProfile(driverId);
      return profile.files;
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách file: $e');
      return [];
    }
  }

  Future<DriverProfile> updateDriverProfile(
    String driverId, 
    String fullName, 
    String email, 
    String phoneNumber, 
    String? dateOfBirth,
    {String? password}
  ) async {
    // Create fields map for multipart request
    Map<String, String> fields = {
      'FullName': fullName,
      'Email': email,
      'PhoneNumber': phoneNumber,
    };
    
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
      fields['DateOfBirth'] = dateOfBirth;
    }
    
    if (password != null && password.isNotEmpty) {
      fields['Password'] = password;
    }
    
    return ApiUtils.safeApiCall(
      apiCall: () async {
        final streamedResponse = await ApiUtils.multipartPut(
          '/api/Driver/$driverId',
          fields,
          null // No files to upload
        );
        
        return await ApiUtils.streamedResponseToResponse(streamedResponse);
      },
      onSuccess: (jsonResponse) {
        if (jsonResponse['success'] == true) {
          return DriverProfile.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['messageVN'] ?? jsonResponse['message'] ?? 'Lỗi khi cập nhật thông tin');
        }
      },
      defaultValue: DriverProfile(
        driverId: driverId,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        status: 0,
        totalOrder: 0,
      ),
      defaultErrorMessage: 'Không thể cập nhật hồ sơ'
    );
  }
  
  /// Upload ID card (CCCD) images
  Future<Map<String, dynamic>> uploadIDCardImages({
    required String driverId,
    required List<File> files,
  }) async {
    if (files.isEmpty) {
      return {
        'success': false,
        'message': 'Không có tệp nào để tải lên',
      };
    }
    
    return ApiUtils.safeApiCall(
      apiCall: () async {
        // Create a multipart request
        final streamedResponse = await ApiUtils.multipartPost(
          '/api/Driver/$driverId/files', 
          {}, // No additional fields needed
          {
            'files': files,  // Now this is correctly typed as List<File>
          }
        );
        
        return await ApiUtils.streamedResponseToResponse(streamedResponse);
      },
      onSuccess: (data) {
        return {
          'success': data['success'] ?? false,
          'message': data['messageVN'] ?? data['message'] ?? 'Tải lên thành công',
          'data': data['data'],
        };
      },
      defaultValue: {
        'success': false,
        'message': 'Không thể tải lên tệp',
        'data': null,
      },
      defaultErrorMessage: 'Lỗi khi tải lên giấy tờ cá nhân'
    );
  }
}
