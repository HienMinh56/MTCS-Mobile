import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driverapp/models/delivery_report_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DeliveryReportDetailScreen extends StatelessWidget {
  final DeliveryReport report;

  const DeliveryReportDetailScreen({Key? key, required this.report}) : super(key: key);

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
        title: Text('Chi Tiết Báo Cáo ${report.tripId}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(context),
              const SizedBox(height: 24),
              if (report.notes.isNotEmpty) _buildNotesSection(context),
              if (report.deliveryReportsFiles.isNotEmpty) _buildImagesSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin báo cáo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('ID Chuyến:', report.tripId.toString()),
            _buildInfoRow('Thời gian báo cáo:', _formatDateTime(report.reportTime)),
            _buildInfoRow('Người báo cáo:', report.reportBy),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi chú',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(report.notes),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hình ảnh báo cáo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: report.deliveryReportsFiles.length,
              itemBuilder: (context, fileIndex) {
                final file = report.deliveryReportsFiles[fileIndex];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text(file.fileName),
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              panEnabled: true,
                              boundaryMargin: const EdgeInsets.all(20),
                              minScale: 0.5,
                              maxScale: 4,
                              child: CachedNetworkImage(
                                imageUrl: file.fileUrl,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 50,
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: file.fileUrl,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
