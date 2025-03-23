import 'package:flutter/material.dart';
import 'package:driverapp/models/delivery_report.dart';
import 'package:driverapp/components/report_info_card.dart';
import 'package:driverapp/components/info_card.dart';
import 'package:driverapp/components/image_grid.dart';
import 'package:driverapp/utils/image_utils.dart';

class DeliveryReportDetailScreen extends StatelessWidget {
  final DeliveryReport report;
  
  DeliveryReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Báo Cáo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportInfoCard(report: report),
            const SizedBox(height: 24),
            _buildImagesCard(context),
          ],
        ),
      ),
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
          ImageGrid(
            files: report.files,
            getImageUrl: (file) => file.fileUrl,
            getImageTitle: (file) => file.fileName,
            getUploadTime: (file) => ImageUtils.formatUploadDate(file.uploadDate),
            onImageTap: (file) {
              ImageUtils.showFullImageDialog(
                context, 
                file.fileUrl,
                title: file.fileName,
                description: file.description,
              );
            },
          ),
      ],
    );
  }
}
