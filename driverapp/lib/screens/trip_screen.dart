import 'package:driverapp/screens/incident_report_screen.dart';
import 'package:driverapp/screens/fuel_report_screen.dart';
import 'package:driverapp/main.dart' as AuthService;
import 'package:flutter/material.dart';
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/data/mock_trips.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/screens/delivery_report_screen.dart';

class TripScreen extends StatefulWidget {
  final String orderId;
  final String? orderStatus; // Add orderStatus parameter

  const TripScreen({
    Key? key, 
    required this.orderId, 
    this.orderStatus,
  }) : super(key: key);

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  late Trip trip;
  late String orderStatus;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    trip = MockTrips.getDefaultTrip(widget.orderId);
    orderStatus = widget.orderStatus ?? 'Chờ xử lý'; // Default to "assigned" if not provided
    
    // Ensure trip status is consistent with order status
    if (orderStatus.toLowerCase() == 'đang giao' && trip.status == TripStatus.notStarted) {
      // If order is "Đang giao" but trip is still "Chưa bắt đầu", update trip to "Đã bắt đầu"
      trip.status = TripStatus.started;
      MockTrips.updateTripStatus(widget.orderId, TripStatus.started);
    } else if (orderStatus.toLowerCase() == 'đã giao' && trip.status != TripStatus.finished) {
      // If order is "Đã giao" but trip is not finished, update trip to "Đã hoàn thành"
      trip.status = TripStatus.finished;
      MockTrips.updateTripStatus(widget.orderId, TripStatus.finished);
    }
  }

  void _updateTripStatus() {
    String? nextStatus = TripStatus.getNextStatus(trip.status);
    
    if (nextStatus != null) {
      // Handle order status transition based on trip status
      if (orderStatus.toLowerCase() == 'chờ xử lý' && trip.status == TripStatus.notStarted) {
        // When starting, first update trip to "Đã bắt đầu" and change order to "Đang giao"
        _orderService.updateOrderStatus(widget.orderId, 'Đang giao');
        orderStatus = 'Đang giao';
      } 
      else if (orderStatus.toLowerCase() == 'đang giao' && nextStatus == TripStatus.finished) {
        // When completing processing order, move it to completed
        _orderService.updateOrderStatus(widget.orderId, 'Đã giao');
        orderStatus = 'Đã giao';
      }
      
      setState(() {
        MockTrips.updateTripStatus(widget.orderId, nextStatus);
        trip.status = nextStatus;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trạng thái đã được cập nhật thành "$nextStatus"'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showReportDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentReportScreen(
          tripId: trip.tripId,
        ),
      ),
    );
  }
  
  void _showFuelReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FuelReportScreen(
          tripId: trip.tripId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chuyến đi #${trip.tripId}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    
    // For completed orders, always show the finished status UI
    if (orderStatus.toLowerCase() == 'đã giao') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      // For other orders, show status based on trip status
      switch (trip.status) {
        case TripStatus.finished:
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          break;
        case TripStatus.onDelivery:
          statusColor = Colors.blue;
          statusIcon = Icons.local_shipping;
          break;
        case TripStatus.onLoadingGoods:
          statusColor = Colors.orange;
          statusIcon = Icons.inventory;
          break;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.pending;
      }
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    // For completed orders, always show "Hoàn thành" instead of trip.status
                    'Trạng thái: ${orderStatus.toLowerCase() == 'đã giao' ? TripStatus.finished : trip.status}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Only show progress indicator for processing and completed orders
            if (orderStatus.toLowerCase() != 'chờ xử lý')
              _buildCustomProgressIndicator(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomProgressIndicator() {
    // For completed orders, always show 100% progress
    double progressValue = orderStatus.toLowerCase() == 'đã giao' 
        ? 1.0  // Always 100% for completed orders
        : trip.status == TripStatus.notStarted
            ? 0.0
            : trip.status == TripStatus.started
                ? 0.25
                : trip.status == TripStatus.onLoadingGoods
                    ? 0.5
                    : trip.status == TripStatus.onDelivery
                        ? 0.75
                        : 1.0;
                    
    // Get readable status labels
    final statusLabels = {
      TripStatus.notStarted: 'Chưa bắt đầu',
      TripStatus.started: 'Đã bắt đầu',
      TripStatus.onLoadingGoods: 'Đang bốc hàng',
      TripStatus.onDelivery: 'Đang vận chuyển',
      TripStatus.finished: 'Hoàn thành',
    };
    
    return Column(
      children: [
        // Parent container to control the overall width
        Container(
          width: double.infinity,
          child: Stack(
            children: [
              // Background track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Foreground progress
              FractionallySizedBox(
                widthFactor: progressValue,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: progressValue == 1.0 
                        ? [Colors.green.shade400, Colors.green.shade700]
                        : [Colors.blue.shade300, Colors.blue.shade600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Status steps with position indicators
        SizedBox(
          width: double.infinity,
          height: 90, // Increased height to accommodate longer text
          child: Stack(
            children: [
              // Step connecting lines
              Positioned(
                left: 30,
                right: 30,
                top: 15,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: 0.33 <= progressValue ? Colors.green : Colors.grey[300],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: 0.67 <= progressValue ? Colors.green : Colors.grey[300],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: 1.0 <= progressValue ? Colors.green : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
              // Step indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusStep(TripStatus.notStarted, progressValue >= 0, statusLabels[TripStatus.notStarted]!),
                  _buildStatusStep(TripStatus.started, progressValue >= 0.25, statusLabels[TripStatus.started]!),
                  _buildStatusStep(TripStatus.onLoadingGoods, progressValue >= 0.5, statusLabels[TripStatus.onLoadingGoods]!),
                  _buildStatusStep(TripStatus.onDelivery, progressValue >= 0.75, statusLabels[TripStatus.onDelivery]!),
                  _buildStatusStep(TripStatus.finished, progressValue >= 1.0, statusLabels[TripStatus.finished]!),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStep(String status, bool isActive, String displayLabel) {
    Color stepColor = isActive ? Colors.green : Colors.grey[350]!;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? stepColor : Colors.white,
              border: Border.all(
                color: stepColor,
                width: 2,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: stepColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: isActive
                ? Center(
                    child: Icon(
                      status == TripStatus.finished ? Icons.flag : 
                      status == TripStatus.notStarted ? Icons.play_arrow : 
                      status == TripStatus.started ? Icons.directions_run :
                      status == TripStatus.onLoadingGoods ? Icons.inventory : 
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? stepColor : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin chuyến đi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Mã chuyến đi', trip.tripId),
            _buildInfoRow('Mã đơn hàng', trip.orderId),
            _buildInfoRow('Mã tài xế', trip.driverId),
            _buildInfoRow('Mã đầu kéo', trip.tractorId),
            _buildInfoRow('Mã rơ mooc', trip.trailerId),
            _buildInfoRow('Quãng đường', trip.distance),
            _buildInfoRow('Loại ghép', trip.matchType),
            _buildInfoRow('Người ghép', trip.matchBy),
            _buildInfoRow('Thời gian ghép', trip.matchTime),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Logic for showing buttons based on order status
    bool canUpdateStatus = orderStatus.toLowerCase() != 'đã giao';
    bool isCompleted = orderStatus.toLowerCase() == 'đã giao' || trip.status == TripStatus.finished;
    
    // Custom button text for assigned orders
    String buttonText = '';
    if (orderStatus.toLowerCase() == 'chờ xử lý') {
      buttonText = 'Bắt đầu nhận chuyến';
    } else {
      String? nextStatus = TripStatus.getNextStatus(trip.status);
      buttonText = nextStatus != null ? 'Cập nhật: ' + nextStatus : '';
    }
    
    return Column(
      children: [
        Row(
          children: [
            if (canUpdateStatus)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _updateTripStatus,
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.update, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                buttonText,
                                style: const TextStyle(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (canUpdateStatus) const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showReportDialog,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                icon: Icon(Icons.report_problem, color: Colors.orange.shade700),
                label: const Flexible(
                  child: Text(
                    'Báo cáo sự cố',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showFuelReportScreen,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              side: BorderSide(color: Colors.blue.shade300, width: 1.5),
            ),
            icon: const Icon(Icons.local_gas_station),
            label: const Text(
              'Báo cáo đổ nhiên liệu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (isCompleted) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showDeliveryNoteScreen,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.purple.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                side: BorderSide(color: Colors.purple.shade300, width: 1.5),
              ),
              icon: const Icon(Icons.description),
              label: const Text(
                'Báo cáo biên bản giao nhận',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  void _showDeliveryNoteScreen() async {
    String? userId = await AuthService.getUserId();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryReportScreen(
          tripId: trip.tripId,
          userId: userId ?? '',
        ),
      ),
    );
  }
}
