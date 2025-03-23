import 'package:driverapp/services/navigation_service.dart';
import 'package:flutter/material.dart';

class ReportMenuScreen extends StatelessWidget {
  final String userId;
  final NavigationService _navigationService = NavigationService();

  ReportMenuScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Loại Báo Cáo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildReportCard(
                    context: context,
                    title: 'Báo Cáo Giao Hàng',
                    subtitle: 'Xem lịch sử các báo cáo giao hàng',
                    icon: Icons.local_shipping,
                    color: Colors.teal,
                    onTap: () => _navigationService.navigateToDeliveryReports(
                      context, userId
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    context: context,
                    title: 'Báo Cáo Nhiên Liệu',
                    subtitle: 'Xem lịch sử các báo cáo nhiên liệu',
                    icon: Icons.local_gas_station,
                    color: Colors.orange,
                    onTap: () => _navigationService.navigateToFuelReports(
                      context, userId
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    context: context,
                    title: 'Báo Cáo Sự Cố',
                    subtitle: 'Xem lịch sử các báo cáo sự cố',
                    icon: Icons.warning_amber,
                    color: Colors.red.shade700,
                    onTap: () => _navigationService.navigateToIncidentReports(
                      context, userId
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
