import 'package:flutter/material.dart';
import 'package:driverapp/services/trip_service.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/services/delivery_status_service.dart';
import 'package:driverapp/services/fuel_report_service.dart';
import 'package:driverapp/services/incident_report_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/incident_confirmation_dialog.dart'; // Add this import
import 'package:image_picker/image_picker.dart';
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
  
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _tripDetails;
  Map<String, dynamic>? _orderDetails;
  List<dynamic> _fuelReports = [];
  List<dynamic> _incidentReports = [];

  // Add state variables to track which report type is expanded
  bool _isFuelReportsExpanded = false;
  bool _isIncidentReportsExpanded = false;

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
      final response = await _tripService.getTripDetail(widget.tripId);
      
      // Extract trip from the data array in the response
      if (response['status'] == 200 && response['data'] is List && response['data'].isNotEmpty) {
        final tripDetails = response['data'][0];
        
        // Load order details
        final orderResponse = await _orderService.getOrderByTripId(widget.tripId);
        final orderDetails = orderResponse['data'] ?? {};
        
        // Load fuel reports - add more robust error handling
        List<dynamic> fuelReports = [];
        try {
          final fuelReportsResponse = await _fuelReportService.getFuelReportsByTripId(widget.tripId);
          if (fuelReportsResponse['status'] == 200 && fuelReportsResponse['data'] is List) {
            fuelReports = fuelReportsResponse['data'];
          }
        } catch (e) {
          print('Error loading fuel reports: $e');
          // Continue with empty fuel reports rather than failing the whole function
        }
        
        // Load incident reports - add more robust error handling
        List<dynamic> incidentReports = [];
        try {
          final incidentReportsResponse = await _incidentReportService.getIncidentReportsByTripId(widget.tripId);
          // Check for both possible success status codes (1 and 200)
          if ((incidentReportsResponse['status'] == 1 || incidentReportsResponse['status'] == 200) && 
              incidentReportsResponse['data'] is List) {
            incidentReports = incidentReportsResponse['data'];
          }
        } catch (e) {
          print('Error loading incident reports: $e');
          // Continue with empty incident reports rather than failing the whole function
        }

        if (mounted) {
          setState(() {
            _tripDetails = tripDetails;
            _orderDetails = orderDetails;
            _fuelReports = fuelReports;
            _incidentReports = incidentReports;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Không tìm thấy dữ liệu trip hoặc định dạng dữ liệu không đúng');
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
  Widget build(BuildContext context) {  // Removed extra parenthesis
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
              ..._fuelReports.map((report) => _buildFuelReportCard(report)).toList()
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ..._incidentReports.map((report) => _buildIncidentReportCard(report)).toList()
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Chưa có báo cáo sự cố')),
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
    
    switch(matchType) {
      case 1: return 'Tự động';
      case 2: return 'Thủ công';
      default: return 'Loại $matchType';
    }
  }

  // New method to build fuel report card
  Widget _buildFuelReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRow(label: 'Số lượng xăng:', value: '${report['refuelAmount']} lít'),
            InfoRow(
              label: 'Chi phí:', 
              value: '${NumberFormatter.formatCurrency(report['fuelCost'])} VNĐ',
            ),
            InfoRow(label: 'Địa điểm:', value: report['location'] ?? 'N/A'),
            InfoRow(
              label: 'Thời gian báo cáo:', 
              value: DateFormatter.formatDateTimeFromString(report['reportTime']),
            ),
            
            const SizedBox(height: 12),
            const Text(
              'Hình ảnh:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (report['fuelReportFiles'] != null && (report['fuelReportFiles'] as List).isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (report['fuelReportFiles'] as List).length,
                  itemBuilder: (context, index) {
                    final file = report['fuelReportFiles'][index];
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(file['fileUrl']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            file['fileUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
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
              const Text('Không có hình ảnh'),
            
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _tripDetails!['endTime'] != null ? null : () => _showEditFuelReportDialog(report),
                child: Text(
                  'Chỉnh sửa báo cáo',
                  style: TextStyle(
                    color: _tripDetails!['endTime'] != null 
                        ? Colors.grey[600] 
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
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
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
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
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chỉnh sửa báo cáo đổ xăng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: refuelAmountController,
                      decoration: const InputDecoration(labelText: 'Số lượng xăng (lít)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: fuelCostController,
                      decoration: const InputDecoration(labelText: 'Chi phí (VNĐ)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Địa điểm'),
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
                          final bool isMarkedForRemoval = fileIdsToRemove.contains(file['fileId']);
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isMarkedForRemoval ? Colors.red : Colors.grey,
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
                                      color: isMarkedForRemoval ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isMarkedForRemoval ? Icons.undo : Icons.close,
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
                                  border: Border.all(color: Colors.grey, width: 2),
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
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            
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
                      
                      final double refuelAmount = double.tryParse(refuelAmountController.text) ?? 0;
                      final double fuelCost = double.tryParse(fuelCostController.text) ?? 0;
                      
                      final response = await _fuelReportService.updateFuelReport(
                        reportId: report['reportId'],
                        refuelAmount: refuelAmount,
                        fuelCost: fuelCost,
                        location: locationController.text,
                        fileIdsToRemove: fileIdsToRemove.toList(),
                        addedFiles: newFiles,
                      );
                      
                      // Close loading dialog
                      Navigator.pop(context);
                      // Close edit dialog
                      Navigator.pop(context);
                      
                      if (response['status'] == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cập nhật báo cáo thành công')),
                        );
                        // Reload trip details to see updated fuel reports
                        _loadDetails();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: ${response['message']}')),
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

  // New method to build incident report card
  Widget _buildIncidentReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRow(label: 'Mã báo cáo:', value: report['reportId'] ?? 'N/A'),
            InfoRow(label: 'Loại sự cố:', value: report['incidentType'] ?? 'N/A'),
            InfoRow(label: 'Mô tả:', value: report['description'] ?? 'N/A'),
            InfoRow(
              label: 'Thời gian xảy ra:', 
              value: DateFormatter.formatDateTimeFromString(report['incidentTime']),
            ),
            InfoRow(label: 'Địa điểm:', value: report['location'] ?? 'N/A'),
            InfoRow(label: 'Trạng thái:', value: report['status'] ?? 'N/A'),
            
            if (report['resolutionDetails'] != null && report['resolutionDetails'].toString().isNotEmpty)
              InfoRow(label: 'Giải pháp:', value: report['resolutionDetails']),
            
            if (report['handledBy'] != null && report['handledBy'].toString().isNotEmpty)
              InfoRow(label: 'Người xử lý:', value: report['handledBy']),
            
            if (report['handledTime'] != null)
              InfoRow(
                label: 'Thời gian xử lý:', 
                value: DateFormatter.formatDateTimeFromString(report['handledTime']),
              ),
            
            const SizedBox(height: 12),
            const Text(
              'Hình ảnh:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (report['incidentReportsFiles'] != null && (report['incidentReportsFiles'] as List).isNotEmpty)
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            file['fileUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
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
              const Text('Không có hình ảnh'),
              
            // Add confirm button if incident is not resolved and trip is not ended
            if (report['status'] != 'Resolved' && _tripDetails!['endTime'] == null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => _showConfirmIncidentDialog(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor,
                    ),
                    child: const Text(
                      'Xác nhận đã giải quyết',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Add method to show incident confirmation dialog
  void _showConfirmIncidentDialog(Map<String, dynamic> report) {
    final TextEditingController resolutionController = TextEditingController();
    final List<File> resolutionImages = []; // Type 2 (resolution proof)
    
    // Open dialog with simple content first, then expand it with setState
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
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Make content scrollable to prevent overflow
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Resolution details input
                              TextField(
                                controller: resolutionController,
                                decoration: const InputDecoration(
                                  labelText: 'Chi tiết giải quyết',
                                  hintText: 'Mô tả cách giải quyết sự cố',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              
                              // Existing images section
                              const Text(
                                'Hình ảnh hiện tại:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              
                              if (report['incidentReportsFiles'] != null && 
                                  (report['incidentReportsFiles'] as List).isNotEmpty)
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: (report['incidentReportsFiles'] as List).length,
                                    itemBuilder: (context, index) {
                                      final file = report['incidentReportsFiles'][index];
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 80,
                                        height: 80,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            file['fileUrl'],
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(child: CircularProgressIndicator());
                                            },
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Center(child: Icon(Icons.error)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                const Text('Không có hình ảnh'),

                              const SizedBox(height: 16),
                              
                              // Resolution images (Type 2)
                              const Text(
                                'Hình ảnh kết quả giải quyết:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...resolutionImages.map((file) => _buildImagePreview(
                                    file, 
                                    ColorConstants.primaryColor,
                                    () {
                                      setDialogState(() {
                                        resolutionImages.remove(file);
                                      });
                                    }
                                  )).toList(),
                                  
                                  // Add image button
                                  GestureDetector(
                                    onTap: () async {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                      if (image != null) {
                                        setDialogState(() {
                                          resolutionImages.add(File(image.path));
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: ColorConstants.primaryColor,
                                          width: 2
                                        ),
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
                            onPressed: () => _confirmIncidentResolution(
                              context,
                              report,
                              resolutionController.text,
                              resolutionImages,
                            ),
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
  Widget _buildImagePreview(File file, Color borderColor, VoidCallback onRemove) {
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
  
  // Helper method to handle confirmation action
  void _confirmIncidentResolution(
    BuildContext context,
    Map<String, dynamic> report,
    String resolutionDetails,
    List<File> resolutionImages,
  ) async {
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
      
      final now = DateTime.now();
      
      // Make API call with resolution images - type is handled within the API
      final response = await _incidentReportService.updateIncidentReport(
        reportId: report['reportId'],
        tripId: widget.tripId,
        incidentType: report['incidentType'] ?? '',
        description: report['description'] ?? '',
        location: report['location'] ?? '',
        status: 'Resolved',
        resolutionDetails: resolutionDetails,
        handledBy: 'Driver',
        handledTime: now,
        resolutionImages: resolutionImages,
        type: 2, // General type for the report
      );
      
      _handleApiResponse(context, response);
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
  
  // Helper method to handle API response
  void _handleApiResponse(BuildContext context, Map<String, dynamic> response) {
    // Close loading dialogs
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    // Close confirmation dialog
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (response['status'] == 1 || response['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác nhận giải quyết sự cố thành công')),
      );
      // Reload trip details
      _loadDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${response['message']}')),
      );
    }
  }
  
  // Helper method to handle API response
  void _handleIncidentUpdateResponse(BuildContext context, Map<String, dynamic> response) {
    // Close the loading dialog if it's still open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    // Close the confirmation dialog if it's still open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (response['status'] == 1 || response['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác nhận giải quyết sự cố thành công')),
      );
      // Reload trip details
      _loadDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${response['message']}')),
      );
    }
  }
}
