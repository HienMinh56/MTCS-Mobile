class DriverProfile {
  final String driverId;
  final String fullName;
  final String email;
  final String? dateOfBirth;
  final String phoneNumber;
  final int status;
  final String createdDate;
  final int totalWorkingTime;
  final int currentWeekWorkingTime;
  final int totalOrder;
  final List<String> fileUrls;

  DriverProfile({
    required this.driverId,
    required this.fullName,
    required this.email,
    this.dateOfBirth,
    required this.phoneNumber,
    required this.status,
    required this.createdDate,
    this.totalWorkingTime = 0,
    this.currentWeekWorkingTime = 0,
    this.totalOrder = 0,
    required this.fileUrls,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    // Handle the fileUrls special structure with $values
    List<String> extractedFileUrls = [];
    if (json['fileUrls'] != null) {
      if (json['fileUrls'] is Map && json['fileUrls'].containsKey('\$values')) {
        final values = json['fileUrls']['\$values'];
        if (values is List) {
          extractedFileUrls = List<String>.from(values.map((url) => url.toString()));
        }
      } else if (json['fileUrls'] is List) {
        extractedFileUrls = List<String>.from(json['fileUrls'].map((url) => url.toString()));
      }
    }

    return DriverProfile(
      driverId: json['driverId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      phoneNumber: json['phoneNumber'] ?? '',
      status: json['status'] ?? 0,
      createdDate: json['createdDate'] ?? '',
      totalWorkingTime: json['totalWorkingTime'] ?? 0,
      currentWeekWorkingTime: json['currentWeekWorkingTime'] ?? 0,
      totalOrder: json['totalOrder'] ?? 0,
      fileUrls: extractedFileUrls,
    );
  }
}

class DriverProfileResponse {
  final bool success;
  final DriverProfile? data;
  final String message;
  final dynamic errors;

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
      errors: json['errors'],
    );
  }
}
