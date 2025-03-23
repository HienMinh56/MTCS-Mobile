import 'package:intl/intl.dart';

class IncidentReport {
  final String reportId;
  final String tripId;
  final String reportedBy;
  final String incidentType;
  final String description;
  final DateTime incidentTime;
  final String location;
  final int type;
  final String status;
  final String? resolutionDetails;
  final String? handledBy;
  final DateTime? handledTime;
  final DateTime createdDate;
  final List<IncidentReportFile> files;

  IncidentReport({
    required this.reportId,
    required this.tripId,
    required this.reportedBy,
    required this.incidentType,
    required this.description,
    required this.incidentTime,
    required this.location,
    required this.type,
    required this.status,
    this.resolutionDetails,
    this.handledBy,
    this.handledTime,
    required this.createdDate,
    required this.files,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    List<IncidentReportFile> files = [];
    if (json['incidentReportsFiles'] != null && 
        json['incidentReportsFiles'][r'$values'] != null) {
      files = (json['incidentReportsFiles'][r'$values'] as List)
          .map((file) => IncidentReportFile.fromJson(file))
          .toList();
    }

    return IncidentReport(
      reportId: json['reportId'] ?? '',
      tripId: json['tripId'] ?? '',
      reportedBy: json['reportedBy'] ?? '',
      incidentType: json['incidentType'] ?? '',
      description: json['description'] ?? '',
      incidentTime: json['incidentTime'] != null 
          ? DateTime.parse(json['incidentTime']) 
          : DateTime.now(),
      location: json['location'] ?? '',
      type: json['type'] ?? 0,
      status: json['status'] ?? '',
      resolutionDetails: json['resolutionDetails'],
      handledBy: json['handledBy'],
      handledTime: json['handledTime'] != null 
          ? DateTime.parse(json['handledTime']) 
          : null,
      createdDate: json['createdDate'] != null 
          ? DateTime.parse(json['createdDate']) 
          : DateTime.now(),
      files: files,
    );
  }

  String getFormattedIncidentTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(incidentTime);
  }

  String getFormattedCreatedDate() {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdDate);
  }

  String getTypeText() {
    switch (type) {
      case 1:
        return 'Nhẹ';
      case 2:
        return 'Nghiêm trọng';
      default:
        return 'Không xác định';
    }
  }
}

class IncidentReportFile {
  final String fileId;
  final String reportId;
  final String fileName;
  final String fileType;
  final DateTime uploadDate;
  final String uploadBy;
  final String? description;
  final String? note;
  final String fileUrl;

  IncidentReportFile({
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

  factory IncidentReportFile.fromJson(Map<String, dynamic> json) {
    return IncidentReportFile(
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
