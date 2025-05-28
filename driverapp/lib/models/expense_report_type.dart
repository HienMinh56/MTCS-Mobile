class ExpenseReportType {
  final String reportTypeId;
  final String reportType;
  final int isActive;

  ExpenseReportType({
    required this.reportTypeId,
    required this.reportType,
    required this.isActive,
  });

  factory ExpenseReportType.fromJson(Map<String, dynamic> json) {
    return ExpenseReportType(
      reportTypeId: json['reportTypeId'] as String,
      reportType: json['reportType'] as String,
      isActive: json['isActive'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportTypeId': reportTypeId,
      'reportType': reportType,
      'isActive': isActive,
    };
  }
}
