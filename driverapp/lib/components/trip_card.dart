import 'package:flutter/material.dart';
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/services/trip_service.dart';
import 'package:driverapp/services/delivery_status_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/screens/order_detail_screen.dart';
import 'package:driverapp/components/trip_detail_bottom_sheet.dart';

class TripCard extends StatefulWidget {
  final Trip trip;
  final String driverId;
  final void Function(String tripId, String newStatus, String newStatusName)? onStatusUpdated;

  const TripCard({
    Key? key,
    required this.trip,
    required this.driverId,
    this.onStatusUpdated,
  }) : super(key: key);

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  final TripService _tripService = TripService();
  final DeliveryStatusService _statusService = DeliveryStatusService();
  
  // Cache all statuses instead of just next status
  static List<DeliveryStatus>? _allStatuses;
  
  // Add state variables to track loading status and next status
  bool _isLoadingStatuses = false;
  DeliveryStatus? _nextStatus;
  bool _isFinalStatus = false;
  
  @override
  void initState() {
    super.initState();
    // Load all statuses if not already cached
    if (_allStatuses == null) {
      _loadAllStatuses();
    } else {
      _determineNextStatus();
    }
  }
  
  // Method to load all delivery statuses
  Future<void> _loadAllStatuses() async {
    if (widget.trip.status == 'completed') return;
    
    setState(() {
      _isLoadingStatuses = true;
    });
    
    try {
      // Use the delivery status service to get all statuses
      final statuses = await _statusService.getAllDeliveryStatuses();
      
      // Store all statuses in cache
      _allStatuses = statuses;
      
      if (mounted) {
        setState(() {
          _isLoadingStatuses = false;
        });
        
        // Determine next status based on all statuses
        _determineNextStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStatuses = false;
        });
      }
    }
  }
  
  // Method to determine next status based on statusIndex
  void _determineNextStatus() {
    if (_allStatuses == null || widget.trip.status == 'completed') {
      _isFinalStatus = (widget.trip.status == 'completed');
      return;
    }
    
    // Find current status in the list
    DeliveryStatus? currentStatus;
    for (var status in _allStatuses!) {
      if (status.statusId == widget.trip.status) {
        currentStatus = status;
        break;
      }
    }
    
    if (currentStatus == null) return;
    
    // Current status index
    int currentIndex = currentStatus.statusIndex;
    
    // Find the next status with the next index
    DeliveryStatus? nextStatus;
    for (var status in _allStatuses!) {
      // Find normal flow status (not canceled or delaying) with next index
      if (status.statusId != 'canceled' && 
          status.statusId != 'delaying' && 
          status.statusIndex == currentIndex + 1) {
        nextStatus = status;
        break;
      }
    }
    
    if (mounted) {
      setState(() {
        _nextStatus = nextStatus;
        // If current status is the highest index or is completed
        _isFinalStatus = (nextStatus == null || widget.trip.status == 'completed');
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip: ${widget.trip.tripId}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InfoRow(label: 'Order ID:', value: widget.trip.orderId),
            InfoRow(label: 'Trạng thái:', value: widget.trip.statusName),
            InfoRow(
              label: 'Thời gian bắt đầu:', 
              value: DateFormatter.formatDateTime(widget.trip.startTime),
            ),
            InfoRow(
              label: 'Thời gian kết thúc:', 
              value: DateFormatter.formatDateTime(widget.trip.endTime),
            ),
            
            // Add buttons row
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Order details button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailScreen(tripId: widget.trip.tripId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory, size: 18),
                  label: const Text('Xem Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                  ),
                ),
                
                // Trip details and update button
                ElevatedButton.icon(
                  onPressed: () {
                    _showTripDetailAndUpdateOptions();
                  },
                  icon: const Icon(Icons.directions_car, size: 18),
                  label: const Text('Quản lý Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTripDetailAndUpdateOptions() {
    // Don't load statuses if trip is completed, canceled or delayed
    bool canUpdateStatus = widget.trip.status != 'completed' && 
                          widget.trip.status != 'canceled' && 
                          widget.trip.status != 'delaying';
    
    if (_allStatuses == null && canUpdateStatus && !_isLoadingStatuses) {
      _loadAllStatuses();
    } else if (_allStatuses != null && _nextStatus == null && canUpdateStatus) {
      _determineNextStatus();
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return TripDetailBottomSheet(
          trip: widget.trip,
          driverId: widget.driverId,
          isLoadingStatuses: _isLoadingStatuses,
          nextStatus: _nextStatus,
          isFinalStatus: _isFinalStatus,
          onStatusUpdated: (String newStatus, String statusName) {
            _updateTripStatus(context, newStatus, statusName);
          },
          onStatusesUpdated: () {
            if (widget.onStatusUpdated != null) {
              widget.onStatusUpdated!(
                widget.trip.tripId, widget.trip.status, widget.trip.statusName);
            }
          },
        );
      },
    );
  }
  
  Future<void> _updateTripStatus(
    BuildContext context, 
    String newStatus, 
    String statusName,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _tripService.updateTripStatus(widget.trip.tripId, newStatus);
      
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        if (result['success'] == true) {
          setState(() {
            widget.trip.status = newStatus;
            widget.trip.statusName = statusName;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật thành công sang trạng thái: $statusName'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);

          if (widget.onStatusUpdated != null) {
            widget.onStatusUpdated!(widget.trip.tripId, newStatus, statusName);
          }

          // Reopen the bottom sheet if trip still belongs to the current view
          Future.delayed(Duration.zero, () {
            if (context.mounted) {
              _showTripDetailAndUpdateOptions();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật trạng thái thất bại: ${result['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
