import 'package:flutter/material.dart';
import '../../services/delivery_status_service.dart';
import '../../utils/date_formatter.dart';
import '../info_row.dart';

class TripInfoSection extends StatelessWidget {
  final Map<String, dynamic> tripDetails;
  final Map<String, dynamic> orderDetails;
  final DeliveryStatusService statusService;

  const TripInfoSection({
    Key? key,
    required this.tripDetails,
    required this.orderDetails,
    required this.statusService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildTripDetails(),
        ),
      ),
    );
  }

  List<Widget> _buildTripDetails() {
    return [
      InfoRow(label: 'Mã chuyến:', value: tripDetails['tripId'] ?? 'N/A'),
      FutureBuilder<String>(
        future: statusService.getStatusName(tripDetails['status']),
        builder: (context, snapshot) {
          final statusName = snapshot.data ?? _getTripStatusName(tripDetails['status']);
          return InfoRow(label: 'Trạng thái:', value: statusName);
        },
      ),
      InfoRow(label: 'Xe kéo:', value: tripDetails['tractorId'] ?? 'N/A'),
      InfoRow(label: 'Rơ moóc:', value: tripDetails['trailerId'] ?? 'N/A'),
      InfoRow(
        label: 'Thời gian bắt đầu:',
        value: DateFormatter.formatDateTimeFromString(tripDetails['startTime']),
      ),
      InfoRow(
        label: 'Thời gian kết thúc:',
        value: tripDetails['endTime'] != null
            ? DateFormatter.formatDateTimeFromString(tripDetails['endTime'])
            : 'Chưa hoàn thành',
      ),
      // Add match information
      InfoRow(
        label: 'Loại ghép:',
        value: _getMatchTypeName(tripDetails['matchType']),
      ),
      InfoRow(label: 'Ghép bởi:', value: tripDetails['matchBy'] ?? 'N/A'),
      InfoRow(
        label: 'Thời gian ghép:',
        value: tripDetails['matchTime'] != null
            ? DateFormatter.formatDateTimeFromString(tripDetails['matchTime'])
            : 'N/A',
      ),
    ];
  }

  // Helper method to convert matchType code to readable text
  String _getMatchTypeName(dynamic matchType) {
    if (matchType == null) return 'N/A';

    switch (matchType) {
      case 1:
        return 'Thủ công';
      case 2:
        return 'Tự động';
      default:
        return 'Loại $matchType';
    }
  }

  // Fallback method when API fails
  String _getTripStatusName(String? status) {
    return statusService.getStatusNameFallback(status);
  }
}