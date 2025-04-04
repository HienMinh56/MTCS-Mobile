import 'package:flutter/material.dart';
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/services/trip_service.dart';
import 'package:driverapp/services/delivery_status_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/trip_filter_panel.dart';  // Import the new component
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
  List<Trip> _filteredTrips = []; // Store filtered trips
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Filter state variables
  String? _statusFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  bool _showFilterPanel = false; // Control filter panel visibility

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
            _trips.sort((a, b) => b.startTime!.compareTo(a.startTime!));
            _applyFilters(); // Apply filters after loading
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
            _trips.sort((a, b) => b.startTime!.compareTo(a.startTime!));
            _applyFilters(); // Apply filters after loading
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

  // Apply filters to the trips list
  void _applyFilters() {
    List<Trip> result = List.from(_trips);
    
    // Apply status filter if selected
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      result = result.where((trip) => trip.status == _statusFilter).toList();
    }
    
    // Apply date range filter if selected
    if (_startDateFilter != null) {
      result = result.where((trip) {
        final tripDate = trip.startTime;
        return tripDate != null && tripDate.isAfter(_startDateFilter!);
      }).toList();
    }
    
    if (_endDateFilter != null) {
      final endOfDay = DateTime(_endDateFilter!.year, _endDateFilter!.month, 
                               _endDateFilter!.day, 23, 59, 59);
      result = result.where((trip) {
        final tripDate = trip.startTime;
        return tripDate != null && tripDate.isBefore(endOfDay);
      }).toList();
    }
    
    setState(() {
      _filteredTrips = result;
    });
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _statusFilter = null;
      _startDateFilter = null;
      _endDateFilter = null;
      _applyFilters();
    });
  }

  // Handle filter changes from the filter component
  void _handleFilterChange(String? status, DateTime? startDate, DateTime? endDate) {
    setState(() {
      _statusFilter = status;
      _startDateFilter = startDate;
      _endDateFilter = endDate;
      _applyFilters();
    });
  }

  // Update a specific trip in the list or remove it if it no longer matches filter
  void _updateTripInList(String tripId, String newStatus, String newStatusName) {
    // Check if the updated trip should remain in the current list based on filter criteria
    bool shouldKeepInList = _shouldKeepInList(newStatus);
    
    if (!shouldKeepInList) {
      // If the trip should no longer be in this list, remove it
      setState(() {
        _trips.removeWhere((trip) => trip.tripId == tripId);
        _applyFilters(); // Reapply filters after updating
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
        _applyFilters(); // Reapply filters after updating
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
        elevation: 0,
        backgroundColor: ColorConstants.primaryColor,
        actions: [
          // Only show filter toggle button on completed trips screen
          if (widget.status == 'completed')
            IconButton(
              icon: Icon(_showFilterPanel ? Icons.filter_list_off : Icons.filter_list),
              onPressed: () {
                setState(() {
                  _showFilterPanel = !_showFilterPanel;
                });
              },
              tooltip: 'Lọc danh sách',
            ),
        ],
      ),
      body: Column(
        children: [
          // Use the new filter component - only visible for completed trips and when toggle is on
          if (widget.status == 'completed' && _showFilterPanel)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showFilterPanel ? null : 0,
              child: TripFilterPanel(
                statusFilter: _statusFilter,
                startDateFilter: _startDateFilter,
                endDateFilter: _endDateFilter,
                onApplyFilter: _handleFilterChange,
                onResetFilter: _resetFilters,
              ),
            ),
            
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTrips,
              color: ColorConstants.accentColor,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : (_filteredTrips.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.horizontal_rule,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Không có trip nào',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  // Show reset filters button if filters are active
                                  if (_statusFilter != null || _startDateFilter != null || _endDateFilter != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: TextButton.icon(
                                        onPressed: _resetFilters,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Xóa bộ lọc'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: ColorConstants.accentColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _filteredTrips.length,
                              itemBuilder: (context, index) {
                                final trip = _filteredTrips[index];
                                return TripCard(
                                  trip: trip,
                                  onStatusUpdated: _updateTripInList,
                                );
                              },
                            )),
            ),
          ),
        ],
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
      final statuses = await _statusService.getDeliveryStatuses();
      
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
        // Also check if the next status is 'completed'
        _isFinalStatus = (nextStatus == null || 
                         widget.trip.status == 'completed' || 
                         (nextStatus.statusId == 'completed'));
      });
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
    Color statusColor;
    IconData statusIcon;
    
    // Determine status color and icon based on trip status
    switch (widget.trip.status) {
      case 'not_started':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'delaying':
        statusColor = const Color.fromARGB(255, 119, 89, 0);
        statusIcon = Icons.hourglass_bottom;
        break;
      case 'canceled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color.fromARGB(255, 0, 17, 255);
        statusIcon = Icons.directions_car;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Header with status indicator
          Container(
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trip: ${widget.trip.tripId}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.trip.statusName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Trip details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fix: Remove custom styling parameters from InfoRow
                InfoRow(
                  label: 'Order ID:', 
                  value: widget.trip.orderId,
                ),
                const SizedBox(height: 8),
                
                // Fix: Replace InfoRow with custom Row for start time
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Thời gian bắt đầu:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatDateTime(widget.trip.startTime),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Fix: Replace InfoRow with custom Row for end time
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Thời gian kết thúc:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatDateTime(widget.trip.endTime),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                
                // Add buttons row - smaller and more harmonious design
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Order details button - compact styling
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailScreen(tripId: widget.trip.tripId),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: ColorConstants.primaryColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ColorConstants.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: ColorConstants.primaryColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.inventory,
                                  color: ColorConstants.primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Xem Order',
                                style: TextStyle(
                                  color: ColorConstants.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 10),
                    
                    // Trip details and update button - compact styling
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _showTripDetailAndUpdateOptions();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: ColorConstants.accentColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ColorConstants.accentColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: ColorConstants.accentColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: ColorConstants.accentColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quản lý Trip',
                                style: TextStyle(
                                  color: ColorConstants.accentColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTripDetailAndUpdateOptions() {
    // Update this section to use the new approach
    if (_allStatuses == null && widget.trip.status != 'completed' && !_isLoadingStatuses) {
      _loadAllStatuses();
    } else if (_allStatuses != null && _nextStatus == null && widget.trip.status != 'completed') {
      _determineNextStatus();
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
                // Handle bar for dragging
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip: ${widget.trip.tripId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Order: ${widget.trip.orderId}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.trip.statusName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Update status button (if not completed)
                      if (widget.trip.status != 'completed' && 
                          widget.trip.status != 'delaying' && 
                          widget.trip.status != 'canceled')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cập nhật trạng thái:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _isLoadingStatuses
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : _nextStatus == null
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'Không thể cập nhật trạng thái',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
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
                                            backgroundColor: ColorConstants.accentColor,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            textStyle: const TextStyle(
                                              fontSize: 16, 
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                          ],
                        ),
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Tuỳ chọn khác:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildActionButton(
                        label: 'Xem chi tiết đầy đủ',
                        icon: Icons.visibility,
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.pop(context); // Close sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TripDetailScreen(tripId: widget.trip.tripId),
                            ),
                          );
                        },
                      ),
                      
                      if (widget.trip.status != 'not_started' && widget.trip.status != 'completed') ...[
                        const SizedBox(height: 12),
                        _buildActionButton(
                          label: 'Báo cáo đổ nhiên liệu',
                          icon: Icons.local_gas_station,
                          color: Colors.orange,
                          onPressed: () {
                            Navigator.pop(context); // Close sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FuelReportScreen(tripId: widget.trip.tripId),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        _buildActionButton(
                          label: 'Báo cáo sự cố',
                          icon: Icons.report_problem,
                          color: Colors.red,
                          onPressed: () {
                            Navigator.pop(context); // Close sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IncidentReportScreen(tripId: widget.trip.tripId),
                              ),
                            );
                          },
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
  
  // Helper method for building action buttons - renamed to avoid conflicts
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
  
  Future<void> _updateTripStatus(
    BuildContext context, 
    String newStatus, 
    String statusName,
    {bool bypassDeliveryReportCheck = false}
  ) async {
    // Check if the next status is 'completed' and we need to show delivery report
    if ((_isFinalStatus || newStatus == 'completed') && !bypassDeliveryReportCheck) {
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