import 'package:flutter/material.dart';
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/screens/trip_detail_screen.dart';
import 'package:driverapp/screens/fuel_report_screen.dart';
import 'package:driverapp/screens/incident_report_screen.dart';
import 'package:driverapp/components/status_update_section.dart';

class TripDetailBottomSheet extends StatelessWidget {
  final Trip trip;
  final String driverId;
  final bool isLoadingStatuses;
  final DeliveryStatus? nextStatus;
  final bool isFinalStatus;
  final Function(String newStatus, String statusName) onStatusUpdated;
  final VoidCallback onStatusesUpdated;

  const TripDetailBottomSheet({
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
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with trip ID
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi tiết Trip: ${trip.tripId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Trip info and actions
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Current status
                  const Text(
                    'Trạng thái hiện tại:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          trip.statusName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Update status section (if not completed, canceled or delayed)
                  if (trip.status != 'completed' && trip.status != 'delaying' && trip.status != 'canceled')
                    StatusUpdateSection(
                      trip: trip,
                      driverId: driverId,
                      isLoadingStatuses: isLoadingStatuses,
                      nextStatus: nextStatus,
                      isFinalStatus: isFinalStatus,
                      onStatusUpdated: onStatusUpdated,
                      onStatusesUpdated: onStatusesUpdated,
                    ),
                  
                  // Show a message when trip is canceled or delayed
                  if (trip.status == 'delaying' || trip.status == 'canceled')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            trip.status == 'delaying' ? Icons.pending_actions : Icons.cancel,
                            color: trip.status == 'delaying' ? Colors.orange : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trip.status == 'delaying' 
                                ? 'Chuyến đang bị trì hoãn' 
                                : 'Chuyến đã bị hủy',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Không thể cập nhật trạng thái chuyến này.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // View full details button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TripDetailScreen(tripId: trip.tripId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Xem chi tiết đầy đủ'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  
                  // Additional report buttons for in-progress trips
                  if (trip.status != 'not_started' && trip.status != 'completed') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FuelReportScreen(tripId: trip.tripId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_gas_station, color: Colors.orange),
                        label: const Text('Báo cáo đổ nhiên liệu'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    
                    // Add Incident Report button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IncidentReportScreen(tripId: trip.tripId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.report_problem, color: Colors.red),
                        label: const Text('Báo cáo sự cố'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
