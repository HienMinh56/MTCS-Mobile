import '../services/status_manager.dart';

class Order {
  final String orderId;
  final String trackingCode;
  final String pickUpLocation;
  final String deliveryLocation;
  final String conReturnLocation;
  final String containerNumber;
  final String contactPerson;
  final String contactPhone;

  Order({
    required this.orderId,
    required this.trackingCode,
    required this.pickUpLocation,
    required this.deliveryLocation,
    required this.conReturnLocation,
    required this.containerNumber,
    required this.contactPerson,
    required this.contactPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'] ?? '',
      trackingCode: json['trackingCode'] ?? '',
      pickUpLocation: json['pickUpLocation'] ?? '',
      deliveryLocation: json['deliveryLocation'] ?? '',
      conReturnLocation: json['conReturnLocation'] ?? '',
      containerNumber: json['containerNumber'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
    );
  }
}

class Trip {
  final String tripId;
  final String orderId;
  final String trackingCode;
  final String driverId;
  final String? tractorId;
  final String? trailerId;
  final DateTime? startTime;
  final DateTime? endTime;
  String status;  // Changed from final to allow updates
  String statusName; // Changed from final to allow updates
  Order? order;  // Changed from final to allow updates
  
  // Thêm các trường mới
  final int? matchType;
  final String? matchBy;
  final DateTime? matchTime;
  final List<dynamic>? tripStatusHistories;

  Trip({
    required this.tripId,
    required this.orderId,
    this.trackingCode = '',
    required this.driverId,
    this.tractorId,
    this.trailerId,
    this.startTime,
    this.endTime,
    required this.status,
    required this.statusName,
    this.order,
    this.matchType,
    this.matchBy, 
    this.matchTime,
    this.tripStatusHistories,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['tripId'] ?? '',
      orderId: json['orderId'] ?? '',
      trackingCode: json['trackingCode'] ?? '',
      driverId: json['driverId'] ?? '',
      tractorId: json['tractorId'],
      trailerId: json['trailerId'],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: json['status'] ?? '',
      // Use StatusManager first, fall back to local mapping
      statusName: StatusManager.getStatusName(json['status']) ?? _getStatusName(json['status']),
      order: json['order'] != null ? Order.fromJson(json['order']) : null,
      matchType: json['matchType'],
      matchBy: json['matchBy'],
      matchTime: json['matchTime'] != null ? DateTime.parse(json['matchTime']) : null,
      tripStatusHistories: json['tripStatusHistories'],
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
