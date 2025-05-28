import 'package:flutter/material.dart';
import 'package:driverapp/models/expense_report_model.dart';
import 'package:driverapp/models/expense_report_type.dart';
import 'package:driverapp/services/expense_report_service.dart';
import 'package:driverapp/services/expense_type_manager.dart';
import 'package:driverapp/components/report_card.dart';
import 'package:driverapp/screens/expense_report_detail_screen.dart';
import 'package:intl/intl.dart';

class ExpenseReportsScreen extends StatefulWidget {
  final String userId;

  const ExpenseReportsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ExpenseReportsScreen> createState() => _ExpenseReportsScreenState();
}

class _ExpenseReportsScreenState extends State<ExpenseReportsScreen> {
  late Future<List<ExpenseReport>> _expenseReportsFuture;
  bool _isLoading = false;
  String? _errorMessage;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  // Add filter state variables
  String _locationFilter = '';
  String _tripIdFilter = '';
  String _reportTypeFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterVisible = false;
  
  // Add list for expense report types from API
  List<ExpenseReportType> _expenseReportTypes = [];
  String? _selectedReportTypeId;
  
  // Controllers for text fields to maintain values
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _tripIdController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadExpenseReports();
    _loadExpenseReportTypes();
  }  Future<void> _loadExpenseReportTypes() async {
    try {
      // Sử dụng ExpenseTypeManager để lấy thông tin loại báo cáo chi phí từ API
      final expenseTypeManager = ExpenseTypeManager();
      final types = expenseTypeManager.getAllExpenseReportTypes();

      if (types.isNotEmpty) {
        setState(() {
          _expenseReportTypes = types;
        });
      } else {
        // Nếu chưa có dữ liệu, tải từ API
        final freshTypes = await ExpenseReportService.getAllExpenseReportTypes();
        setState(() {
          _expenseReportTypes = freshTypes;
        });
      }
    } catch (e) {
      print('Error loading expense report types: $e');
    }
  }  String getReportTypeName(String reportTypeId) {
    // Sử dụng ExpenseTypeManager để lấy thông tin loại báo cáo chi phí từ API
    final expenseTypeManager = ExpenseTypeManager();
    final reportTypes = expenseTypeManager.getAllExpenseReportTypes();
    
    // Debug: In ra thông tin để kiểm tra
    print('ExpenseTypeManager isInitialized: ${expenseTypeManager.isInitialized}');
    print('Number of report types loaded: ${reportTypes.length}');
    if (reportTypes.isNotEmpty) {
      print('Available report types: ${reportTypes.map((e) => '${e.reportTypeId}: ${e.reportType}').join(', ')}');
    }
    
    // Nếu chưa có dữ liệu từ ExpenseTypeManager, trả về giá trị mặc định
    if (reportTypes.isEmpty) {
      print('No report types available, using default for reportTypeId: $reportTypeId');
      return 'Chi phí khác';
    }
    
    // Tìm loại báo cáo chi phí phù hợp từ danh sách
    final reportType = reportTypes.firstWhere(
      (type) => type.reportTypeId == reportTypeId,
      orElse: () => ExpenseReportType(
        reportTypeId: reportTypeId,
        reportType: 'Chi phí khác', // Giá trị mặc định nếu không tìm thấy
        isActive: 1
      )
    );
    
    print('Found report type for $reportTypeId: ${reportType.reportType}');
    
    // Trả về tên loại báo cáo chi phí
    return reportType.reportType;
  }

  Future<void> _loadExpenseReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _expenseReportsFuture = _fetchExpenseReports();
      await _expenseReportsFuture; // Wait to catch any errors
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải báo cáo: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<ExpenseReport>> _fetchExpenseReports() async {
    final response = await ExpenseReportService.getAllExpenseReportsByDriverId(widget.userId);
    
    if (response['status'] == 200 && response['data'] != null) {
      final List<dynamic> data = response['data'];
      final List<ExpenseReport> reports = data
          .map((json) => ExpenseReport.fromJson(json))
          .toList();
      
      // Sort by report time (newest first)
      reports.sort((a, b) => b.reportTime.compareTo(a.reportTime));
      return reports;
    }
    
    return [];
  }  void _clearAllFilters() {
    setState(() {
      _locationFilter = '';
      _tripIdFilter = '';
      _reportTypeFilter = '';
      _selectedReportTypeId = null;
      _startDate = null;
      _endDate = null;
      _locationController.clear();
      _tripIdController.clear();
    });
  }
  // Add filtering function
  List<ExpenseReport> _getFilteredReports(List<ExpenseReport> reports) {
    return reports.where((report) {
      // Filter by location
      if (_locationFilter.isNotEmpty &&
          !report.location.toLowerCase().contains(_locationFilter.toLowerCase())) {
        return false;
      }

      // Filter by trip ID
      if (_tripIdFilter.isNotEmpty &&
          !report.tripId.toLowerCase().contains(_tripIdFilter.toLowerCase())) {
        return false;
      }

      // Filter by report type (using dropdown selection)
      if (_selectedReportTypeId != null && _selectedReportTypeId!.isNotEmpty &&
          report.reportTypeId != _selectedReportTypeId) {
        return false;
      }      // Filter by report type name (using text input - fallback)
      if (_reportTypeFilter.isNotEmpty &&
          !getReportTypeName(report.reportTypeId).toLowerCase().contains(_reportTypeFilter.toLowerCase())) {
        return false;
      }

      // Filter by report time (date range)
      if (_startDate != null || _endDate != null) {
        DateTime reportDate = report.reportTime;
        if (_startDate != null && reportDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null) {
          // Include the entire end date by setting it to end of day
          DateTime endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
          if (reportDate.isAfter(endOfDay)) {
            return false;
          }
        }
      }
      return true;
    }).toList();
  }

  // Remove _showFilterDialog and replace it with toggle filter visibility
  void _toggleFilterVisibility() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }
  Widget _buildExpenseReportCard(BuildContext context, ExpenseReport report) {
    return ReportCard(
      onTap: () {
        // Navigate to detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseReportDetailScreen(report: report),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Mã: ${report.reportId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                report.getFormattedReportTime(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loại chi phí',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),                    Text(
                      getReportTypeName(report.reportTypeId),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi phí',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.getFormattedCost()} VND',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.local_shipping,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Chuyến: ${report.tripId}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _tripIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Báo Cáo Chi Phí'),
        actions: [
          IconButton(
            icon: Icon(_isFilterVisible ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: _toggleFilterVisibility,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          if (_isFilterVisible) ...[
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                children: [
                  // Location and Trip ID filters
                  Row(                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Lọc theo địa điểm',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _locationFilter = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _tripIdController,
                          decoration: const InputDecoration(
                            labelText: 'Lọc theo mã chuyến',
                            prefixIcon: Icon(Icons.local_shipping),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _tripIdFilter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),                  const SizedBox(height: 8),
                  // Report type filter - using dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedReportTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Lọc theo loại chi phí',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tất cả loại chi phí'),
                      ),
                      ..._expenseReportTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type.reportTypeId,
                          child: Text(type.reportType),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedReportTypeId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Date range filters
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Từ ngày',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _startDate != null ? _dateFormatter.format(_startDate!) : 'Chọn ngày',
                              style: TextStyle(
                                color: _startDate != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Đến ngày',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _endDate != null ? _dateFormatter.format(_endDate!) : 'Chọn ngày',
                              style: TextStyle(
                                color: _endDate != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Clear filters button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.clear),
                      label: const Text('Xóa bộ lọc'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Reports list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadExpenseReports,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMessage!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadExpenseReports,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : FutureBuilder<List<ExpenseReport>>(
                          future: _expenseReportsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Lỗi: ${snapshot.error}'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadExpenseReports,
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final reports = snapshot.data ?? [];
                            final filteredReports = _getFilteredReports(reports);

                            if (filteredReports.isEmpty) {
                              return const Center(
                                child: Text('Không có báo cáo chi phí nào.'),
                              );
                            }                            return ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: filteredReports.length,
                              itemBuilder: (context, index) {
                                final report = filteredReports[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: _buildExpenseReportCard(context, report),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
