class Trip {
  final String tripId;
  final String orderId;
  final String driverId;
  final String? tractorId;
  final String? trailerId;
  final DateTime? startTime;
  final DateTime? endTime;
  String status;  // Changed from final to allow updates
  String statusName; // Changed from final to allow updates

  Trip({
    required this.tripId,
    required this.orderId,
    required this.driverId,
    this.tractorId,
    this.trailerId,
    this.startTime,
    this.endTime,
    required this.status,
    required this.statusName,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['tripId'] ?? '',
      orderId: json['orderId'] ?? '',
      driverId: json['driverId'] ?? '',
      tractorId: json['tractorId'],
      trailerId: json['trailerId'],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: json['status'] ?? '',
      // Map the status ID to a display name based on your API response
      statusName: _getStatusName(json['status']),
    );
  }

  // Helper method to convert status codes to display names
  static String _getStatusName(String? statusId) {
    final Map<String, String> statusMap = {
      'not_started': 'Chưa bắt đầu',
      'going_to_port': 'Đang đến cảng',
      'picking_up_goods': 'Đang bốc dỡ hàng',
      'is_delivering': 'Đang trên đường giao',
      'at_delivery_point': 'Đang ở điểm giao',
      'canceled': 'Đã hủy chuyến',
      'delaying': 'Đang delay',
      'completed': 'Đã hoàn thành',
    };
    
    return statusMap[statusId] ?? statusId ?? 'Unknown';
  }
}
