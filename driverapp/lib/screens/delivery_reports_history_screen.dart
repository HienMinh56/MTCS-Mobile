import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driverapp/models/delivery_report.dart';
import 'package:driverapp/services/delivery_report_service.dart';
import 'package:driverapp/screens/delivery_report_history_detail_screen.dart';

class DeliveryReportsScreen extends StatefulWidget {
  final String driverId;
  
  const DeliveryReportsScreen({super.key, required this.driverId});

  @override
  State<DeliveryReportsScreen> createState() => _DeliveryReportsScreenState();
}

class _DeliveryReportsScreenState extends State<DeliveryReportsScreen> {
  final DeliveryReportService _reportService = DeliveryReportService();
  List<DeliveryReport> _reports = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadReports();
  }
  
  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final reports = await _reportService.getDeliveryReports(widget.driverId);
      
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Không thể tải dữ liệu: $e';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Báo Cáo'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadReports,
              child: const Text('Thử Lại'),
            ),
          ],
        ),
      );
    }
    
    if (_reports.isEmpty) {
      return const Center(
        child: Text('Không có báo cáo nào'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _buildReportCard(report);
      },
    );
  }
  
  Widget _buildReportCard(DeliveryReport report) {
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(report.reportTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description,
                    color: Colors.teal[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mã Chuyến: ${report.tripId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (report.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  report.notes,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.photo_library,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${report.files.length} ảnh',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.teal[700],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
