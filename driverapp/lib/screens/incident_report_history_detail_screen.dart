import 'package:flutter/material.dart';
import 'package:driverapp/models/incident_report_model.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/status_header.dart';
import 'package:driverapp/components/info_card.dart';
import 'package:driverapp/components/image_grid.dart';
import 'package:driverapp/utils/image_utils.dart';
import 'package:driverapp/utils/status_utils.dart';
import 'package:driverapp/utils/date_utils.dart';

class IncidentReportDetailScreen extends StatelessWidget {
  final IncidentReport report;

  const IncidentReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi Tiết Báo Cáo ${report.reportId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 16),
            _buildInfoCard(context),
            const SizedBox(height: 16),
            _buildDescriptionCard(),
            if (report.files.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImagesCard(context),
            ],
            if (report.handledBy != null) ...[
              const SizedBox(height: 16),
              _buildResolutionCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor = StatusUtils.getStatusColor(report.status);
    IconData statusIcon = StatusUtils.getStatusIcon(report.status);

    return StatusHeader(
      title: 'Trạng thái: ${report.status}',
      subtitle: 'Cập nhật: ${report.getFormattedCreatedDate()}',
      icon: statusIcon,
      color: statusColor,
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return InfoCard(
      title: 'Thông tin sự cố',
      children: [
        InfoRow(label: 'Mã báo cáo:', value: report.reportId),
        InfoRow(label: 'Mã chuyến đi:', value: report.tripId),
        InfoRow(label: 'Loại sự cố:', value: report.incidentType),
        InfoRow(label: 'Vị trí:', value: report.location),
        InfoRow(label: 'Thời gian xảy ra:', value: report.getFormattedIncidentTime()),
        InfoRow(label: 'Người báo cáo:', value: report.reportedBy),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return InfoCard(
      title: 'Mô tả sự cố',
      children: [
        Text(
          report.description,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildImagesCard(BuildContext context) {
    return InfoCard(
      title: 'Hình ảnh',
      children: [
        if (report.files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: Text('Không có hình ảnh')),
          )
        else
          ImageGrid<IncidentReportFile>(
            files: report.files,
            getImageUrl: (file) => file.fileUrl,
            getImageTitle: (file) => file.fileName,
            getUploadTime: (file) => ImageUtils.formatUploadDate(file.uploadDate),
            onImageTap: (file) {
              ImageUtils.showFullImageDialog(
                context, 
                file.fileUrl,
                title: file.fileName,
                description: file.description ?? 'Không có mô tả',
              );
            },
          ),
      ],
    );
  }

  Widget _buildResolutionCard() {
    return InfoCard(
      title: 'Thông tin xử lý',
      children: [
        InfoRow(
          label: 'Người xử lý:',
          value: report.handledBy ?? 'Chưa có',
        ),
        InfoRow(
          label: 'Thời gian xử lý:',
          value: report.handledTime != null
              ? AppDateUtils.formatDateTime(report.handledTime!)
              : 'Chưa có',
        ),
        if (report.resolutionDetails != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Chi tiết xử lý:',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            report.resolutionDetails ?? '',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ],
    );
  }
}
