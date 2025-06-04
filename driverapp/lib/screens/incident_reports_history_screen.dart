import 'package:flutter/material.dart';
import 'package:driverapp/models/incident_report_model.dart';
import 'package:driverapp/services/report_service.dart';
import 'package:driverapp/screens/incident_report_history_detail_screen.dart';
import 'package:driverapp/components/report_card.dart';
import 'package:driverapp/utils/status_utils.dart';
import 'package:intl/intl.dart';

class IncidentReportsScreen extends StatefulWidget {
  final String userId;

  const IncidentReportsScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<IncidentReportsScreen> createState() => _IncidentReportsScreenState();
}

class _IncidentReportsScreenState extends State<IncidentReportsScreen> {
  final ReportService _reportService = ReportService();
  late Future<List<IncidentReport>> _incidentReportsFuture;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  // Add filter state variables
  String _locationFilter = '';
  String _tripIdFilter = '';
  String _statusFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterVisible = false;

  // Danh sách các status có thể có - chỉ 2 trạng thái (bằng tiếng Việt)
  final List<String> _availableStatuses = ['Đang xử lý', 'Đã xử lý'];

  // Map tiếng Việt sang tiếng Anh để lọc chính xác
  final Map<String, String> _statusMap = {
    'Đang xử lý': 'Handling',
    'Đã xử lý': 'Resolved'
  };

  @override
  void initState() {
    super.initState();
    _loadIncidentReports();
  }

  Future<void> _loadIncidentReports() async {
    setState(() {
      _incidentReportsFuture = _reportService.getIncidentReports(widget.userId);
    });
  }

  void _clearAllFilters() {
    setState(() {
      _locationFilter = '';
      _tripIdFilter = '';
      _statusFilter = '';
      _startDate = null;
      _endDate = null;
    });
  }

  // Add filtering function
  List<IncidentReport> _getFilteredReports(List<IncidentReport> reports) {
    // Lọc báo cáo theo các tiêu chí
    final filteredResults = reports.where((report) {
      // Filter by location
      if (_locationFilter.isNotEmpty &&
          !report.location
              .toLowerCase()
              .contains(_locationFilter.toLowerCase())) {
        return false;
      }

      // Filter by trip ID
      if (_tripIdFilter.isNotEmpty &&
          !(report.tripId
              .toLowerCase()
              .contains(_tripIdFilter.toLowerCase()))) {
        return false;
      }

      // Filter by status - sử dụng map ánh xạ từ tiếng Việt sang tiếng Anh
      if (_statusFilter.isNotEmpty) {
        String englishStatus = _statusMap[_statusFilter] ?? _statusFilter;
        if (!report.status
            .toLowerCase()
            .contains(englishStatus.toLowerCase())) {
          return false;
        }
      }

      // Filter by incident time (date range)
      if (_startDate != null || _endDate != null) {
        DateTime incidentDate = report.incidentTime;
        if (_startDate != null && incidentDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null) {
          // Include the entire end date by setting it to end of day
          DateTime endOfDay = DateTime(
              _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
          if (incidentDate.isAfter(endOfDay)) {
            return false;
          }
        }
      }
      return true;
    }).toList();
    
    // Sắp xếp báo cáo theo thời gian mới nhất (giảm dần)
    filteredResults.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    
    return filteredResults;
  }

  // Toggle filter visibility
  void _toggleFilterVisibility() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Sự Cố'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _isFilterVisible ? Icons.filter_list_off : Icons.filter_list),
            onPressed: _toggleFilterVisibility,
            tooltip: 'Lọc báo cáo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Add expandable filter panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFilterVisible ? null : 0,
            child: _isFilterVisible ? _buildFilterPanel() : null,
          ),

          Expanded(
            child: FutureBuilder<List<IncidentReport>>(
              future: _incidentReportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Đã xảy ra lỗi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Không có báo cáo sự cố nào'),
                  );
                } else {
                  // Apply filters to the reports
                  final filteredReports = _getFilteredReports(snapshot.data!);

                  return filteredReports.isEmpty
                      ? const Center(
                          child: Text(
                              'Không tìm thấy báo cáo phù hợp với bộ lọc đã chọn'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadIncidentReports,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              return _buildIncidentReportCard(context, report);
                            },
                          ),
                        );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Filter panel widget
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lọc báo cáo sự cố',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Vị trí',
              hintText: 'Tìm theo vị trí',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                _locationFilter = value;
              });
            },
            controller: TextEditingController(text: _locationFilter),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Mã chuyến',
              hintText: 'Tìm theo mã chuyến',
              prefixIcon: const Icon(Icons.directions_car),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                _tripIdFilter = value;
              });
            },
            controller: TextEditingController(text: _tripIdFilter),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Trạng thái',
              prefixIcon: const Icon(Icons.info),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            value: _statusFilter.isEmpty ? null : _statusFilter,
            items: _availableStatuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _statusFilter = value ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Khoảng thời gian',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _startDate == null
                              ? 'Từ ngày'
                              : _dateFormatter.format(_startDate!),
                          style: TextStyle(
                            color: _startDate == null
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _endDate == null
                              ? 'Đến ngày'
                              : _dateFormatter.format(_endDate!),
                          style: TextStyle(
                            color: _endDate == null
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearAllFilters,
                child: const Text('Đặt lại'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Just to trigger a rebuild with new filters
                  });
                },
                child: const Text('Áp dụng'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentReportCard(BuildContext context, IncidentReport report) {
    Color statusColor = StatusUtils.getStatusColor(report.status);

    return ReportCard(
      onTap: () {        // Chuyển đổi IncidentReport thành Map<String, dynamic>
        Map<String, dynamic> reportJson = {
          'reportId': report.reportId,
          'tripId': report.tripId,
          'reportedBy': report.reportedBy,
          'incidentType': report.incidentType,
          'description': report.description,
          'incidentTime': report.incidentTime.toIso8601String(),
          'location': report.location,
          'type': report.type,
          'status': report.status,
          'vehicleType': report.vehicleType,
          'price': report.price ?? 0,
          'isPay': report.isPay ?? 0,
          'resolutionDetails': report.resolutionDetails,
          'handledBy': report.handledBy,
          'handledTime': report.handledTime?.toIso8601String(),
          'createdDate': report.createdDate.toIso8601String(),
          'incidentReportsFiles': report.files.map((file) => {
            'fileId': file.fileId,
            'reportId': file.reportId,
            'fileName': file.fileName,
            'fileType': file.fileType,
            'uploadDate': file.uploadDate.toIso8601String(),
            'uploadBy': file.uploadBy,
            'description': file.description,
            'note': file.note,
            'fileUrl': file.fileUrl,
            'type': file.type,
          }).toList(),
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncidentReportDetailScreen(report: reportJson),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã: ${report.reportId}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status == 'Resolved' ? 'Đã xử lý' : 'Đang xử lý',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Loại sự cố: ${report.incidentType}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Vị trí: ${report.location}',
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Add price display here
          if (report.price != null && report.price! > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Chi phí: ${report.getFormattedPrice()} VND',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thời gian: ${report.getFormattedIncidentTime()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
