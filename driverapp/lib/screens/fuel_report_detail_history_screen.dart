import 'package:flutter/material.dart';
import 'package:driverapp/models/fuel_report_model.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/status_header.dart';
import 'package:driverapp/components/info_card.dart';
import 'package:driverapp/components/image_grid.dart';
import 'package:driverapp/utils/image_utils.dart';

class FuelReportDetailScreen extends StatelessWidget {
  final FuelReport report;

  const FuelReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Báo Cáo Nhiên Liệu'),
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
            _buildHeader(),
            const SizedBox(height: 16),
            _buildInfoCard(context),
            const SizedBox(height: 16),
            if (report.files.isNotEmpty) _buildImagesCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return StatusHeader(
      title: 'Báo Cáo Nhiên Liệu: ${report.reportId}',
      subtitle: 'Ngày báo cáo: ${report.getFormattedReportTime()}',
      icon: Icons.local_gas_station,
      color: Colors.orange,
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return InfoCard(
      title: 'Thông tin nhiên liệu',
      children: [
        InfoRow(label: 'Mã báo cáo:', value: report.reportId),
        InfoRow(label: 'Mã chuyến đi:', value: report.tripId),
        InfoRow(label: 'Số lượng nhiên liệu:', value: report.getFormattedRefuelAmount()),
        InfoRow(
          label: 'Chi phí:',
          value: report.getFormattedFuelCost(),
        ),
        InfoRow(label: 'Vị trí:', value: report.location),
        InfoRow(label: 'Thời gian báo cáo:', value: report.getFormattedReportTime()),
        InfoRow(label: 'Người báo cáo:', value: report.reportBy),
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
          ImageGrid<FuelReportFile>(
            files: report.files,
            getImageUrl: (file) => file.fileUrl,
            getImageTitle: (file) => file.fileName,
            // getUploadTime: (file) => ImageUtils.formatUploadDate(file.uploadDate),
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
}
