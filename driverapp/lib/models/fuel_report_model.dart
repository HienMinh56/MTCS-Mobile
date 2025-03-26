import 'package:intl/intl.dart';

class FuelReportFile {
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
  final String modifiedDate;
  final String modifiedBy;

  FuelReportFile({
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
    required this.modifiedDate,
    required this.modifiedBy,
  });

  factory FuelReportFile.fromJson(Map<String, dynamic> json) {
    return FuelReportFile(
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
      modifiedDate: json['modifiedDate'] ?? '',
      modifiedBy: json['modifiedBy'] ?? '',
    );
  }
}

class FuelReport {
  final String reportId;
  final String tripId;
  final double refuelAmount;
  final double fuelCost;
  final String location;
  final DateTime reportTime;
  final String reportBy;
  final String? licensePlate;
  final List<FuelReportFile> files; // Keep this as files for compatibility

  FuelReport({
    required this.reportId,
    required this.tripId,
    required this.refuelAmount,
    required this.fuelCost,
    required this.location,
    required this.reportTime,
    required this.reportBy,
    this.licensePlate,
    required this.files,
  });

  factory FuelReport.fromJson(Map<String, dynamic> json) {
    List<FuelReportFile> filesList = [];
    if (json['fuelReportFiles'] != null) {
      filesList = (json['fuelReportFiles'] as List)
          .map((fileJson) => FuelReportFile.fromJson(fileJson))
          .toList();
    }

    return FuelReport(
      reportId: json['reportId'] ?? '',
      tripId: json['tripId'] ?? '',
      refuelAmount: (json['refuelAmount'] ?? 0).toDouble(),
      fuelCost: (json['fuelCost'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      reportTime: json['reportTime'] != null 
          ? DateTime.parse(json['reportTime']) 
          : DateTime.now(),
      reportBy: json['reportBy'] ?? '',
      licensePlate: json['licensePlate'],
      files: filesList, // Map fuelReportFiles to files
    );
  }

  String getFormattedRefuelAmount() {
    return '$refuelAmount lít';
  }

  String getFormattedFuelCost() {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(fuelCost)} VND';
  }

  String getFormattedReportTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(reportTime);
  }
}
