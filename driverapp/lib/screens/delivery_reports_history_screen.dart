import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driverapp/models/delivery_report_model.dart';
import 'package:driverapp/services/report_service.dart';
import 'package:driverapp/screens/delivery_report_detail_screen.dart';

class DeliveryReportsScreen extends StatefulWidget {
  final String driverId;

  const DeliveryReportsScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  _DeliveryReportsScreenState createState() => _DeliveryReportsScreenState();
}

class _DeliveryReportsScreenState extends State<DeliveryReportsScreen> {
  final ReportService _reportService = ReportService();
  late Future<List<DeliveryReport>> _reportsFuture;
  bool _isLoading = false;
  String? _errorMessage;

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

    _reportsFuture = _reportService.getDeliveryReports(widget.driverId);
    _reportsFuture.then((_) {
      setState(() {
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load delivery reports: ${error.toString()}';
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Giao Hàng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadReports();
          // Remove the return statement as onRefresh requires Future<void>
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
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Không có báo cáo giao hàng nào'),
                        );
                      }

                      final reports = snapshot.data!;
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
                                      'Báo cáo chuyến hàng ${report.tripId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
    );
  }
}
