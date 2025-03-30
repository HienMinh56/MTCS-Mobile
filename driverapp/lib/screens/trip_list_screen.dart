import 'package:flutter/material.dart';
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/services/trip_service.dart';
import 'package:driverapp/services/delivery_status_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/screens/trip_detail_screen.dart';
import 'package:driverapp/screens/order_detail_screen.dart';
import 'package:driverapp/screens/fuel_report_screen.dart';
import 'package:driverapp/screens/delivery_report_screen.dart';
import 'package:driverapp/screens/incident_report_screen.dart';

class TripListScreen extends StatefulWidget {
  final String driverId;
  final String status;
  final List<String>? statusList;

  const TripListScreen({
    Key? key,
    required this.driverId,
    required this.status,
    this.statusList,
  }) : super(key: key);

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final TripService _tripService = TripService();
  List<Trip> _trips = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.statusList != null && widget.statusList!.isNotEmpty) {
        // Load multiple statuses for "in_progress"
        final List<Trip> allTrips = [];
        for (final status in widget.statusList!) {
          final trips = await _tripService.getDriverTrips(
            widget.driverId,
            status: status,
          );
          allTrips.addAll(trips);
        }
        
        if (mounted) {
          setState(() {
            _trips = allTrips;
            _isLoading = false;
          });
        }
      } else {
        // Load single status
        final trips = await _tripService.getDriverTrips(
          widget.driverId,
          status: widget.status,
        );
        
        if (mounted) {
          setState(() {
            _trips = trips;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khi tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Update a specific trip in the list or remove it if it no longer matches filter
  void _updateTripInList(String tripId, String newStatus, String newStatusName) {
    // Check if the updated trip should remain in the current list based on filter criteria
    bool shouldKeepInList = _shouldKeepInList(newStatus);
    
    if (!shouldKeepInList) {
      // If the trip should no longer be in this list, remove it
      setState(() {
        _trips.removeWhere((trip) => trip.tripId == tripId);
      });
    } else {
      // Just update the status
      setState(() {
        for (int i = 0; i < _trips.length; i++) {
          if (_trips[i].tripId == tripId) {
            _trips[i].status = newStatus;
            _trips[i].statusName = newStatusName;
            break;
          }
        }
      });
    }
  }
  
  // Determine if a trip with the given status should be in the current list
  bool _shouldKeepInList(String status) {
    // If we're showing multiple statuses (for in_progress trips)
    if (widget.statusList != null && widget.statusList!.isNotEmpty) {
      return widget.statusList!.contains(status);
    }
    // If we're showing a single status
    return widget.status == status;
  }

  String getScreenTitle() {
    if (widget.status == 'not_started') {
      return 'Trip Chưa Bắt Đầu';
    } else if (widget.status == 'in_progress') {
      return 'Trip Đang Xử Lý';
    } else if (widget.status == 'completed') {
      return 'Trip Đã Hoàn Thành';
    }
    return 'Danh Sách Trip';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getScreenTitle()),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : _trips.isEmpty
                    ? const Center(child: Text('Không có trip nào'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _trips.length,
                        itemBuilder: (context, index) {
                          final trip = _trips[index];
                          return TripCard(
                            trip: trip,
                            onStatusUpdated: _updateTripInList,
                          );
                        },
                      ),
      ),
    );
  }
}

class TripCard extends StatefulWidget {
  final Trip trip;
  final void Function(String tripId, String newStatus, String newStatusName)? onStatusUpdated;

  const TripCard({
    Key? key,
    required this.trip,
    this.onStatusUpdated,
  }) : super(key: key);

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  final TripService _tripService = TripService();
  final DeliveryStatusService _statusService = DeliveryStatusService();
  
  // Add a static cache to store next status information
  static final Map<String, DeliveryStatus> _nextStatusCache = {};
  
  // Add state variables to track loading status and final status
  bool _isLoadingNextStatus = false;
  DeliveryStatus? _nextStatus;
  bool _isFinalStatus = false;
  
  @override
  void initState() {
    super.initState();
    // Pre-load next status information if not in cache
    if (widget.trip.status != 'completed' && !_nextStatusCache.containsKey(widget.trip.status)) {
      _loadNextStatus();
    } else if (_nextStatusCache.containsKey(widget.trip.status)) {
      _nextStatus = _nextStatusCache[widget.trip.status];
      _checkIfFinalStatus();
    }
  }
  
  // Method to check if the next status is the final status
  void _checkIfFinalStatus() {
    // Check if there will be no further status after this one
    _statusService.hasNextStatus(_nextStatus?.statusId ?? '').then((hasNext) {
      if (mounted) {
        setState(() {
          _isFinalStatus = !hasNext;
        });
      }
    });
  }
  
  // Method to load next status
  Future<void> _loadNextStatus() async {
    if (widget.trip.status == 'completed') return;
    
    setState(() {
      _isLoadingNextStatus = true;
    });
    
    try {
      final nextStatus = await _statusService.getNextTripStatus(widget.trip.status);
      if (nextStatus != null) {
        // Store in cache for future use
        _nextStatusCache[widget.trip.status] = nextStatus;
      }
      
      if (mounted) {
        setState(() {
          _nextStatus = nextStatus;
          _isLoadingNextStatus = false;
        });
        
        // Check if this is the final status
        _checkIfFinalStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNextStatus = false;
        });
      }
    }
  }
  
  Future<void> _navigateToDeliveryReportScreen() async {
    final _TripListScreenState? parentState = 
        context.findAncestorStateOfType<_TripListScreenState>();
    
    if (parentState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xác định ID tài xế'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final String driverId = parentState.widget.driverId;
    
    final bool? reportSubmitted = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryReportScreen(
          tripId: widget.trip.tripId,
          userId: driverId, // Use the driverId from parent widget
          onReportSubmitted: (success) {
            Navigator.pop(context, success);
          },
        ),
      ),
    );
    
    if (reportSubmitted == true && context.mounted && _nextStatus != null) {
      _updateTripStatus(
        context, 
        _nextStatus!.statusId,
        _nextStatus!.statusName,
        bypassDeliveryReportCheck: true,
      );
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
    // If we don't have next status yet and trip isn't completed, try loading it
    if (_nextStatus == null && widget.trip.status != 'completed' && !_isLoadingNextStatus) {
      _loadNextStatus();
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                        'Chi tiết Trip: ${widget.trip.tripId}',
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
                              widget.trip.statusName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Update status button (if not completed)
                      if (widget.trip.status != 'completed')
                        Column(
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
                            _isLoadingNextStatus
                                ? const Center(child: CircularProgressIndicator())
                                : _nextStatus == null
                                    ? const Center(child: Text('Không thể cập nhật trạng thái'))
                                    : SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _updateTripStatus(
                                            context, 
                                            _nextStatus!.statusId,
                                            _nextStatus!.statusName,
                                          ),
                                          icon: const Icon(Icons.arrow_forward),
                                          label: Text('Cập nhật thành: ${_nextStatus!.statusName}'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            textStyle: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                          ],
                        ),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripDetailScreen(tripId: widget.trip.tripId),
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
                      
                      if (widget.trip.status != 'not_started' && widget.trip.status != 'completed') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context); // Close sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FuelReportScreen(tripId: widget.trip.tripId),
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
                                  builder: (context) => IncidentReportScreen(tripId: widget.trip.tripId),
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
      },
    );
  }
  
  Future<void> _updateTripStatus(
    BuildContext context, 
    String newStatus, 
    String statusName,
    {bool bypassDeliveryReportCheck = false}
  ) async {
    if (_isFinalStatus && !bypassDeliveryReportCheck) {
      _navigateToDeliveryReportScreen();
      return;
    }

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

          final _TripListScreenState? parentState = context.findAncestorStateOfType<_TripListScreenState>();
          if (parentState != null && parentState._shouldKeepInList(newStatus)) {
            Future.delayed(Duration.zero, () {
              if (context.mounted) {
                _showTripDetailAndUpdateOptions();
              }
            });
          }
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