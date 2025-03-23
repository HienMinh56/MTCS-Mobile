import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driverapp/models/delivery_report.dart';

class ReportInfoCard extends StatelessWidget {
  final DeliveryReport report;

  const ReportInfoCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(report.reportTime);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông Tin Báo Cáo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            _buildInfoRow('Mã Báo Cáo:', report.reportId),
            const SizedBox(height: 12),
            
            _buildInfoRow('Mã Chuyến:', report.tripId),
            const SizedBox(height: 12),
            
            _buildInfoRow('Thời Gian Báo Cáo:', formattedDate),
            const SizedBox(height: 12),
            
            _buildInfoRow('Người Báo Cáo:', report.reportBy),
            const SizedBox(height: 12),
            
            const Text(
              'Ghi Chú:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              report.notes.isEmpty ? 'Không có ghi chú' : report.notes,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
