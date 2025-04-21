import 'package:driverapp/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:driverapp/services/trip_service.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/services/delivery_status_service.dart';
import 'package:driverapp/services/fuel_report_service.dart';
import 'package:driverapp/services/incident_report_service.dart';
import 'package:driverapp/services/delivery_report_service.dart'; // Add this import
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // Add this import
import 'dart:io';

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
  final FuelReportService _fuelReportService = FuelReportService();
  final IncidentReportService _incidentReportService = IncidentReportService();
  final DeliveryReportService _deliveryReportService = DeliveryReportService(); // Add this line

  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _tripDetails;
  Map<String, dynamic>? _orderDetails;
  List<Map<String, dynamic>> _fuelReports = [];
  List<Map<String, dynamic>> _incidentReports = [];
  List<Map<String, dynamic>> _deliveryReports = []; // Add this line

  // Add state variables to track which report type is expanded
  bool _isFuelReportsExpanded = false;
  bool _isIncidentReportsExpanded = false;
  bool _isDeliveryReportsExpanded = false; // Add this line

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  // Helper method to convert dynamic maps to string key maps
  Map<String, dynamic> _convertToStringKeyMap(dynamic item) {
    if (item is Map) {
      return item.map<String, dynamic>((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _convertToStringKeyMap(value));
        } else if (value is List) {
          return MapEntry(key.toString(), _convertListItems(value));
        } else {
          return MapEntry(key.toString(), value);
        }
      });
    }
    return <String, dynamic>{};
  }

  List<dynamic> _convertListItems(List items) {
    return items.map((item) {
      if (item is Map) {
        return _convertToStringKeyMap(item);
      } else if (item is List) {
        return _convertListItems(item);
      } else {
        return item;
      }
    }).toList();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load trip details
      final Trip trip = await _tripService.getTripDetail(widget.tripId);
      
      // Convert Trip object to map for compatibility with existing code
      final Map<String, dynamic> tripDetails = {
        'tripId': trip.tripId,
        'orderId': trip.orderId,
        'trackingCode': trip.trackingCode,
        'driverId': trip.driverId,
        'tractorId': trip.tractorId,
        'trailerId': trip.trailerId,
        'startTime': trip.startTime?.toIso8601String(),
        'endTime': trip.endTime?.toIso8601String(),
        'status': trip.status,
        'statusName': trip.statusName,
        'matchType': trip.matchType,
        'matchBy': trip.matchBy,
        'matchTime': trip.matchTime?.toIso8601String(),
        'tripStatusHistories': trip.tripStatusHistories,
      };

      // Convert Order object to map for compatibility
      Map<String, dynamic> orderDetails = {};
      if (trip.order != null) {
        orderDetails = {
          'orderId': trip.order!.orderId,
          'trackingCode': trip.order!.trackingCode,
          'pickUpLocation': trip.order!.pickUpLocation,
          'deliveryLocation': trip.order!.deliveryLocation,
          'conReturnLocation': trip.order!.conReturnLocation,
          'containerNumber': trip.order!.containerNumber,
          'contactPerson': trip.order!.contactPerson,
          'contactPhone': trip.order!.contactPhone,
        };
      } else {
        // Load order details from API for backward compatibility
        try {
          final orderResponse = await _orderService.getOrderByTripId(widget.tripId);
          orderDetails = orderResponse['data'] != null
              ? _convertToStringKeyMap(orderResponse['data'])
              : <String, dynamic>{};
        } catch (e) {
          print('Error loading order details: $e');
          // Continue without order details
        }
      }

      // Load fuel reports with more robust error handling
      List<Map<String, dynamic>> fuelReports = [];
      try {
        final fuelReportsResponse = await _fuelReportService.getFuelReportsByTripId(widget.tripId);
        if (fuelReportsResponse['status'] == 200 && fuelReportsResponse['data'] is List) {
          fuelReports = (fuelReportsResponse['data'] as List)
              .map((item) => _convertToStringKeyMap(item))
              .toList();
        }
      } catch (e) {
        print('Error loading fuel reports: $e');
        // Continue with empty fuel reports rather than failing the whole function
      }

      // Load incident reports with more robust error handling
      List<Map<String, dynamic>> incidentReports = [];
      try {
        final incidentReportsResponse = await _incidentReportService
            .getIncidentReportsByTripId(widget.tripId);
        // Check for both possible success status codes (1 and 200)
        if ((incidentReportsResponse['status'] == 1 ||
            incidentReportsResponse['status'] == 200) &&
            incidentReportsResponse['data'] is List) {
          incidentReports = (incidentReportsResponse['data'] as List)
              .map((item) => _convertToStringKeyMap(item))
              .toList();
        }
      } catch (e) {
        print('Error loading incident reports: $e');
        // Continue with empty incident reports rather than failing the whole function
      }
      
      // Load delivery reports
      List<Map<String, dynamic>> deliveryReports = [];
      try {
        final deliveryReportsResponse = await _deliveryReportService
            .getDeliveryReportsByTripId(widget.tripId);
        if (deliveryReportsResponse['status'] == 200 &&
            deliveryReportsResponse['data'] is List) {
          deliveryReports = (deliveryReportsResponse['data'] as List)
              .map((item) => _convertToStringKeyMap(item))
              .toList();
        }
      } catch (e) {
        print('Error loading delivery reports: $e');
        // Continue with empty delivery reports rather than failing the whole function
      }

      if (mounted) {
        setState(() {
          _tripDetails = tripDetails;
          _orderDetails = orderDetails;
          _fuelReports = fuelReports;
          _incidentReports = incidentReports;
          _deliveryReports = deliveryReports;
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
    // Removed extra parenthesis
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết chuyến'),
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
          _buildSectionTitle('Thông tin chuyến'),
          _buildDetailCard(_buildTripDetails()),

          // Reports Section with icons
          const SizedBox(height: 20),
          _buildSectionTitle('Báo cáo'),
          _buildReportIconsSection(),

          // Fuel Reports Section (expandable)
          if (_isFuelReportsExpanded) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Báo cáo đổ xăng',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_up),
                  onPressed: () {
                    setState(() {
                      _isFuelReportsExpanded = false;
                    });
                  },
                ),
              ],
            ),
            if (_fuelReports.isNotEmpty)
              ..._fuelReports
                  .map((report) => _buildFuelReportCard(report))
                  .toList()
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Chưa có báo cáo đổ xăng')),
                ),
              ),
          ],

          // Incident Reports Section (expandable)
          if (_isIncidentReportsExpanded) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Báo cáo sự cố',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_up),
                  onPressed: () {
                    setState(() {
                      _isIncidentReportsExpanded = false;
                    });
                  },
                ),
              ],
            ),
            if (_incidentReports.isNotEmpty)
              ..._incidentReports
                  .map((report) => _buildIncidentReportCard(report))
                  .toList()
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Chưa có báo cáo sự cố')),
                ),
              ),
          ],
          
          // Delivery Reports Section (expandable)
          if (_isDeliveryReportsExpanded) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Báo cáo giao hàng',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_up),
                  onPressed: () {
                    setState(() {
                      _isDeliveryReportsExpanded = false;
                    });
                  },
                ),
              ],
            ),
            if (_deliveryReports.isNotEmpty)
              ..._deliveryReports
                  .map((report) => _buildDeliveryReportCard(report))
                  .toList()
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Chưa có báo cáo giao hàng')),
                ),
              ),
          ],

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

  // New method to build the report icons section
  Widget _buildReportIconsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Fuel report icon
            GestureDetector(
              onTap: () {
                setState(() {
                  _isFuelReportsExpanded = !_isFuelReportsExpanded;
                  // Close the other section if this one is opening
                  if (_isFuelReportsExpanded) {
                    _isIncidentReportsExpanded = false;
                    _isDeliveryReportsExpanded = false;
                  }
                });
              },
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isFuelReportsExpanded
                              ? ColorConstants.primaryColor.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_gas_station,
                          color: _isFuelReportsExpanded
                              ? ColorConstants.primaryColor
                              : Colors.grey[700],
                          size: 36,
                        ),
                      ),
                      if (_fuelReports.isNotEmpty)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _fuelReports.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đổ xăng',
                    style: TextStyle(
                      color: _isFuelReportsExpanded
                          ? ColorConstants.primaryColor
                          : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Incident report icon
            GestureDetector(
              onTap: () {
                setState(() {
                  _isIncidentReportsExpanded = !_isIncidentReportsExpanded;
                  // Close the other section if this one is opening
                  if (_isIncidentReportsExpanded) {
                    _isFuelReportsExpanded = false;
                    _isDeliveryReportsExpanded = false;
                  }
                });
              },
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isIncidentReportsExpanded
                              ? ColorConstants.primaryColor.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber,
                          color: _isIncidentReportsExpanded
                              ? ColorConstants.primaryColor
                              : Colors.grey[700],
                          size: 36,
                        ),
                      ),
                      if (_incidentReports.isNotEmpty)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _incidentReports.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sự cố',
                    style: TextStyle(
                      color: _isIncidentReportsExpanded
                          ? ColorConstants.primaryColor
                          : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Delivery report icon - add this section
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDeliveryReportsExpanded = !_isDeliveryReportsExpanded;
                  // Close the other section if this one is opening
                  if (_isDeliveryReportsExpanded) {
                    _isFuelReportsExpanded = false;
                    _isIncidentReportsExpanded = false;
                  }
                });
              },
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isDeliveryReportsExpanded
                              ? ColorConstants.primaryColor.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: _isDeliveryReportsExpanded
                              ? ColorConstants.primaryColor
                              : Colors.grey[700],
                          size: 36,
                        ),
                      ),
                      if (_deliveryReports.isNotEmpty)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _deliveryReports.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Giao hàng',
                    style: TextStyle(
                      color: _isDeliveryReportsExpanded
                          ? ColorConstants.primaryColor
                          : Colors.grey[700],
                      fontWeight: FontWeight.bold,
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
      InfoRow(label: 'Mã chuyến:', value: _tripDetails!['tripId'] ?? 'N/A'),
      FutureBuilder<String>(
        future: _statusService.getStatusName(_tripDetails!['status']),
        builder: (context, snapshot) {
          final statusName =
              snapshot.data ?? _getTripStatusName(_tripDetails!['status']);
          return InfoRow(label: 'Trạng thái:', value: statusName);
        },
      ),
      InfoRow(label: 'Xe kéo:', value: _tripDetails!['tractorId'] ?? 'N/A'),
      InfoRow(label: 'Rơ moóc:', value: _tripDetails!['trailerId'] ?? 'N/A'),
      InfoRow(
        label: 'Thời gian bắt đầu:',
        value:
            DateFormatter.formatDateTimeFromString(_tripDetails!['startTime']),
      ),
      InfoRow(
        label: 'Thời gian kết thúc:',
        value: _tripDetails!['endTime'] != null
            ? DateFormatter.formatDateTimeFromString(_tripDetails!['endTime'])
            : 'Chưa hoàn thành',
      ),
      // Add match information
      InfoRow(
        label: 'Loại ghép:',
        value: _getMatchTypeName(_tripDetails!['matchType']),
      ),
      InfoRow(label: 'Ghép bởi:', value: _tripDetails!['matchBy'] ?? 'N/A'),
      InfoRow(
        label: 'Thời gian ghép:',
        value: _tripDetails!['matchTime'] != null
            ? DateFormatter.formatDateTimeFromString(_tripDetails!['matchTime'])
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

  // Enhanced fuel report card with better styling
  Widget _buildFuelReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with colored accent
          Container(
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.local_gas_station,
                  color: ColorConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Báo cáo đổ xăng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateTimeFromString(report['reportTime']),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ColorConstants.primaryColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${NumberFormatter.formatCurrency(report['fuelCost'])} đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fuel amount with visual indicator
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Số lượng',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${report['refuelAmount']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'lít',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.lightBlue.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Địa điểm',
                              style: TextStyle(
                                color: Colors.lightBlue,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              report['location'] ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Images section
                if (report['fuelReportFiles'] != null &&
                    (report['fuelReportFiles'] as List).isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.photo_library, size: 18, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Hình ảnh',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (report['fuelReportFiles'] as List).length,
                      itemBuilder: (context, index) {
                        final file = report['fuelReportFiles'][index];
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(file['fileUrl']),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                file['fileUrl'],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(Icons.error, color: Colors.red),
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          Icon(Icons.no_photography, color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Không có hình ảnh',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Edit button - only if trip not ended
                if (_tripDetails!['endTime'] == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditFuelReportDialog(report),
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa báo cáo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditFuelReportDialog(Map<String, dynamic> report) {
    final TextEditingController refuelAmountController = TextEditingController(
      text: report['refuelAmount'].toString(),
    );
    final TextEditingController fuelCostController = TextEditingController(
      text: report['fuelCost'].toString(),
    );
    final TextEditingController locationController = TextEditingController(
      text: report['location'] ?? '',
    );

    // Track images to keep or remove
    final List<Map<String, dynamic>> existingFiles =
        List<Map<String, dynamic>>.from(report['fuelReportFiles'] ?? []);
    final Set<String> fileIdsToRemove = {};
    final List<File> newFiles = [];
    
    // Add validation state variables
    bool isRefuelAmountValid = true;
    bool isFuelCostValid = true;
    bool isLocationValid = true;
    
    // Validation error messages
    String refuelAmountError = '';
    String fuelCostError = '';
    String locationError = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            // Validate function
            void validateFields() {
              setState(() {
                // Validate refuel amount (must be a valid number)
                final refuelAmountText = refuelAmountController.text.trim();
                final refuelAmount = double.tryParse(refuelAmountText);
                
                if (refuelAmountText.isEmpty) {
                  isRefuelAmountValid = false;
                  refuelAmountError = 'Vui lòng nhập số lượng xăng';
                } else if (refuelAmount == null) {
                  isRefuelAmountValid = false;
                  refuelAmountError = 'Số lượng xăng phải là số';
                } else if (refuelAmount <= 0) {
                  isRefuelAmountValid = false;
                  refuelAmountError = 'Số lượng xăng phải lớn hơn 0';
                } else {
                  isRefuelAmountValid = true;
                  refuelAmountError = '';
                }
                
                // Validate fuel cost (must be a valid number greater than 0)
                final fuelCostText = fuelCostController.text.trim();
                final fuelCost = double.tryParse(fuelCostText);
                
                if (fuelCostText.isEmpty) {
                  isFuelCostValid = false;
                  fuelCostError = 'Vui lòng nhập chi phí';
                } else if (fuelCost == null) {
                  isFuelCostValid = false;
                  fuelCostError = 'Chi phí phải là số';
                } else if (fuelCost <= 0) {
                  isFuelCostValid = false;
                  fuelCostError = 'Chi phí phải lớn hơn 0';
                } else {
                  isFuelCostValid = true;
                  fuelCostError = '';
                }
                
                // Validate location (cannot be empty)
                if (locationController.text.trim().isEmpty) {
                  isLocationValid = false;
                  locationError = 'Vui lòng nhập địa điểm';
                } else {
                  isLocationValid = true;
                  locationError = '';
                }
              });
            }
            
            return AlertDialog(
              title: const Text('Chỉnh sửa báo cáo đổ xăng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: refuelAmountController,
                      decoration: InputDecoration(
                        labelText: 'Số lượng xăng (lít)',
                        errorText: isRefuelAmountValid ? null : refuelAmountError,
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                      ],
                      onChanged: (value) {
                        if (!isRefuelAmountValid) {
                          validateFields();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fuelCostController,
                      decoration: InputDecoration(
                        labelText: 'Chi phí (VNĐ)',
                        errorText: isFuelCostValid ? null : fuelCostError,
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                      ],
                      onChanged: (value) {
                        if (!isFuelCostValid) {
                          validateFields();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Địa điểm',
                        errorText: isLocationValid ? null : locationError,
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'^\s')), // Prevents spaces at the beginning
                      ],
                      onChanged: (value) {
                        if (!isLocationValid) {
                          validateFields();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Hình ảnh hiện tại:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (existingFiles.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: existingFiles.map((file) {
                          final bool isMarkedForRemoval =
                              fileIdsToRemove.contains(file['fileId']);
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isMarkedForRemoval
                                        ? Colors.red
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Opacity(
                                    opacity: isMarkedForRemoval ? 0.5 : 1.0,
                                    child: Image.network(
                                      file['fileUrl'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isMarkedForRemoval) {
                                        fileIdsToRemove.remove(file['fileId']);
                                      } else {
                                        fileIdsToRemove.add(file['fileId']);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: isMarkedForRemoval
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isMarkedForRemoval
                                          ? Icons.undo
                                          : Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      )
                    else
                      const Text('Không có hình ảnh'),
                    const SizedBox(height: 16),
                    const Text(
                      'Hình ảnh mới:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...newFiles.map((file) {
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      newFiles.remove(file);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),

                        // Add image button
                        GestureDetector(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery);

                            if (image != null) {
                              setState(() {
                                newFiles.add(File(image.path));
                              });
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_a_photo, size: 30),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate all fields before submitting
                    validateFields();
                    
                    // Check if all fields are valid
                    if (!isRefuelAmountValid || !isFuelCostValid || !isLocationValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng kiểm tra lại thông tin nhập'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    try {
                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          contentPadding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: SizedBox(
                            width: 250,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Đang cập nhật báo cáo...'),
                              ],
                            ),
                          ),
                        ),
                      );

                      final double refuelAmount =
                          double.tryParse(refuelAmountController.text.trim()) ?? 0;
                      final double fuelCost =
                          double.tryParse(fuelCostController.text.trim()) ?? 0;

                      final response =
                          await _fuelReportService.updateFuelReport(
                        reportId: report['reportId'],
                        refuelAmount: refuelAmount,
                        fuelCost: fuelCost,
                        location: locationController.text.trim(),
                        fileIdsToRemove: fileIdsToRemove.toList(),
                        addedFiles: newFiles,
                      );

                      // Close loading dialog
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      
                      // Automatically close edit dialog on success
                      if (response['status'] == 200) {
                        // Close edit dialog
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Cập nhật báo cáo thành công')),
                        );
                        // Reload trip details to see updated fuel reports - force refresh
                        _loadDetails();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Lỗi: ${response['message']}')),
                        );
                      }
                    } catch (e) {
                      // Close loading dialog if still open
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildTripStatusHistory() {
    final List<dynamic> histories =
        List.from(_tripDetails!['tripStatusHistories']);

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

  // New method to build incident report card with improved styling
  Widget _buildIncidentReportCard(Map<String, dynamic> report) {
    // Convert incident type to int for badge coloring
    final int incidentTypeValue = int.tryParse(report['type']?.toString() ?? '1') ?? 1;
    final String incidentTypeName = _getIncidentTypeName(incidentTypeValue);
    
    // Get vehicle type info
    final int vehicleTypeValue = int.tryParse(report['vehicleType']?.toString() ?? '1') ?? 1;
    final String vehicleTypeName = vehicleTypeValue == 1 ? 'Xe kéo' : 'Rơ moóc';
    
    // Choose badge color based on type
    final Color typeBadgeColor = incidentTypeValue == 2 ? Colors.orange : Colors.blue;
    final Color vehicleTypeBadgeColor = vehicleTypeValue == 1 ? Colors.green : Colors.purple;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with colored strip or badge showing status and type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: report['status'] == 'Resolved' ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '#${report['reportId']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: report['status'] == 'Resolved' ? Colors.green.shade800 : Colors.orange.shade800,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Vehicle type badge
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: vehicleTypeBadgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: vehicleTypeBadgeColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              vehicleTypeValue == 1 ? Icons.local_shipping : Icons.directions_railway,
                              color: vehicleTypeBadgeColor,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              vehicleTypeName,
                              style: TextStyle(
                                color: vehicleTypeBadgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Incident type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: typeBadgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: typeBadgeColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              incidentTypeValue == 2 ? Icons.swap_horiz : Icons.handyman,
                              color: typeBadgeColor,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              incidentTypeName,
                              style: TextStyle(
                                fontSize: 11,
                                color: typeBadgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  label: 'Loại sự cố:',
                  value: report['incidentType'] ?? 'N/A',
                ),
                InfoRow(label: 'Mô tả:', value: report['description'] ?? 'N/A'),
                InfoRow(
                  label: 'Thời gian xảy ra:',
                  value: DateFormatter.formatDateTimeFromString(
                      report['incidentTime']),
                ),
                InfoRow(label: 'Địa điểm:', value: report['location'] ?? 'N/A'),
                
                // Status with colored indicator
                Row(
                  children: [
                    const Text('Trạng thái:', style: TextStyle(color: Colors.black54)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: report['status'] == 'Resolved' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12), 
                      ),
                      child: Text(
                        (report['status'] == 'Resolved') ? 'Đã giải quyết' : 'Chưa giải quyết',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: report['status'] == 'Resolved' ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),

                if (report['resolutionDetails'] != null &&
                    report['resolutionDetails'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  InfoRow(
                    label: 'Giải pháp:',
                    value: report['resolutionDetails'],
                  ),
                ],

                if (report['handledBy'] != null &&
                    report['handledBy'].toString().isNotEmpty)
                  InfoRow(label: 'Người xử lý:', value: report['handledBy']),

                if (report['handledTime'] != null)
                  InfoRow(
                    label: 'Thời gian xử lý:',
                    value: DateFormatter.formatDateTimeFromString(
                        report['handledTime']),
                  ),

                const SizedBox(height: 12),
                const Text(
                  'Hình ảnh:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (report['incidentReportsFiles'] != null &&
                    (report['incidentReportsFiles'] as List).isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (report['incidentReportsFiles'] as List).length,
                      itemBuilder: (context, index) {
                        final file = report['incidentReportsFiles'][index];
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(file['fileUrl']),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                file['fileUrl'],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(child: Icon(Icons.error)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Không có hình ảnh', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // First row of action buttons - Edit and Resolve
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Edit button - only if not resolved
                    if (report['status'] != 'Resolved')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showEditIncidentDialog(report),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Chỉnh sửa'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    
                    // Resolve button - only if not resolved
                    if (report['status'] != 'Resolved')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showConfirmIncidentDialog(report),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Xác nhận giải quyết'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Add second row of action buttons for billing and resolution images
                // Only show if incident is not resolved yet - remove trip endTime condition
                if (report['status'] != 'Resolved') ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showUploadBillingImagesDialog(report),
                            icon: const Icon(Icons.receipt, size: 18),
                            label: const Text('Tải lên hóa đơn'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.orange),
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showUploadExchangeImagesDialog(report),
                            icon: const Icon(Icons.image, size: 18),
                            label: const Text('Tải hình giải quyết'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.green),
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditIncidentDialog(Map<String, dynamic> report) {
    // Check if incident is already resolved - prevent editing
    if (report['status'] == 'Resolved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể chỉnh sửa sự cố đã được giải quyết'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Initialize controllers with existing values
    final TextEditingController incidentTypeController = TextEditingController(
      text: report['incidentType'] ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: report['description'] ?? '',
    );
    final TextEditingController locationController = TextEditingController(
      text: report['location'] ?? '',
    );

    // Initialize incident resolution type (default to 1 if not present)
    // int selectedIncidentType = report['type'] != null ? 
    //     int.tryParse(report['type'].toString()) ?? 1 : 1;
        
    // Initialize vehicle type (default to 1 - tractor if not present)
    int selectedVehicleType = report['vehicleType'] != null ? 
        int.tryParse(report['vehicleType'].toString()) ?? 1 : 1;

    // Track images to keep or remove
    final List<Map<String, dynamic>> existingFiles =
        List<Map<String, dynamic>>.from(report['incidentReportsFiles'] ?? []);
    final Set<String> fileIdsToRemove = {};
    final List<File> newFiles = [];
    
    // Add validation state variables
    bool isIncidentTypeValid = true;
    bool isDescriptionValid = true;
    bool isLocationValid = true;
    
    // Validation error messages
    String incidentTypeError = '';
    String descriptionError = '';
    String locationError = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            // Validate function
            void validateFields() {
              setState(() {
                // Validate incident type
                if (incidentTypeController.text.trim().isEmpty) {
                  isIncidentTypeValid = false;
                  incidentTypeError = 'Vui lòng nhập loại sự cố';
                } else if (incidentTypeController.text.trim().length < 3) {
                  isIncidentTypeValid = false;
                  incidentTypeError = 'Loại sự cố quá ngắn';
                } else {
                  isIncidentTypeValid = true;
                  incidentTypeError = '';
                }
                
                // Validate description
                if (descriptionController.text.trim().isEmpty) {
                  isDescriptionValid = false;
                  descriptionError = 'Vui lòng nhập mô tả sự cố';
                } else if (descriptionController.text.trim().length < 10) {
                  isDescriptionValid = false;
                  descriptionError = 'Mô tả cần ít nhất 10 ký tự';
                } else {
                  isDescriptionValid = true;
                  descriptionError = '';
                }
                
                // Validate location
                if (locationController.text.trim().isEmpty) {
                  isLocationValid = false;
                  locationError = 'Vui lòng nhập địa điểm';
                } else {
                  isLocationValid = true;
                  locationError = '';
                }
              });
            }
            
            return AlertDialog(
              title: const Text('Chỉnh sửa báo cáo sự cố'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Type Selector
                    const Text(
                      'Loại phương tiện:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = 1; // Tractor
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedVehicleType == 1 
                                      ? ColorConstants.primaryColor 
                                      : Colors.grey.shade400,
                                  width: selectedVehicleType == 1 ? 2 : 1,
                                ),
                                color: selectedVehicleType == 1
                                    ? ColorConstants.primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    color: selectedVehicleType == 1
                                        ? ColorConstants.primaryColor
                                        : Colors.grey.shade600,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Xe kéo',
                                    style: TextStyle(
                                      fontWeight: selectedVehicleType == 1
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: selectedVehicleType == 1
                                          ? ColorConstants.primaryColor
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = 2; // Trailer
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedVehicleType == 2
                                      ? ColorConstants.primaryColor
                                      : Colors.grey.shade400,
                                  width: selectedVehicleType == 2 ? 2 : 1,
                                ),
                                color: selectedVehicleType == 2
                                    ? ColorConstants.primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.directions_railway,
                                    color: selectedVehicleType == 2
                                        ? ColorConstants.primaryColor
                                        : Colors.grey.shade600,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rơ moóc',
                                    style: TextStyle(
                                      fontWeight: selectedVehicleType == 2
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: selectedVehicleType == 2
                                          ? ColorConstants.primaryColor
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: incidentTypeController,
                      // Add input formatter to prevent leading spaces
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'^\s')), // Prevents spaces at the beginning
                      ],
                      decoration: InputDecoration(
                        labelText: 'Loại sự cố',
                        errorText: isIncidentTypeValid ? null : incidentTypeError,
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        if (!isIncidentTypeValid) {
                          validateFields();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Continue with the rest of the form
                    TextField(
                      controller: descriptionController,
                      // Add input formatter to prevent leading spaces
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'^\s')), // Prevents spaces at the beginning
                      ],
                      decoration: InputDecoration(
                        labelText: 'Mô tả',
                        errorText: isDescriptionValid ? null : descriptionError,
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        if (!isDescriptionValid) {
                          validateFields();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      // Add input formatter to prevent leading spaces
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'^\s')), // Prevents spaces at the beginning
                      ],
                      decoration: InputDecoration(
                        labelText: 'Địa điểm',
                        errorText: isLocationValid ? null : locationError,
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        if (!isLocationValid) {
                          validateFields();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Hình ảnh hiện tại:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (existingFiles.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: existingFiles.map((file) {
                          final bool isMarkedForRemoval =
                              fileIdsToRemove.contains(file['fileId']);
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isMarkedForRemoval
                                        ? Colors.red
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Opacity(
                                    opacity: isMarkedForRemoval ? 0.5 : 1.0,
                                    child: Image.network(
                                      file['fileUrl'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isMarkedForRemoval) {
                                        fileIdsToRemove.remove(file['fileId']);
                                      } else {
                                        fileIdsToRemove.add(file['fileId']);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: isMarkedForRemoval
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isMarkedForRemoval
                                          ? Icons.undo
                                          : Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      )
                    else
                      const Text('Không có hình ảnh'),
                    const SizedBox(height: 16),
                    const Text(
                      'Thêm hình ảnh mới:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...newFiles.map((file) {
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      newFiles.remove(file);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),

                        // Add image button
                        GestureDetector(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery);

                            if (image != null) {
                              setState(() {
                                newFiles.add(File(image.path));
                              });
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_a_photo, size: 30),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate fields before submission
                    validateFields();
                    
                    // Check if all fields are valid
                    if (!isIncidentTypeValid || !isDescriptionValid || !isLocationValid) {
                      // Only show the error SnackBar if there are validation errors not already
                      // displayed in the form fields
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng kiểm tra lại thông tin nhập'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    try {
                      // Trim input values before submission to ensure no leading/trailing spaces
                      final String trimmedIncidentType = incidentTypeController.text.trim();
                      final String trimmedDescription = descriptionController.text.trim();
                      final String trimmedLocation = locationController.text.trim();
                      
                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          content: const Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text('Đang cập nhật...'),
                            ],
                          ),
                        ),
                      );

                      final response = await _incidentReportService.updateIncidentReport(
                        reportId: report['reportId'],
                        incidentType: trimmedIncidentType.isNotEmpty ? 
                            trimmedIncidentType : null,
                        description: trimmedDescription.isNotEmpty ? 
                            trimmedDescription : null,
                        location: trimmedLocation.isNotEmpty ? 
                            trimmedLocation : null,
                        fileIdsToRemove: fileIdsToRemove.isNotEmpty ? 
                            fileIdsToRemove.toList() : null,
                        addedFiles: newFiles.isNotEmpty ? newFiles : null,
                        vehicleType: selectedVehicleType, // Add vehicle type to the update call
                      );

                      // Close loading dialog
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      
                      if (response['status'] == 1 || response['status'] == 200) {
                        // Automatically close the edit dialog on success
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cập nhật báo cáo sự cố thành công'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Reload data to show updated reports - force refresh
                        _loadDetails();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: ${response['message']}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Close loading dialog if still open
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add method to show incident confirmation dialog
  void _showConfirmIncidentDialog(Map<String, dynamic> report) {
    // Check if incident is already resolved
    if (report['status'] == 'Resolved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sự cố đã được giải quyết'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final TextEditingController resolutionController = TextEditingController();
    final List<File> resolutionImages = []; // Type 2 (resolution proof)
    
    // Add validation state variables
    bool isResolutionValid = true;
    String resolutionError = '';

    // Open dialog with simple content first, then expand it with setState
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            // Add validation function
            void validateResolution() {
              setDialogState(() {
                if (resolutionController.text.trim().isEmpty) {
                  isResolutionValid = false;
                  resolutionError = 'Vui lòng nhập chi tiết giải quyết';
                } else if (resolutionController.text.trim().length < 10) {
                  isResolutionValid = false;
                  resolutionError = 'Chi tiết giải quyết cần ít nhất 10 ký tự';
                } else {
                  isResolutionValid = true;
                  resolutionError = '';
                }
              });
            }
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Title
                      const Text(
                        'Xác nhận giải quyết sự cố',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Make content scrollable to prevent overflow
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Resolution details input with validation
                              TextField(
                                controller: resolutionController,
                                decoration: InputDecoration(
                                  labelText: 'Chi tiết giải quyết',
                                  hintText: 'Mô tả cách giải quyết sự cố',
                                  errorText: isResolutionValid ? null : resolutionError,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: ColorConstants.primaryColor, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                maxLines: 3,
                                // Add input formatter to prevent leading spaces
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(RegExp(r'^\s')), // Prevents spaces at the beginning
                                ],
                                onChanged: (value) {
                                  if (!isResolutionValid) {
                                    validateResolution();
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Existing images section
                              const Text(
                                'Hình ảnh hiện tại:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),

                              if (report['incidentReportsFiles'] != null &&
                                  (report['incidentReportsFiles'] as List)
                                      .isNotEmpty)
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        (report['incidentReportsFiles'] as List)
                                            .length,
                                    itemBuilder: (context, index) {
                                      final file =
                                          report['incidentReportsFiles'][index];
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 80,
                                        height: 80,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            file['fileUrl'],
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            },
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Center(
                                                    child: Icon(Icons.error)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                const Text('Không có hình ảnh'),

                              const SizedBox(height: 16),                        
                            ],
                          ),
                        ),
                      ),

                      // Dialog buttons
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            // Only enable if incident hasn't been resolved yet
                            onPressed: report['status'] == 'Resolved' 
                                ? null 
                                : () {
                                    // Validate resolution before submitting
                                    validateResolution();
                                    
                                    if (!isResolutionValid) {
                                      // Resolution validation errors are already shown in the input field
                                      return;
                                    }
                                    
                                    _confirmIncidentResolution(
                                      context,
                                      report,
                                      resolutionController.text,
                                      resolutionImages,
                                    );
                                  },
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to build image preview
  Widget _buildImagePreview(
      File file, Color borderColor, VoidCallback onRemove) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to handle confirmation action - modified to make images optional
  void _confirmIncidentResolution(
    BuildContext context,
    Map<String, dynamic> report,
    String resolutionDetails,
    List<File> resolutionImages,
  ) async {
    // Double-check if incident is already resolved
    if (report['status'] == 'Resolved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sự cố đã được giải quyết'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Show a simple loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Đang xử lý...")
              ],
            ),
          ),
        ),
      );
      
      // Call the API endpoint to set the incident as resolved
      // Images are now optional - only upload if there are any
      final response = await _incidentReportService.resolveIncidentReport(
        reportId: report['reportId'],
        resolutionDetails: resolutionDetails,
        resolutionImages: resolutionImages.isNotEmpty ? resolutionImages : null,
      );

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Close confirmation dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response['status'] == 1 || response['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác nhận giải quyết sự cố thành công', style: TextStyle(color: Colors.green))),
        );
        // Reload trip details
        _loadDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${response['message']}')),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  // New method to show dialog for uploading billing images
  void _showUploadBillingImagesDialog(Map<String, dynamic> report) {
    // Check if incident is already resolved
    if (report['status'] == 'Resolved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải hình ảnh khi sự cố đã được giải quyết'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final List<File> billingImages = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Title
                      const Text(
                        'Tải lên hóa đơn sự cố',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Make content scrollable to prevent overflow
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Show selected billing images
                              const Text(
                                'Hình ảnh hóa đơn:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...billingImages
                                      .map((file) => _buildImagePreview(
                                          file, Colors.orange, () {
                                        setDialogState(() {
                                          billingImages.remove(file);
                                        });
                                      }))
                                      .toList(),

                                  // Add image button
                                  GestureDetector(
                                    onTap: () async {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(
                                          source: ImageSource.gallery);
                                      if (image != null) {
                                        setDialogState(() {
                                          billingImages.add(File(image.path));
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 80,
                                      height: 80,
decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.orange, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.add_a_photo,
                                          size: 30, color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Text(
                                'Lưu ý: Vui lòng tải lên các hình ảnh hóa đơn liên quan đến sự cố này.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Add warning message about refunds
                              const Text(
                                'QUAN TRỌNG: Nếu hình ảnh không phù hợp hoặc không rõ ràng, bạn sẽ không được hoàn tiền!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dialog buttons
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: billingImages.isEmpty
                                ? null // Disable if no images selected
                                : () => _uploadBillingImages(
                                      context,
                                      report['reportId'],
                                      billingImages,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: const Text(
                              'Tải lên',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Method to upload billing images
  Future<void> _uploadBillingImages(
    BuildContext context,
    String reportId,
    List<File> images,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Đang tải lên hóa đơn..."),
              ],
            ),
          ),
        ),
      );

      // Upload the images
      final response = await _incidentReportService.uploadBillingImages(
        reportId: reportId,
        images: images,
      );

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Close upload dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show result message
      if (response['status'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tải lên hóa đơn thành công')),
        );
        // Reload data to show updated images
        _loadDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${response['message']}')),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  // New method to show dialog for uploading exchange/resolution images
  void _showUploadExchangeImagesDialog(Map<String, dynamic> report) {
    // Check if incident is already resolved
    if (report['status'] == 'Resolved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải hình ảnh khi sự cố đã được giải quyết'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final List<File> exchangeImages = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Title
                      const Text(
                        'Tải lên hình ảnh giải quyết',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Make content scrollable to prevent overflow
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Show selected exchange images
                              const Text(
                                'Hình ảnh giải quyết:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...exchangeImages
                                      .map((file) => _buildImagePreview(
                                          file, Colors.green, () {
                                        setDialogState(() {
                                          exchangeImages.remove(file);
                                        });
                                      }))
                                      .toList(),

                                  // Add image button
                                  GestureDetector(
                                    onTap: () async {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(
                                          source: ImageSource.gallery);
                                      if (image != null) {
                                        setDialogState(() {
                                          exchangeImages.add(File(image.path));
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.green, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.add_a_photo,
                                          size: 30, color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Text(
                                'Lưu ý: Vui lòng tải lên các hình ảnh cho thấy đã giải quyết sự cố.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Add warning message about refunds
                              const Text(
                                'QUAN TRỌNG: Nếu hình ảnh không phù hợp hoặc không rõ ràng, bạn sẽ không được hoàn tiền!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dialog buttons
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: exchangeImages.isEmpty
                                ? null // Disable if no images selected
                                : () => _uploadExchangeImages(
                                      context,
                                      report['reportId'],
                                      exchangeImages,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: const Text(
                              'Tải lên',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Method to upload exchange/resolution images
  Future<void> _uploadExchangeImages(
    BuildContext context,
    String reportId,
    List<File> images,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Đang tải lên hình ảnh giải quyết..."),
              ],
            ),
          ),
        ),
      );

      // Upload the images
      final response = await _incidentReportService.uploadExchangeImages(
        reportId: reportId,
        images: images,
      );

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Close upload dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show result message
      if (response['status'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tải lên hình ảnh giải quyết thành công')),
        );
        // Reload data to show updated images
        _loadDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${response['message']}')),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  // Helper method to convert incident type code to readable text
  String _getIncidentTypeName(dynamic incidentType) {
    if (incidentType == null) return 'N/A';
    
    switch (int.tryParse(incidentType.toString()) ?? 0) {
      case 1:
        return 'Xử lý tại chỗ';
      case 2:
        return 'Thay xe';
      case 3:
        return 'Thay xe cả ngày';
      default:
        return 'Không xác định';
    }
  }
  
  // Enhanced delivery report card with better styling
  Widget _buildDeliveryReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with colored accent
          Container(
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Báo cáo giao hàng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateTimeFromString(report['reportTime']),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Text(
                    report['reportBy'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notes section with decorative container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notes, color: Colors.grey, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Ghi chú',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report['notes'] ?? 'Không có ghi chú',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: report['notes'] != null ? FontWeight.w500 : FontWeight.normal,
                          fontStyle: report['notes'] != null ? FontStyle.normal : FontStyle.italic,
                          color: report['notes'] != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Images section
                if (report['deliveryReportsFiles'] != null &&
                    (report['deliveryReportsFiles'] as List).isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.photo_library, size: 18, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Hình ảnh xác nhận',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (report['deliveryReportsFiles'] as List).length,
                      itemBuilder: (context, index) {
                        final file = report['deliveryReportsFiles'][index];
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(file['fileUrl']),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      file['fileUrl'],
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(
                                            child: Icon(Icons.error, color: Colors.red),
                                          ),
                                    ),
                                  ),
                                ),
                                // Add a small badge showing the file type if available
                                if (file['fileType'] != null)
                                  Positioned(
                                    right: 5,
                                    bottom: 5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        file['fileType'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          Icon(Icons.no_photography, color: Colors.grey.shade400, size: 40),
                          const SizedBox(height: 8),
                          const Text(
                            'Không có hình ảnh xác nhận giao hàng',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
}

Map<String, dynamic> _convertToStringKeyMap(dynamic item) {
  if (item is Map) {
    return item.map<String, dynamic>((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _convertToStringKeyMap(value));
      } else if (value is List) {
        return MapEntry(key.toString(), _convertListItems(value));
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }
  return <String, dynamic>{};
}

List<dynamic> _convertListItems(List items) {
  return items.map((item) {
    if (item is Map) {
      return _convertToStringKeyMap(item);
    } else if (item is List) {
      return _convertListItems(item);
    } else {
      return item;
    }
  }).toList();
}
