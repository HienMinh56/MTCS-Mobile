import 'package:flutter/material.dart';
import '../../services/delivery_status_service.dart';
import '../../utils/color_constants.dart';
import '../../utils/date_formatter.dart';

class TripStatusHistorySection extends StatelessWidget {
  final List<dynamic> statusHistories;
  final DeliveryStatusService statusService;

  const TripStatusHistorySection({
    Key? key,
    required this.statusHistories,
    required this.statusService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort histories by startTime (chronologically)
    final sortedHistories = List.from(statusHistories);
    sortedHistories.sort((a, b) {
      DateTime aTime = DateTime.parse(a['startTime']);
      DateTime bTime = DateTime.parse(b['startTime']);
      return aTime.compareTo(bTime);
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildStatusHistory(sortedHistories),
        ),
      ),
    );
  }

  List<Widget> _buildStatusHistory(List<dynamic> histories) {
    final List<Widget> widgets = [];

    for (int i = 0; i < histories.length; i++) {
      final history = histories[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status dot
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: i == histories.length - 1 
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 8),
              // Status information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: statusService.getStatusName(history['statusId']),
                      builder: (context, snapshot) {
                        final statusName = snapshot.data ??
                            _getTripStatusName(history['statusId']);
                        return Text(
                          statusName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    Text(
                      'Thời gian: ${DateFormatter.formatDateTimeFromString(history['startTime'])}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    if (history['notes'] != null && history['notes'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Ghi chú: ${history['notes']}',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      // Add connector line except for the last item
      if (i < histories.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 11.5, bottom: 12.0),
            child: Container(
              width: 1.0,
              height: 20.0,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  // Fallback method when API fails
  String _getTripStatusName(String? status) {
    return statusService.getStatusNameFallback(status);
  }
}