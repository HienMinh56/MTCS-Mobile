import 'package:intl/intl.dart';

class FuelReport {
  final String reportId;
  final String tripId;
  final double refuelAmount;
  final double fuelCost;
  final String location;
  final DateTime reportTime;
  final String reportBy;
  final List<FuelReportFile> files;

  FuelReport({
    required this.reportId,
    required this.tripId,
    required this.refuelAmount,
    required this.fuelCost,
    required this.location,
    required this.reportTime,
    required this.reportBy,
    required this.files,
  });

  factory FuelReport.fromJson(Map<String, dynamic> json) {
    List<FuelReportFile> files = [];
    if (json['fuelReportFiles'] != null && 
        json['fuelReportFiles'][r'$values'] != null) {
      files = (json['fuelReportFiles'][r'$values'] as List)
          .map((file) => FuelReportFile.fromJson(file))
          .toList();
    }

    return FuelReport(
      reportId: json['reportId'] ?? '',
      tripId: json['tripId'] ?? '',
      refuelAmount: json['refuelAmount']?.toDouble() ?? 0.0,
      fuelCost: json['fuelCost']?.toDouble() ?? 0.0,
      location: json['location'] ?? '',
      reportTime: json['reportTime'] != null 
          ? DateTime.parse(json['reportTime']) 
          : DateTime.now(),
      reportBy: json['reportBy'] ?? '',
      files: files,
    );
  }

  String getFormattedReportTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(reportTime);
  }

  String getFormattedRefuelAmount() {
    return '${refuelAmount.toStringAsFixed(2)} lít';
  }

  String getFormattedFuelCost() {
    final numberFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return numberFormat.format(fuelCost);
  }
}

class FuelReportFile {
  final String fileId;
  final String reportId;
  final String fileName;
  final String fileType;
  final DateTime uploadDate;
  final String uploadBy;
  final String? description;
  final String? note;
  final String fileUrl;

  FuelReportFile({
    required this.fileId,
    required this.reportId,
    required this.fileName,
    required this.fileType,
    required this.uploadDate,
    required this.uploadBy,
    this.description,
    this.note,
    required this.fileUrl,
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
      fileUrl: json['fileUrl'] ?? '',
    );
  }
}
