import 'package:flutter/material.dart';
import 'package:driverapp/models/incident_report_model.dart';
import 'package:driverapp/services/report_service.dart';
import 'package:driverapp/screens/incident_report_history_detail_screen.dart';
import 'package:driverapp/components/report_card.dart';
import 'package:driverapp/utils/status_utils.dart';

class IncidentReportsScreen extends StatefulWidget {
  final String userId;

  const IncidentReportsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<IncidentReportsScreen> createState() => _IncidentReportsScreenState();
}

class _IncidentReportsScreenState extends State<IncidentReportsScreen> {
  final ReportService _reportService = ReportService();
  late Future<List<IncidentReport>> _incidentReportsFuture;

  @override
  void initState() {
    super.initState();
    _incidentReportsFuture = _reportService.getIncidentReports(widget.userId);
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
      ),
      body: FutureBuilder<List<IncidentReport>>(
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
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final report = snapshot.data![index];
                return _buildIncidentReportCard(context, report);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildIncidentReportCard(BuildContext context, IncidentReport report) {
    Color statusColor = StatusUtils.getStatusColor(report.status);

    return ReportCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncidentReportDetailScreen(report: report),
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
                report.reportId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                  report.status,
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
