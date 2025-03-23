import 'package:flutter/material.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/components/order_list.dart';
import 'package:driverapp/models/order.dart';

class OrderListScreen extends StatelessWidget {
  final String userId;
  final String status;

  const OrderListScreen({Key? key, required this.userId, required this.status}) : super(key: key);
  
  // Method to translate status to Vietnamese
  String getVietnameseStatus(String englishStatus) {
    switch (englishStatus.toLowerCase()) {
      case 'assigned':
        return 'Chờ xử lý';  // Updated to match mock data
      case 'processing':
        return 'Đang giao';  // Updated to match mock data
      case 'completed':
        return 'Đã giao';    // Updated to match mock data
      default:
        return englishStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn Hàng ${getVietnameseStatus(status)}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Order>>(
          future: orderService.getOrdersByStatus(userId, status),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lỗi: ${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Show available statuses for debugging
                        final statuses = orderService.getAvailableStatuses();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Available statuses: ${statuses.join(", ")}'),
                            duration: const Duration(seconds: 10),
                          ),
                        );
                      },
                      child: const Text('Show Available Statuses'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Không tìm thấy đơn hàng.'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Show available statuses for debugging
                        final statuses = orderService.getAvailableStatuses();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Available statuses: ${statuses.join(", ")}'),
                            duration: const Duration(seconds: 10),
                          ),
                        );
                      },
                      child: const Text('Show Available Statuses'),
                    ),
                  ],
                ),
              );
            } else {
              final orders = snapshot.data!;
              return OrderList(orders: orders);
            }
          },
        ),
      ),
    );
  }
}
