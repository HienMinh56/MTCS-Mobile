import 'package:flutter/material.dart';
import '../../utils/color_constants.dart';

class ReportIconsSection extends StatelessWidget {
  final int fuelReportsCount;
  final int incidentReportsCount;
  final int deliveryReportsCount;
  final bool isFuelReportsExpanded;
  final bool isIncidentReportsExpanded;
  final bool isDeliveryReportsExpanded;
  final Function(int) onReportTypeSelected;

  const ReportIconsSection({
    Key? key,
    required this.fuelReportsCount,
    required this.incidentReportsCount,
    required this.deliveryReportsCount,
    required this.isFuelReportsExpanded,
    required this.isIncidentReportsExpanded,
    required this.isDeliveryReportsExpanded,
    required this.onReportTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Fuel report icon
            _buildReportIcon(
              icon: Icons.local_gas_station,
              label: 'Đổ xăng',
              count: fuelReportsCount,
              isSelected: isFuelReportsExpanded,
              onTap: () => onReportTypeSelected(0),
            ),

            // Incident report icon
            _buildReportIcon(
              icon: Icons.warning_amber,
              label: 'Sự cố',
              count: incidentReportsCount,
              isSelected: isIncidentReportsExpanded,
              onTap: () => onReportTypeSelected(1),
            ),
            
            // Delivery report icon
            _buildReportIcon(
              icon: Icons.receipt_long,
              label: 'Giao hàng',
              count: deliveryReportsCount,
              isSelected: isDeliveryReportsExpanded,
              onTap: () => onReportTypeSelected(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportIcon({
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorConstants.primaryColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? ColorConstants.primaryColor
                      : Colors.grey[700],
                  size: 36,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? ColorConstants.primaryColor
                  : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}