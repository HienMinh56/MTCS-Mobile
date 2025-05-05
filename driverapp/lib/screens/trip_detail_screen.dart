import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/trip_detail/trip_info_section.dart';
import '../components/trip_detail/report_icons_section.dart';
import '../components/trip_detail/fuel_report_card.dart';
import '../components/trip_detail/incident_report_card.dart';
import '../components/trip_detail/delivery_report_card.dart';
import '../components/trip_detail/trip_status_history_section.dart';
import '../components/trip_detail/edit_fuel_report_dialog.dart';
import '../components/trip_detail/edit_incident_report_dialog.dart'; // New import for incident report dialog
import '../components/trip_detail/billing_images_dialog.dart'; // New import for billing images dialog
import '../components/trip_detail/resolve_incident_dialog.dart'; // New import for resolve incident dialog
import '../components/trip_detail/exchange_images_dialog.dart'; // Import ExchangeImagesDialog
import '../models/trip.dart';
import '../services/trip_service.dart';
import '../services/order_service.dart';
import '../services/delivery_status_service.dart';
import '../services/fuel_report_service.dart';
import '../services/incident_report_service.dart';
import '../services/delivery_report_service.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  _TripDetailScreenState createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TripService _tripService = TripService();
  final OrderService _orderService = OrderService();
  final DeliveryStatusService _statusService = DeliveryStatusService();
  final FuelReportService _fuelReportService = FuelReportService();
  final IncidentReportService _incidentReportService = IncidentReportService();
  final DeliveryReportService _deliveryReportService = DeliveryReportService();

  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _tripDetails;
  Map<String, dynamic>? _orderDetails;
  List<Map<String, dynamic>> _fuelReports = [];
  List<Map<String, dynamic>> _incidentReports = [];
  List<Map<String, dynamic>> _deliveryReports = [];

  // Add state variables to track which report type is expanded
  bool _isFuelReportsExpanded = false;
  bool _isIncidentReportsExpanded = false;
  bool _isDeliveryReportsExpanded = false;

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

  void _handleReportTypeSelected(int reportType) {
    setState(() {
      // Reset all section expanded states
      _isFuelReportsExpanded = reportType == 0 ? !_isFuelReportsExpanded : false;
      _isIncidentReportsExpanded = reportType == 1 ? !_isIncidentReportsExpanded : false;
      _isDeliveryReportsExpanded = reportType == 2 ? !_isDeliveryReportsExpanded : false;
    });
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

  // Hàm mới sử dụng component EditFuelReportDialog
  void _showEditFuelReportDialog(Map<String, dynamic> report) {
    EditFuelReportDialogHelper.show(
      context: context,
      report: report,
      onReportUpdated: _loadDetails,
      onShowFullScreenImage: _showFullScreenImage,
    );
  }

  void _showEditIncidentDialog(Map<String, dynamic> report) {
    EditIncidentReportDialogHelper.show(
      context: context,
      report: report,
      onReportUpdated: _loadDetails,
      onShowFullScreenImage: _showFullScreenImage,
    );
  }

  void _showConfirmIncidentDialog(Map<String, dynamic> report) {
    ResolveIncidentDialogHelper.show(
      context: context,
      report: report,
      onReportResolved: _loadDetails,
      // onShowFullScreenImage: _showFullScreenImage,
    );
  }

  void _showBillingImagesDialog(Map<String, dynamic> report) {
    BillingImagesDialogHelper.show(
      context: context,
      reportId: report['reportId'],
      onImagesUploaded: _loadDetails,
    );
  }

  // Add exchange images to an incident report
  Future<void> _handleAddExchangeImages(Map<String, dynamic> report) async {
    ExchangeImagesDialogHelper.show(
      context: context,
      reportId: report['reportId'],
      onImagesUploaded: _loadDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
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

    // Check if trip is ended
    final bool isTripEnded = _tripDetails!['endTime'] != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Thông tin chuyến'),
          
          // Trip Info Section
          TripInfoSection(
            tripDetails: _tripDetails!,
            orderDetails: _orderDetails!,
            statusService: _statusService,
          ),

          // Reports Section with icons
          const SizedBox(height: 20),
          _buildSectionTitle('Báo cáo'),
          
          // Report Icons Section
          ReportIconsSection(
            fuelReportsCount: _fuelReports.length,
            incidentReportsCount: _incidentReports.length,
            deliveryReportsCount: _deliveryReports.length,
            isFuelReportsExpanded: _isFuelReportsExpanded,
            isIncidentReportsExpanded: _isIncidentReportsExpanded,
            isDeliveryReportsExpanded: _isDeliveryReportsExpanded,
            onReportTypeSelected: _handleReportTypeSelected,
          ),

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
              ..._fuelReports.map((report) => FuelReportCard(
                    report: report,
                    isTripEnded: isTripEnded,
                    onShowFullImage: (file) => _showFullScreenImage(file['fileUrl']),
                    // Chỉ cho phép cập nhật báo cáo nhiên liệu khi chuyến chưa kết thúc
                    onEditReport: isTripEnded ? null : _showEditFuelReportDialog,
                  )).toList()
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
              ..._incidentReports.map((report) => IncidentReportCard(
                    report: report,
                    isTripEnded: isTripEnded,
                    onShowFullImage: (file) => _showFullScreenImage(file),
                    // Chỉ cho phép cập nhật báo cáo sự cố khi chưa được giải quyết và chuyến chưa kết thúc
                    onEditReport:  report['status'] == 'Resolved' ? null : _showEditIncidentDialog,
                    // Chỉ cho phép giải quyết sự cố khi chưa được giải quyết và chuyến chưa kết thúc
                    onResolveReport:  report['status'] == 'Resolved' ? null : _showConfirmIncidentDialog,
                    // Thêm callback để tải lên ảnh hóa đơn cho sự cố
                    onAddBillingImages:  report['status'] == 'Resolved' ? null : _showBillingImagesDialog,
                    // Thêm callback để tải lên ảnh trao đổi cho sự cố
                    onAddExchangeImages:  report['status'] == 'Resolved' ? null : _handleAddExchangeImages,
                  )).toList()
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
              ..._deliveryReports.map((report) => DeliveryReportCard(
                    report: report,
                    isTripEnded: isTripEnded,
                    onShowFullImage: (file) => _showFullScreenImage(file),
                    // Không cho phép cập nhật báo cáo giao hàng trong mọi trường hợp
                    onEditReport: null,
                  )).toList()
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

          // Trip Status History Section
          if (_tripDetails!['tripStatusHistories'] != null &&
              (_tripDetails!['tripStatusHistories'] as List).isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionTitle('Lịch sử trạng thái'),
            TripStatusHistorySection(
              statusHistories: _tripDetails!['tripStatusHistories'],
              statusService: _statusService,
            ),
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
}
