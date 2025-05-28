import 'package:intl/intl.dart';

class ExpenseReportFile {
  final String fileId;
  final String reportId;
  final String fileName;
  final String fileType;
  final DateTime uploadDate;
  final String uploadBy;
  final String? description;
  final String? note;
  final String? deletedDate;
  final String? deletedBy;
  final String fileUrl;
  final String? modifiedDate;
  final String? modifiedBy;
  final dynamic report;  // Keeping this as dynamic as per API response

  ExpenseReportFile({
    required this.fileId,
    required this.reportId,
    required this.fileName,
    required this.fileType,
    required this.uploadDate,
    required this.uploadBy,
    this.description,
    this.note,
    this.deletedDate,
    this.deletedBy,
    required this.fileUrl,
    this.modifiedDate,
    this.modifiedBy,
    this.report,
  });

  factory ExpenseReportFile.fromJson(Map<String, dynamic> json) {
    return ExpenseReportFile(
      fileId: json['fileId'] ?? '',
      reportId: json['reportId'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      uploadDate: json['uploadDate'] != null 
          ? DateTime.parse(json['uploadDate']) 
          : DateTime.now(),
      uploadBy: json['uploadBy'] ?? '',
      description: json['description'],
      note: json['note'],
      deletedDate: json['deletedDate'],
      deletedBy: json['deletedBy'],
      fileUrl: json['fileUrl'] ?? '',
      modifiedDate: json['modifiedDate'],
      modifiedBy: json['modifiedBy'],
      report: json['report'],
    );
  }
}

class ExpenseReport {
  final String reportId;
  final String tripId;
  final String reportTypeId;
  final double cost;
  final String location;
  final DateTime reportTime;
  final String reportBy;
  final int isPay;  // 0 or 1
  final String? description;
  final List<ExpenseReportFile> files;
  final dynamic reportType;  // Keeping this as dynamic as per API response
  final dynamic trip;  // Keeping this as dynamic as per API response

  ExpenseReport({
    required this.reportId,
    required this.tripId,
    required this.reportTypeId,
    required this.cost,
    required this.location,
    required this.reportTime,
    required this.reportBy,
    required this.isPay,
    this.description,
    required this.files,
    this.reportType,
    this.trip,
  });

  factory ExpenseReport.fromJson(Map<String, dynamic> json) {
    List<ExpenseReportFile> filesList = [];
    if (json['expenseReportFiles'] != null) {
      filesList = (json['expenseReportFiles'] as List)
          .map((fileJson) => ExpenseReportFile.fromJson(fileJson))
          .toList();
    }

    return ExpenseReport(
      reportId: json['reportId'] ?? '',
      tripId: json['tripId'] ?? '',
      reportTypeId: json['reportTypeId'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      reportTime: json['reportTime'] != null 
          ? DateTime.parse(json['reportTime']) 
          : DateTime.now(),
      reportBy: json['reportBy'] ?? '',
      isPay: json['isPay'] ?? 0,
      description: json['description'],
      files: filesList,
      reportType: json['reportType'],
      trip: json['trip'],
    );
  }

  String getFormattedCost() {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(cost);
  }

  String getFormattedReportTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(reportTime);
  }
  String getReportTypeName() {
    // First try to get the name from the reportType object if available
    if (reportType != null && reportType is Map<String, dynamic>) {
      final reportTypeMap = reportType as Map<String, dynamic>;
      if (reportTypeMap.containsKey('reportType')) {
        return reportTypeMap['reportType'] ?? 'Chi phí không xác định';
      }
    }
    
    // Fallback to hardcoded values if reportType object is not available
    switch (reportTypeId) {
      case 'toll':
        return 'Phí cầu đường';
      case 'parking':
        return 'Phí đỗ xe';
      case 'meal':
        return 'Chi phí ăn uống';
      case 'accommodation':
        return 'Chi phí nghỉ ngơi';
      case 'other':
        return 'Chi phí khác';
      default:
        return 'Chi phí không xác định';
    }
  }
}