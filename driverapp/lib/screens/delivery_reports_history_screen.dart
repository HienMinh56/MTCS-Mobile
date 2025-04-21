import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driverapp/models/delivery_report_model.dart';
import 'package:driverapp/services/report_service.dart';
import 'package:driverapp/screens/delivery_report_detail_screen.dart';

class DeliveryReportsScreen extends StatefulWidget {
  final String driverId;

  const DeliveryReportsScreen({super.key, required this.driverId});

  @override
  _DeliveryReportsScreenState createState() => _DeliveryReportsScreenState();
}

class _DeliveryReportsScreenState extends State<DeliveryReportsScreen> {
  final ReportService _reportService = ReportService();
  late Future<List<DeliveryReport>> _reportsFuture;
  List<DeliveryReport> _allReports = [];
  List<DeliveryReport> _filteredReports = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  String _tripIdFilter = '';
  
  bool _isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _reportsFuture = _reportService.getDeliveryReports(null, widget.driverId);
    _reportsFuture.then((reports) {
      setState(() {
        _isLoading = false;
        _allReports = reports;
        _applyFilters();
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load delivery reports: ${error.toString()}';
      });
    });
  }

  void _applyFilters() {
    setState(() {
      if (_startDate == null && _endDate == null && _tripIdFilter.isEmpty) {
        _filteredReports = List.from(_allReports);
        return;
      }

      _filteredReports = _allReports.where((report) {
        try {
          // Filter by trip ID
          if (_tripIdFilter.isNotEmpty && 
              !report.tripId.toLowerCase().contains(_tripIdFilter.toLowerCase())) {
            return false;
          }
          
          // Filter by date range
          DateTime reportDate = DateTime.parse(report.reportTime);

          if (_startDate != null) {
            DateTime startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            if (reportDate.isBefore(startOfDay)) {
              return false;
            }
          }

          if (_endDate != null) {
            DateTime endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
            if (reportDate.isAfter(endOfDay)) {
              return false;
            }
          }

          return true;
        } catch (e) {
          return true;
        }
      }).toList();
    });
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _tripIdFilter = '';
      _applyFilters();
    });
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  void _toggleFilterVisibility() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Giao Hàng'),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFilterVisible ? null : 0,
            child: _isFilterVisible ? _buildFilterPanel() : null,
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadReports();
              },
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
                                onPressed: _loadReports,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : FutureBuilder<List<DeliveryReport>>(
                          future: _reportsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Error: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadReports,
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              );
                            } else if (!snapshot.hasData || _allReports.isEmpty) {
                              return const Center(
                                child: Text('Không có báo cáo giao hàng nào'),
                              );
                            }

                            final reports = _filteredReports;

                            if (reports.isEmpty) {
                              return Center(
                                child: Text('Không tìm thấy báo cáo'),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: reports.length,
                              itemBuilder: (context, index) {
                                final report = reports[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DeliveryReportDetailScreen(report: report),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Mã: ${report.tripId}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Thời gian: ${_formatDateTime(report.reportTime)}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          if (report.deliveryReportsFiles.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.image, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${report.deliveryReportsFiles.length} hình ảnh',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
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
            'Lọc báo cáo giao hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
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
                _applyFilters();
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
                    if (picked != null && picked != _startDate) {
                      setState(() {
                        _startDate = picked;
                        _applyFilters();
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
                    if (picked != null && picked != _endDate) {
                      setState(() {
                        _endDate = picked;
                        _applyFilters();
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
                onPressed: _clearDateFilters,
                child: const Text('Đặt lại'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
