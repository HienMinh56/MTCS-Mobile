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
  final List<dynamic> incidentReportsFiles;

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
    required this.incidentReportsFiles,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      reportId: json['reportId'] ?? '',
      tripId: json['tripId'] ?? '',
      reportedBy: json['reportedBy'] ?? 'Unknown',
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
      incidentReportsFiles: json['incidentReportsFiles'] ?? [],
    );
  }

  // Trả về một chuỗi cho biết trạng thái xử lý của sự cố
  String get statusDisplay {
    if (status.toLowerCase() == 'resolved' || status.toLowerCase() == 'done') {
      return 'Đã xử lý';
    } else if (status.toLowerCase() == 'handling') {
      return 'Đang xử lý';
    } else {
      return 'Chờ xử lý';
    }
  }

  // Kiểm tra xem sự cố đã được xử lý hay chưa
  bool get isHandled => 
      status.toLowerCase() == 'resolved' || 
      status.toLowerCase() == 'done';
}
