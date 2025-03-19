class DriverProfile {
  final String driverId;
  final String fullName;
  final String email;
  final String? dateOfBirth;
  final String phoneNumber;
  final int status;
  final String createdDate;
  final String? createdBy;
  final String? modifiedDate;
  final String? modifiedBy;
  final int totalWorkingTime;
  final int currentWeekWorkingTime;
  final List<String> fileUrls;

  DriverProfile({
    required this.driverId,
    required this.fullName,
    required this.email,
    this.dateOfBirth,
    required this.phoneNumber,
    required this.status,
    required this.createdDate,
    this.createdBy,
    this.modifiedDate,
    this.modifiedBy,
    required this.totalWorkingTime,
    required this.currentWeekWorkingTime,
    required this.fileUrls,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      driverId: json['driverId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      phoneNumber: json['phoneNumber'] ?? '',
      status: json['status'] ?? 0,
      createdDate: json['createdDate'] ?? '',
      createdBy: json['createdBy'],
      modifiedDate: json['modifiedDate'],
      modifiedBy: json['modifiedBy'],
      totalWorkingTime: json['totalWorkingTime'] ?? 0,
      currentWeekWorkingTime: json['currentWeekWorkingTime'] ?? 0,
      fileUrls: List<String>.from(json['fileUrls'] ?? []),
    );
  }
}

class DriverProfileResponse {
  final bool success;
  final DriverProfile? data;
  final String message;
  final List<String>? errors;

  DriverProfileResponse({
    required this.success,
    this.data,
    required this.message,
    this.errors,
  });

  factory DriverProfileResponse.fromJson(Map<String, dynamic> json) {
    return DriverProfileResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? DriverProfile.fromJson(json['data']) : null,
      message: json['message'] ?? '',
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }
}
