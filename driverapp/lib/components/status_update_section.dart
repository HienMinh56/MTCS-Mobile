import 'package:flutter/material.dart';
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/screens/delivery_report_screen.dart';

class StatusUpdateSection extends StatelessWidget {
  final Trip trip;
  final String driverId;
  final bool isLoadingStatuses;
  final DeliveryStatus? nextStatus;
  final bool isFinalStatus;
  final Function(String newStatus, String statusName) onStatusUpdated;
  final VoidCallback onStatusesUpdated;

  const StatusUpdateSection({
    Key? key,
    required this.trip,
    required this.driverId,
    required this.isLoadingStatuses,
    required this.nextStatus,
    required this.isFinalStatus,
    required this.onStatusUpdated,
    required this.onStatusesUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Additional safety check - don't show update options for canceled or delayed trips
    if (trip.status == 'delaying' || trip.status == 'canceled') {
      return const SizedBox.shrink(); // Return an empty widget
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cập nhật trạng thái:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        isLoadingStatuses
            ? const Center(child: CircularProgressIndicator())
            : nextStatus == null
                ? const Center(child: Text('Không thể cập nhật trạng thái'))
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isFinalStatus) {
                          _navigateToDeliveryReportScreen(context);
                        } else {
                          onStatusUpdated(nextStatus!.statusId, nextStatus!.statusName);
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text('Cập nhật thành: ${nextStatus!.statusName}'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
      ],
    );
  }

  Future<void> _navigateToDeliveryReportScreen(BuildContext context) async {
    final bool? reportSubmitted = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryReportScreen(
          tripId: trip.tripId,
          userId: driverId,
          onReportSubmitted: (success) {
            Navigator.pop(context, success);
          },
        ),
      ),
    );
    
    if (reportSubmitted == true && context.mounted && nextStatus != null) {
      onStatusUpdated(nextStatus!.statusId, nextStatus!.statusName);
      onStatusesUpdated();
    }
  }
}
