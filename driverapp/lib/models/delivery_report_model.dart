
class DeliveryReport {
  final String reportId;
  final String tripId;
  final String notes;
  final String reportTime;
  final String reportBy;
  final List<DeliveryReportFile> deliveryReportsFiles;

  DeliveryReport({
    required this.reportId,
    required this.tripId,
    required this.notes,
    required this.reportTime,
    required this.reportBy,
    required this.deliveryReportsFiles,
  });

  factory DeliveryReport.fromJson(Map<String, dynamic> json) {
    return DeliveryReport(
      reportId: json['reportId'] ?? '',
      tripId: json['tripId'] ?? '',
      notes: json['notes'] ?? '',
      reportTime: json['reportTime'] ?? '',
      reportBy: json['reportBy'] ?? '',
      deliveryReportsFiles: json['deliveryReportsFiles'] != null
          ? List<DeliveryReportFile>.from(
              json['deliveryReportsFiles'].map(
                (file) => DeliveryReportFile.fromJson(file),
              ),
            )
          : [],
    );
  }
}

class DeliveryReportFile {
  final String fileId;
  final String reportId;
  final String fileName;
  final String fileType;
  final String uploadDate;
  final String uploadBy;
  final String description;
  final String note;
  final String? deletedDate;
  final String? deletedBy;
  final String fileUrl;
  final String modifiedDate;
  final String modifiedBy;

  DeliveryReportFile({
    required this.fileId,
    required this.reportId,
    required this.fileName,
    required this.fileType,
    required this.uploadDate,
    required this.uploadBy,
    required this.description,
    required this.note,
    this.deletedDate,
    this.deletedBy,
    required this.fileUrl,
    required this.modifiedDate,
    required this.modifiedBy,
  });

  factory DeliveryReportFile.fromJson(Map<String, dynamic> json) {
    return DeliveryReportFile(
      fileId: json['fileId'] ?? '',
      reportId: json['reportId'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      uploadDate: json['uploadDate'] ?? '',
      uploadBy: json['uploadBy'] ?? '',
      description: json['description'] ?? '',
      note: json['note'] ?? '',
      deletedDate: json['deletedDate'],
      deletedBy: json['deletedBy'],
      fileUrl: json['fileUrl'] ?? '',
      modifiedDate: json['modifiedDate'] ?? '',
      modifiedBy: json['modifiedBy'] ?? '',
    );
  }
}
