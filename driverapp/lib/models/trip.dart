import '../services/status_manager.dart';

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
      // Use StatusManager first, fall back to local mapping
      statusName: StatusManager.getStatusName(json['status']) ?? _getStatusName(json['status']),
    );
  }

  // Helper method to convert status codes to display names (fallback)
  static String _getStatusName(String? statusId) {
    final Map<String, String> statusMap = {
      'not_started': 'Chưa bắt đầu',
      'going_to_port': 'Đang đến cảng',
      'pick_up_container': 'Đang lấy container',
      'picking_up_goods': 'Đang lấy hàng',
      'is_delivering': 'Đang trên đường giao',
      'at_delivery_point': 'Đang ở điểm giao',
      'canceled': 'Đã hủy chuyến',
      'delaying': 'Đang delay',
      'going_to_port/depot': 'Đang đến điểm giao/trả container',
      'completed': 'Đã hoàn thành',
    };
    
    return statusMap[statusId] ?? statusId ?? 'Unknown';
  }
  
  // Method to update status name from latest mapping
  void refreshStatusName() {
    String? updatedName = StatusManager.getStatusName(status);
    if (updatedName != null) {
      statusName = updatedName;
    }
  }
}
