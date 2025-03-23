import 'package:driverapp/models/order.dart';
import 'package:driverapp/data/mock_data.dart';

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
  
  // Fixed method to update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Since Order.status is final, we need to replace the order
    // with a new instance that has the updated status
    final allOrders = MockData.getMockOrders();
    final orderIndex = allOrders.indexWhere((order) => order.orderId == orderId);
    
    if (orderIndex != -1) {
      final oldOrder = allOrders[orderIndex];
      // Create a new order with updated status
      // This assumes we have a copyWith method or a constructor that takes all fields
      final updatedOrder = Order(
        orderId: oldOrder.orderId,
        customerName: oldOrder.customerName,
        creator: oldOrder.creator,
        deliveryDate: oldOrder.deliveryDate,
        deliveryLocation: oldOrder.deliveryLocation,
        status: newStatus, // Updated status
        // Add any other required fields from the Order class
      );
      
      // Replace the old order with the updated one
      allOrders[orderIndex] = updatedOrder;
      return true;
    }
    
    return false;
  }
  
  // Helper method for debugging
  List<String> getAvailableStatuses() {
    final orders = MockData.getMockOrders();
    return orders.map((o) => o.status).toSet().toList();
  }
}
