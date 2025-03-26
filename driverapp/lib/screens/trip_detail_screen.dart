import 'package:flutter/material.dart';
import 'package:driverapp/services/trip_service.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/services/delivery_status_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TripService _tripService = TripService();
  final OrderService _orderService = OrderService();
  final DeliveryStatusService _statusService = DeliveryStatusService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _tripDetails;
  Map<String, dynamic>? _orderDetails;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load trip details
      final tripDetails = await _tripService.getTripDetail(widget.tripId);
      
      // Load order details
      final orderDetails = await _orderService.getOrderByTripId(widget.tripId);

      if (mounted) {
        setState(() {
          _tripDetails = tripDetails;
          _orderDetails = orderDetails;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết Trip ${widget.tripId}'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetails,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : _buildDetailsContent(),
      ),
    );
  }

  Widget _buildDetailsContent() {
    if (_tripDetails == null || _orderDetails == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Thông tin Trip'),
          _buildDetailCard(_buildTripDetails()),
          
          if (_tripDetails!['tripStatusHistories'] != null && 
              (_tripDetails!['tripStatusHistories'] as List).isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionTitle('Lịch sử trạng thái'),
            _buildDetailCard(_buildTripStatusHistory()),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  List<Widget> _buildTripDetails() {
    return [
      InfoRow(label: 'Trip ID:', value: _tripDetails!['tripId'] ?? 'N/A'),
      FutureBuilder<String>(
        future: _statusService.getStatusName(_tripDetails!['status']),
        builder: (context, snapshot) {
          final statusName = snapshot.data ?? _getTripStatusName(_tripDetails!['status']);
          return InfoRow(label: 'Trạng thái:', value: statusName);
        },
      ),
      InfoRow(label: 'Xe kéo ID:', value: _tripDetails!['tractorId'] ?? 'N/A'),
      InfoRow(label: 'Rơ moóc ID:', value: _tripDetails!['trailerId'] ?? 'N/A'),
      InfoRow(
        label: 'Thời gian bắt đầu:', 
        value: DateFormatter.formatDateTimeFromString(_tripDetails!['startTime']),
      ),
      InfoRow(
        label: 'Thời gian kết thúc:', 
        value: DateFormatter.formatDateTimeFromString(_tripDetails!['endTime']),
      ),
    ];
  }


  List<Widget> _buildTripStatusHistory() {
    final List<dynamic> histories = List.from(_tripDetails!['tripStatusHistories']);
    
    // Sort histories by startTime (chronologically)
    histories.sort((a, b) {
      DateTime aTime = DateTime.parse(a['startTime']);
      DateTime bTime = DateTime.parse(b['startTime']);
      return aTime.compareTo(bTime);
    });
    
    final List<Widget> widgets = [];
    
    for (int i = 0; i < histories.length; i++) {
      final history = histories[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _statusService.getStatusName(history['statusId']),
                      builder: (context, snapshot) {
                        final statusName = snapshot.data ?? _getTripStatusName(history['statusId']);
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
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }

  // Fallback method when API fails
  String _getTripStatusName(String? status) {
    return _statusService.getStatusNameFallback(status);
  }
}
