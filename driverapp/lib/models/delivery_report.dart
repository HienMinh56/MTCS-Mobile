class DeliveryReportFile {
  final String fileId;
  final String fileName;
  final String fileType;
  final DateTime uploadDate;
  final String fileUrl;
  final String description;

  DeliveryReportFile({
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.uploadDate,
    required this.fileUrl,
    required this.description,
  });

  factory DeliveryReportFile.fromJson(Map<String, dynamic> json) {
    return DeliveryReportFile(
      fileId: json['fileId'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      uploadDate: json['uploadDate'] != null 
          ? DateTime.parse(json['uploadDate']) 
          : DateTime.now(),
      fileUrl: json['fileUrl'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class DeliveryReport {
  final String reportId;
  final String tripId;
  final String notes;
  final DateTime reportTime;
  final String reportBy;
  final List<DeliveryReportFile> files;

  DeliveryReport({
    required this.reportId,
    required this.tripId,
    required this.notes,
    required this.reportTime,
    required this.reportBy,
    required this.files,
  });

  factory DeliveryReport.fromJson(Map<String, dynamic> json) {
    List<DeliveryReportFile> files = [];
    if (json['deliveryReportsFiles'] != null && 
        json['deliveryReportsFiles']['\$values'] != null) {
      files = List<DeliveryReportFile>.from(
        json['deliveryReportsFiles']['\$values'].map(
          (fileJson) => DeliveryReportFile.fromJson(fileJson)
        )
      );
    }

    return DeliveryReport(
      reportId: json['reportId'] ?? '',
      tripId: json['tripId'] ?? '',
      notes: json['notes'] ?? '',
      reportTime: json['reportTime'] != null 
          ? DateTime.parse(json['reportTime']) 
          : DateTime.now(),
      reportBy: json['reportBy'] ?? '',
      files: files,
    );
  }

  String get formattedDate {
    return '${reportTime.day}/${reportTime.month}/${reportTime.year} ${reportTime.hour}:${reportTime.minute.toString().padLeft(2, '0')}';
  }
}
