import 'package:flutter/material.dart';
import 'package:driverapp/models/fuel_report_model.dart';
import 'package:driverapp/services/report_service.dart';
import 'package:driverapp/screens/fuel_report_detail_history_screen.dart';
import 'package:driverapp/components/report_card.dart';

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
      _fuelReportsFuture = _reportService.getFuelReports(widget.userId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Nhiên Liệu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFuelReports,
          ),
        ],
      ),
      body: _isLoading 
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
                      return RefreshIndicator(
                        onRefresh: _loadFuelReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final report = snapshot.data![index];
                            return _buildFuelReportCard(context, report);
                          },
                        ),
                      );
                    }
                  },
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
