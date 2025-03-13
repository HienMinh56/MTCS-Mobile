class OrderService {
  // Simulate fetching order counts from a backend
  Future<Map<String, int>> getOrderCounts(String userId) async {
    // This would normally be an API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'assigned': 3,
      'processing': 1,
      'completed': 12,
    };
  }
  
  // Simulate fetching orders by their status
  Future<List<Map<String, dynamic>>> getOrdersByStatus(
    String userId, 
    String status
  ) async {
    // This would normally be an API call
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return dummy data for demonstration
    return List.generate(
      status == 'assigned' ? 3 : (status == 'processing' ? 1 : 12),
      (index) => {
        'id': 'ORD-${1000 + index}',
        'status': status,
        'destination': 'Port ${index + 1}',
        'containerNumber': 'CONT${10000 + index}',
        'timestamp': DateTime.now().toString(),
      },
    );
  }
}
