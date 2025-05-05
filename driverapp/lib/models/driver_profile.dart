class DriverFile {
  final String fileId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final String description;
  final String? note;
  final String uploadDate;
  final String uploadBy;

  DriverFile({
    required this.fileId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.description,
    this.note,
    required this.uploadDate,
    required this.uploadBy,
  });

  factory DriverFile.fromJson(Map<String, dynamic> json) {
    return DriverFile(
      fileId: json['fileId'] ?? '',
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? '',
      description: json['description'] ?? '',
      note: json['note'],
      uploadDate: json['uploadDate'] ?? '',
      uploadBy: json['uploadBy'] ?? '',
    );
  }
}

class DriverProfile {
  final String driverId;
  final String fullName;
  final String email;
  final String? dateOfBirth;
  final String phoneNumber;
  final int status;
  final String? createdDate;
  final String? createdBy;
  final String? modifiedDate;
  final String? modifiedBy;
  final String? dailyWorkingTime;
  final String? currentWeekWorkingTime;
  final int totalOrder;
  final List<DriverFile> files;

  DriverProfile({
    required this.driverId,
    required this.fullName,
    required this.email,
    this.dateOfBirth,
    required this.phoneNumber,
    required this.status,
    this.createdDate,
    this.createdBy,
    this.modifiedDate,
    this.modifiedBy,
    this.dailyWorkingTime,
    this.currentWeekWorkingTime,
    this.totalOrder = 0,
    this.files = const [],
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    // Extract files array from json response
    List<DriverFile> filesList = [];
    if (json['files'] != null && json['files'] is List) {
      filesList = (json['files'] as List)
          .map((fileJson) => DriverFile.fromJson(fileJson))
          .toList();
    }

    return DriverProfile(
      driverId: json['driverId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      phoneNumber: json['phoneNumber'] ?? '',
      status: json['status'] is int ? json['status'] : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      createdDate: json['createdDate'],
      createdBy: json['createdBy'],
      modifiedDate: json['modifiedDate'],
      modifiedBy: json['modifiedBy'],
      dailyWorkingTime: json['dailyWorkingTime'],
      currentWeekWorkingTime: json['currentWeekWorkingTime'],
      totalOrder: json['totalOrder'] is int 
          ? json['totalOrder'] 
          : int.tryParse(json['totalOrder']?.toString() ?? '0') ?? 0,
      files: filesList,
    );
  }

  // Helper method to get ID card front image if available
  String? getIDCardFrontImage() {
    final frontCard = files.firstWhere(
      (file) => file.description == 'CCCD_Front',
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
    
    return frontCard.fileUrl.isNotEmpty ? frontCard.fileUrl : null;
  }
}

class DriverProfileResponse {
  final bool success;
  final DriverProfile? data;
  final String message;
  final String? messageVN;
  final dynamic errors;

  DriverProfileResponse({
    required this.success,
    this.data,
    required this.message,
    this.messageVN,
    this.errors,
  });

  factory DriverProfileResponse.fromJson(Map<String, dynamic> json) {
    return DriverProfileResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? DriverProfile.fromJson(json['data']) : null,
      message: json['message'] ?? '',
      messageVN: json['messageVN'],
      errors: json['errors'],
    );
  }
}
