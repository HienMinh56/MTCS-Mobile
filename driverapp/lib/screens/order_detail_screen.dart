import 'package:flutter/material.dart';
import 'package:driverapp/models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Đơn Hàng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDetailCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng: ${order.orderId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(order.status),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  order.deliveryDate,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    
    switch (status.toLowerCase()) {
      case 'đã giao': color = Colors.green; break;
      case 'đang giao': color = Colors.blue; break;
      case 'chờ xử lý': color = Colors.orange; break;
      default: color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin chi tiết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            
            // Shipping details section
            _buildSectionTitle('Thông tin vận đơn'),
            _buildDetailItem('Mã vận đơn', order.shippingCode ?? 'N/A'),
            _buildDetailItem('Cách thức vận chuyển', order.transportationType ?? 'N/A'),
            
            const Divider(height: 24),
            
            // Container details section
            _buildSectionTitle('Thông tin container'),
            _buildDetailItem('Mã container', order.containerId ?? 'N/A'),
            _buildDetailItem('Loại container', order.containerType ?? 'N/A'),
            _buildDetailItem('Nhiệt độ container', order.containerTemperature != null 
                ? '${order.containerTemperature}°C' : 'N/A'),
            _buildDetailItem('Khối lượng đơn hàng', order.orderWeight != null 
                ? '${order.orderWeight} Tấn' : 'N/A'),
            
            const Divider(height: 24),
            
            // Locations and dates section
            _buildSectionTitle('Địa điểm & thời gian'),
            _buildDetailItem('Ngày lấy hàng', order.pickupDate ?? 'N/A'),
            _buildDetailItem('Ngày giao hàng', order.deliveryDate),
            _buildDetailItem('Chỗ lấy hàng', order.pickupLocation ?? 'N/A'),
            _buildDetailItem('Chỗ giao hàng', order.deliveryLocation),
            _buildDetailItem('Chỗ trả container', order.containerReturnLocation ?? 'N/A'),
            
            const Divider(height: 24),
            
            // Partner information section
            _buildSectionTitle('Thông tin đối tác'),
            _buildDetailItem('Tên đối tác', order.partnerName ?? order.customerName),
            _buildDetailItem('Số điện thoại đối tác', order.partnerPhone ?? 'N/A'),
            
            const Divider(height: 24),
            
            // Payment information section
            _buildSectionTitle('Thông tin thanh toán'),
            _buildDetailItem('Trạng thái thanh toán', 
                order.isPaid ?? false ? 'Đã thanh toán' : 'Chưa thanh toán',
                valueColor: order.isPaid ?? false ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
