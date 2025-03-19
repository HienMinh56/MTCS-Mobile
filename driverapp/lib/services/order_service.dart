import 'package:driverapp/models/order.dart';
import 'package:driverapp/utils/mock_data.dart';

class OrderService {
  // Simulate fetching order counts from a backend
  Future<Map<String, int>> getOrderCounts(String userId) async {
    // This would normally be an API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    final allOrders = MockData.getMockOrders();
    final assigned = allOrders.where((o) => o.status.toLowerCase() == 'chờ xử lý').length;
    final processing = allOrders.where((o) => o.status.toLowerCase() == 'đang giao').length;
    final completed = allOrders.where((o) => o.status.toLowerCase() == 'đã giao').length;
    
    return {
      'assigned': assigned,
      'processing': processing,
      'completed': completed,
    };
  }
  
  Future<List<Order>> getOrdersByStatus(String userId, String status) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Get mock data
    final allOrders = MockData.getMockOrders();
    
    // Filter by status if needed
    if (status.toLowerCase() == 'all' || status.isEmpty) {
      return allOrders;
    }
    
    // Map English status to Vietnamese for comparison
    String vietnameseStatus;
    switch (status.toLowerCase()) {
      case 'assigned':
        vietnameseStatus = 'Chờ xử lý';  // Updated to match mock data
        break;
      case 'processing':
        vietnameseStatus = 'Đang giao';  // Updated to match mock data
        break;
      case 'completed':
        vietnameseStatus = 'Đã giao';    // Updated to match mock data
        break;
      default:
        vietnameseStatus = status;
    }
    
    // Return filtered orders
    return allOrders.where((order) => 
      order.status.toLowerCase() == vietnameseStatus.toLowerCase()
    ).toList();
  }
  
  // Helper method for debugging
  List<String> getAvailableStatuses() {
    final orders = MockData.getMockOrders();
    return orders.map((o) => o.status).toSet().toList();
  }
}
