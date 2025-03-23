class FuelReport {
  final String reportId;
  final String tripId;
  final double refuelAmount;
  final double fuelCost;
  final String location;
  final DateTime reportTime;
  final String reportBy;
  final List<dynamic> fuelReportFiles;

  FuelReport({
    required this.reportId,
    required this.tripId,
    required this.refuelAmount,
    required this.fuelCost,
    required this.location,
    required this.reportTime,
    required this.reportBy,
    required this.fuelReportFiles,
  });

  factory FuelReport.fromJson(Map<String, dynamic> json) {
    return FuelReport(
      reportId: json['reportId'] ?? '',
      tripId: json['tripId'] ?? '',
      refuelAmount: json['refuelAmount']?.toDouble() ?? 0.0,
      fuelCost: json['fuelCost']?.toDouble() ?? 0.0,
      location: json['location'] ?? '',
      reportTime: json['reportTime'] != null
          ? DateTime.parse(json['reportTime'])
          : DateTime.now(),
      reportBy: json['reportBy'] ?? 'Unknown',
      fuelReportFiles: json['fuelReportFiles'] ?? [],
    );
  }
}
