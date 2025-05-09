import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Add this for Clipboard
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/services/trip_service.dart';
import 'package:driverapp/services/delivery_status_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/trip_filter_panel.dart';
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
  List<Trip> _filteredTrips = [];
  bool _isLoading = true;
  String _errorMessage = '';

  String? _statusFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  String? _trackingCodeFilter;
  bool _showFilterPanel = false;

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
        // For legacy support - use the new API with group type parameter
        String groupType = "completed"; // Default fallback
        
        // Determine group type based on the status lists
        if (widget.statusList!.contains("completed") || widget.statusList!.contains("canceled")) {
          groupType = "completed";
        } else if (widget.statusList!.any((s) => s != "not_started" && 
                                              s != "completed" && 
                                              s != "canceled")) {
          groupType = "in_progress";
        } else if (widget.statusList!.contains("not_started")) {
          groupType = "not_started";
        }
        
        // Use the new optimized API
        final trips = await _tripService.getDriverTripsByGroup(
          widget.driverId, 
          groupType: groupType
        );
        
        if (mounted) {
          setState(() {
            _trips = trips;
            _sortTrips();
            _applyFilters();
            _isLoading = false;
          });
        }
      } else {
        // Map individual status to group type
        String groupType = widget.status;
        
        // Convert legacy status to group type
        if (widget.status == 'completed' || widget.status == 'canceled') {
          groupType = 'completed';
        } else if (widget.status != 'not_started') {
          groupType = 'in_progress';
        } else {
          groupType = 'not_started';
        }
        
        // Use the new optimized API
        final trips = await _tripService.getDriverTripsByGroup(
          widget.driverId,
          groupType: groupType
        );

        if (mounted) {
          setState(() {
            _trips = trips;
            _sortTrips();
            _applyFilters();
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

  void _sortTrips() {
    _trips.sort((a, b) {
      // Handle null endTime values
      if (a.endTime == null && b.endTime == null) {
        return 0;
      } else if (a.endTime == null) {
        return 1; // Null values go at the end
      } else if (b.endTime == null) {
        return -1;
      }
      // Sort by most recent first (descending order)
      return b.endTime!.compareTo(a.endTime!);
    });
  }

  void _applyFilters() {
    List<Trip> result = List.from(_trips);

    // Lọc theo deliveryDate nếu status là not_started
    if (widget.status == 'not_started') {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      result = result.where((trip) {
        if (trip.order?.deliveryDate == null) return false;
        
        // Chuyển deliveryDate từ String sang DateTime
        final deliveryDate = DateTime.tryParse(trip.order!.deliveryDate);
        if (deliveryDate == null) return false;
        
        // So sánh chỉ ngày/tháng/năm, không quan tâm giờ phút giây
        final tripDeliveryDate = DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);
        return tripDeliveryDate.isAtSameMomentAs(todayDate);
      }).toList();
    }

    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      result = result.where((trip) => trip.status == _statusFilter).toList();
    }

    if (_startDateFilter != null) {
      result = result.where((trip) {
        final tripStartDate = trip.startTime;
        final tripEndDate = trip.endTime;
        return (tripStartDate != null && tripStartDate.isAfter(_startDateFilter!)) ||
            (tripEndDate != null && tripEndDate.isAfter(_startDateFilter!));
      }).toList();
    }

    if (_endDateFilter != null) {
      final endOfDay = DateTime(_endDateFilter!.year, _endDateFilter!.month,
          _endDateFilter!.day, 23, 59, 59);
      result = result.where((trip) {
        final tripStartDate = trip.startTime;
        final tripEndDate = trip.endTime;
        return (tripStartDate != null && tripStartDate.isBefore(endOfDay)) ||
            (tripEndDate != null && tripEndDate.isBefore(endOfDay));
      }).toList();
    }

    if (_trackingCodeFilter != null && _trackingCodeFilter!.isNotEmpty) {
      result = result.where((trip) => 
        trip.trackingCode.toLowerCase().contains(_trackingCodeFilter!.toLowerCase())
      ).toList();
    }

    setState(() {
      _filteredTrips = result;
    });
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = null;
      _startDateFilter = null;
      _endDateFilter = null;
      _trackingCodeFilter = null;
      _applyFilters();
    });
  }

  void _handleFilterChange(String? status, DateTime? startDate, DateTime? endDate, String? trackingCode) {
    setState(() {
      _statusFilter = status;
      _startDateFilter = startDate;
      _endDateFilter = endDate;
      _trackingCodeFilter = trackingCode;
      _applyFilters();
    });
  }

  void _updateTripInList(String tripId, String newStatus, String newStatusName) {
    bool shouldKeepInList = _shouldKeepInList(newStatus);

    if (!shouldKeepInList) {
      setState(() {
        _trips.removeWhere((trip) => trip.tripId == tripId);
        _applyFilters();
      });
    } else {
      setState(() {
        for (int i = 0; i < _trips.length; i++) {
          if (_trips[i].tripId == tripId) {
            _trips[i].status = newStatus;
            _trips[i].statusName = newStatusName;
            break;
          }
        }
        _applyFilters();
      });
    }
  }

  bool _shouldKeepInList(String? status) {
    if (status == null) return false;
    
    if (widget.statusList != null && widget.statusList!.isNotEmpty) {
      return widget.statusList!.contains(status);
    }
    return widget.status == status;
  }

  String getScreenTitle() {
    if (widget.status == 'not_started') {
      return 'Chuyến Chưa Bắt Đầu';
    } else if (widget.status == 'in_progress') {
      return 'Chuyến Đang Xử Lý';
    } else if (widget.status == 'completed') {
      return 'Chuyến Đã Hoàn Thành';
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
          if (_showFilterPanel)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showFilterPanel ? null : 0,
              child: TripFilterPanel(
                statusFilter: _statusFilter,
                startDateFilter: _startDateFilter,
                endDateFilter: _endDateFilter,
                trackingCodeFilter: _trackingCodeFilter,
                onApplyFilter: _handleFilterChange,
                onResetFilter: _resetFilters,
                showStatusFilter: widget.status == 'completed', // Chỉ hiển thị bộ lọc trạng thái khi ở màn hình completed
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
                                    'Không có chuyến',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
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

  static List<DeliveryStatus>? _allStatuses;

  bool _isLoadingStatuses = false;
  DeliveryStatus? _nextStatus;
  bool _isFinalStatus = false;

  @override
  void initState() {
    super.initState();
    if (_allStatuses == null) {
      _loadAllStatuses();
    } else {
      _determineNextStatus();
    }
  }

  Future<void> _loadAllStatuses() async {
    if (widget.trip.status == 'completed') return;

    setState(() {
      _isLoadingStatuses = true;
    });

    try {
      final statuses = await _statusService.getDeliveryStatuses();
      _allStatuses = statuses;

      if (mounted) {
        setState(() {
          _isLoadingStatuses = false;
        });
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

  void _determineNextStatus() {
    if (_allStatuses == null || widget.trip.status == 'completed') {
      _isFinalStatus = (widget.trip.status == 'completed');
      return;
    }

    DeliveryStatus? currentStatus;
    for (var status in _allStatuses!) {
      if (status.statusId == widget.trip.status) {
        currentStatus = status;
        break;
      }
    }

    if (currentStatus == null) return;

    int currentIndex = currentStatus.statusIndex;

    DeliveryStatus? nextStatus;
    for (var status in _allStatuses!) {
      if (status.statusId != 'canceled' &&
          status.statusId != 'delaying' &&
          status.statusIndex == currentIndex + 1 &&
          status.isActive == 1) {  // Chỉ xem xét trạng thái active (isActive = 1)
        nextStatus = status;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _nextStatus = nextStatus;
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
          userId: driverId,
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

  Future<void> _navigateWithRefresh(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    final _TripListScreenState? parentState =
        context.findAncestorStateOfType<_TripListScreenState>();

    if (parentState != null && mounted) {
      parentState._loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

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
        statusColor = const Color.fromARGB(255, 241, 188, 27);
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
          Container(
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dòng đầu tiên chỉ hiển thị tracking code và nút copy
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.trip.trackingCode.isNotEmpty 
                            ? 'Mã vận đơn: ${widget.trip.trackingCode}'
                            : 'Mã chuyến: ${widget.trip.tripId}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    // Add copy button for tracking code
                    if (widget.trip.trackingCode.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.trip.trackingCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép mã vận đơn'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
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
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.trip.order?.containerNumber != null && 
                    widget.trip.order!.containerNumber.isNotEmpty)
                  InfoRow(
                    label: 'Mã Container:',
                    value: widget.trip.order!.containerNumber,
                  ),
                  
                if (widget.trip.order?.pickUpLocation != null && 
                    widget.trip.order!.pickUpLocation.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Điểm lấy cont:',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Add copy button for pickup location
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.trip.order!.pickUpLocation));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép điểm lấy cont'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0, top: 4.0),
                        child: Text(
                          widget.trip.order!.pickUpLocation,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                
                if (widget.trip.order?.deliveryLocation != null && 
                    widget.trip.order!.deliveryLocation.isNotEmpty)
                  const SizedBox(height: 8),
                  if (widget.trip.order?.deliveryLocation != null && 
                      widget.trip.order!.deliveryLocation.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Điểm giao:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            // Add copy button for delivery location
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: widget.trip.order!.deliveryLocation));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã sao chép điểm giao'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 24.0, top: 4.0),
                          child: Text(
                            widget.trip.order!.deliveryLocation,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                
                if (widget.trip.order?.conReturnLocation != null && 
                    widget.trip.order!.conReturnLocation.isNotEmpty)
                  const SizedBox(height: 8),
                  if (widget.trip.order?.conReturnLocation != null && 
                      widget.trip.order!.conReturnLocation.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Điểm trả cont:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            // Add copy button for container return location
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: widget.trip.order!.conReturnLocation));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã sao chép điểm trả cont'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 24.0, top: 4.0),
                          child: Text(
                            widget.trip.order!.conReturnLocation,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _navigateWithRefresh(OrderDetailScreen(tripId: widget.trip.tripId));
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
                                'Xem Đơn Hàng',
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
                                'Quản lý chuyến',
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
                            'Mã vận đơn: ${widget.trip.order?.trackingCode}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
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
                            const SizedBox(height: 8),
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
                                            foregroundColor: Colors.white, // Thêm thuộc tính này để đặt màu chữ
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
                          Navigator.pop(context);
                          _navigateWithRefresh(TripDetailScreen(tripId: widget.trip.tripId));
                        },
                      ),
                      if (widget.trip.status != 'not_started' &&
                          widget.trip.status != 'completed' &&
                          widget.trip.status != 'canceled') ...[
                        const SizedBox(height: 12),
                        _buildActionButton(
                          label: 'Báo cáo đổ nhiên liệu',
                          icon: Icons.local_gas_station,
                          color: Colors.orange,
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateWithRefresh(FuelReportScreen(tripId: widget.trip.tripId));
                          },
                        ),
                        if (widget.trip.status != 'delaying') ...[
                          const SizedBox(height: 12),
                          _buildActionButton(
                            label: 'Báo cáo sự cố',
                            icon: Icons.report_problem,
                            color: Colors.red,
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateWithRefresh(IncidentReportScreen(tripId: widget.trip.tripId));
                            },
                          ),
                        ],
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
    String statusName, {
    bool bypassDeliveryReportCheck = false,
  }) async {
    // Bỏ qua dialog xác nhận nếu cập nhật sang trạng thái completed
    bool confirmed = true;
    
    // Hiển thị dialog xác nhận chỉ khi KHÔNG phải cập nhật sang trạng thái completed
    if (newStatus != 'completed') {
      // Show confirmation dialog for all status updates except completed
      String confirmTitle = 'Xác nhận cập nhật';
      String confirmMessage = 'Bạn có chắc chắn muốn cập nhật trạng thái chuyến này sang "${statusName}" không?';
      String confirmButtonText = 'Cập nhật';
      IconData headerIcon = Icons.update;
      Color iconColor = ColorConstants.accentColor;
      
      // Special message for starting a trip
      if (widget.trip.status == 'not_started') {
        confirmTitle = 'Xác nhận bắt đầu';
        confirmMessage = 'Bạn có chắc chắn muốn bắt đầu chuyến này không?';
        confirmButtonText = 'Bắt đầu';
        headerIcon = Icons.play_arrow;
        iconColor = Colors.green;
      }
      
      final bool? dialogResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    headerIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  confirmTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: iconColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        confirmMessage,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trip.trackingCode.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Mã vận đơn: ${widget.trip.trackingCode}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(headerIcon, size: 18, color: Colors.white,),
                  const SizedBox(width: 8),
                  Text(
                    confirmButtonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      
      confirmed = dialogResult == true;
    }
    
    if (!confirmed) {
      return;
    }

    // Sau khi đã xác nhận hoặc bỏ qua xác nhận (với trạng thái completed), kiểm tra báo cáo giao hàng
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
          _determineNextStatus();
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
          final _TripListScreenState? parentState =
              context.findAncestorStateOfType<_TripListScreenState>();
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
              content: Text('${result['message']}'),
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