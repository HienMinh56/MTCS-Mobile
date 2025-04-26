class Staff {
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final int role;
  final String gender;
  final String birthday;
  final int status;

  Staff({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.gender,
    required this.birthday,
    required this.status,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 0,
      gender: json['gender'] ?? '',
      birthday: json['birthday'] ?? '',
      status: json['status'] ?? 0,
    );
  }
}

class StaffResponse {
  final int status;
  final String message;
  final List<Staff> data;

  StaffResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory StaffResponse.fromJson(Map<String, dynamic> json) {
    return StaffResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List).map((item) => Staff.fromJson(item)).toList()
          : [],
    );
  }
}