import 'package:flutter/material.dart';
import 'package:driverapp/models/fuel_report_model.dart';
import 'package:driverapp/services/report_service.dart';
import 'package:driverapp/screens/fuel_report_detail_history_screen.dart';
import 'package:driverapp/components/report_card.dart';
import 'package:intl/intl.dart';

class FuelReportsScreen extends StatefulWidget {
  final String userId;

  const FuelReportsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<FuelReportsScreen> createState() => _FuelReportsScreenState();
}

class _FuelReportsScreenState extends State<FuelReportsScreen> {
  final ReportService _reportService = ReportService();
  late Future<List<FuelReport>> _fuelReportsFuture;
  bool _isLoading = false;
  String? _errorMessage;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  // Add filter state variables
  String _locationFilter = '';
  String _tripIdFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    _loadFuelReports();
  }

  Future<void> _loadFuelReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _fuelReportsFuture = _reportService.getFuelReports(null, widget.userId);
      await _fuelReportsFuture; // Wait to catch any errors
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

  void _clearAllFilters() {
    setState(() {
      _locationFilter = '';
      _tripIdFilter = '';
      _startDate = null;
      _endDate = null;
    });
  }

  // Add filtering function
  List<FuelReport> _getFilteredReports(List<FuelReport> reports) {
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

  @override
  Widget build(BuildContext context) {
    // bool hasActiveFilters = _startDate != null || _endDate != null || 
    //                        _locationFilter.isNotEmpty || _tripIdFilter.isNotEmpty;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Nhiên Liệu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFilterVisible ? Icons.filter_list_off : Icons.filter_list),
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
          
          // Add filter summary bar similar to delivery reports
          // if (hasActiveFilters)
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     color: Colors.grey[200],
          //     child: Row(
          //       children: [
          //         Expanded(
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               if (_startDate != null || _endDate != null)
          //                 Text(
          //                   'Từ: ${_startDate != null ? _dateFormatter.format(_startDate!) : "Tất cả"} '
          //                   'đến: ${_endDate != null ? _dateFormatter.format(_endDate!) : "Tất cả"}',
          //                   style: const TextStyle(fontWeight: FontWeight.bold),
          //                 ),
          //               if (_locationFilter.isNotEmpty)
          //                 Text(
          //                   'Vị trí: $_locationFilter',
          //                   style: const TextStyle(fontWeight: FontWeight.bold),
          //                 ),
          //               if (_tripIdFilter.isNotEmpty)
          //                 Text(
          //                   'Mã chuyến: $_tripIdFilter',
          //                   style: const TextStyle(fontWeight: FontWeight.bold),
          //                 ),
          //             ],
          //           ),
          //         ),
          //         IconButton(
          //           icon: const Icon(Icons.clear, size: 20),
          //           onPressed: _clearAllFilters,
          //           tooltip: 'Xóa bộ lọc',
          //         ),
          //       ],
          //     ),
          //   ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFuelReports,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : FutureBuilder<List<FuelReport>>(
                        future: _fuelReportsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Đã xảy ra lỗi: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadFuelReports,
                                    child: const Text('Thử lại'),
                                  ),
                                ],
                              ),
                            );
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('Không có báo cáo nhiên liệu nào'),
                            );
                          } else {
                            // Apply filters to the reports
                            final filteredReports = _getFilteredReports(snapshot.data!);

                            return filteredReports.isEmpty
                                ? Center(
                                    child: Text('Không tìm thấy báo cáo phù hợp với bộ lọc đã chọn'),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadFuelReports,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(16.0),
                                      itemCount: filteredReports.length,
                                      itemBuilder: (context, index) {
                                        final report = filteredReports[index];
                                        return _buildFuelReportCard(context, report);
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
  
  // New filter panel widget
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
            'Lọc báo cáo nhiên liệu',
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
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                _tripIdFilter = value;
              });
            },
            controller: TextEditingController(text: _tripIdFilter),
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                            color: _startDate == null ? Colors.grey[600] : Colors.black,
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                            color: _endDate == null ? Colors.grey[600] : Colors.black,
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

  Widget _buildFuelReportCard(BuildContext context, FuelReport report) {
    return ReportCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FuelReportDetailScreen(report: report),
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
                  report.reportId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                report.tripId,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
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
                    const Text(
                      'Số lượng nhiên liệu',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.getFormattedRefuelAmount(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi phí',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.getFormattedFuelCost(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Vị trí: ${report.location}',
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thời gian: ${report.getFormattedReportTime()}',
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
