import 'package:flutter/material.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/section_card.dart';

class OrderDetailScreen extends StatefulWidget {
  final String tripId;

  const OrderDetailScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _orderDetails;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load order details
      final orderDetails = await _orderService.getOrderByTripId(widget.tripId);

      if (mounted) {
        setState(() {
          _orderDetails = orderDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khi tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết Order: ${_orderDetails?['orderId'] ?? ''}'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrderDetails,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : _buildOrderContent(),
      ),
    );
  }

  Widget _buildOrderContent() {
    if (_orderDetails == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Thông tin Cơ bản',
            children: [
              InfoRow(label: 'Order ID:', value: _orderDetails!['orderId'] ?? 'N/A'),
              InfoRow(label: 'Tracking Code:', value: _orderDetails!['trackingCode'] ?? 'N/A'),
              InfoRow(label: 'Số Container:', value: _orderDetails!['containerNumber'] ?? 'N/A'),
              InfoRow(label: 'Giá:', value: CurrencyFormatter.formatVND(_orderDetails!['price'])),
              InfoRow(label: 'Loại:', value: _orderDetails!['deliveryType'] == 1 ? "Nhập" : "Xuất"),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SectionCard(
            title: 'Điểm Giao Nhận',
            children: [
              InfoRow(label: 'Điểm lấy hàng:', value: _orderDetails!['pickUpLocation'] ?? 'N/A'),
              InfoRow(label: 'Điểm giao hàng:', value: _orderDetails!['deliveryLocation'] ?? 'N/A'),
              InfoRow(label: 'Điểm trả rỗng:', value: _orderDetails!['conReturnLocation'] ?? 'N/A'),
              InfoRow(label: 'Khoảng cách:', value: '${_orderDetails!['distance']} km'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SectionCard(
            title: 'Thông tin Hàng Hóa',
            children: [
              InfoRow(label: 'Loại Container:', value: _getContainerType(_orderDetails!['containerType'])),
              InfoRow(label: 'Loại Giao Hàng:', value: _getDeliveryType(_orderDetails!['deliveryType'])),
              InfoRow(label: 'Nhiệt độ:', value: '${_orderDetails!['temperature']} °C'),
              InfoRow(label: 'Khối lượng:', value: '${_orderDetails!['weight']} tấn'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SectionCard(
            title: 'Thời Gian',
            children: [
              InfoRow(label: 'Ngày lấy hàng:', value: _formatDate(_orderDetails!['pickUpDate'])),
              InfoRow(label: 'Ngày giao hàng:', value: _formatDate(_orderDetails!['deliveryDate'])),
              InfoRow(label: 'Hoàn thành cần:', value: _orderDetails!['completionTime']),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SectionCard(
            title: 'Thông tin Liên Hệ',
            children: [
              InfoRow(label: 'Người liên hệ:', value: _orderDetails!['contactPerson'] ?? 'N/A'),
              InfoRow(label: 'SĐT liên hệ:', value: _orderDetails!['contactPhone'] ?? 'N/A'),
              InfoRow(label: 'Người đặt hàng:', value: _orderDetails!['orderPlacer'] ?? 'N/A'),
            ],
          ),
          
          if (_orderDetails!['note'] != null && _orderDetails!['note'].toString().isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Ghi Chú',
                  children: [
                    InfoRow(label: '', value: _orderDetails!['note'] ?? 'Không có ghi chú'),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
  
  String _getContainerType(int? type) {
    if (type == null) return 'N/A';
    switch (type) {
      case 1:
        return 'Container Thường';
      case 2:
        return 'Container Lạnh';
      default:
        return 'Loại $type';
    }
  }
  
  String _getDeliveryType(int? type) {
    if (type == null) return 'N/A';
    switch (type) {
      case 1:
        return 'Giao thẳng';
      case 2:
        return 'Giao kho';
      default:
        return 'Loại $type';
    }
  }
}
