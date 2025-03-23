class Trip {
  final String tripId;
  final String orderId;
  final String driverId;
  final String tractorId;
  final String trailerId;
  final String distance;
  final String matchType;
  final String matchBy;
  final String matchTime;
  String status;

  Trip({
    required this.tripId,
    required this.orderId,
    required this.driverId,
    required this.tractorId,
    required this.trailerId,
    required this.distance,
    required this.matchType,
    required this.matchBy,
    required this.matchTime,
    required this.status,
  });
}

// Trip status constants
class TripStatus {
  static const String notStarted = 'Chưa bắt đầu';
  static const String started = 'Đã bắt đầu';  // New status
  static const String onLoadingGoods = 'Đang bốc hàng';
  static const String onDelivery = 'Đang trên đường vận chuyển';
  static const String finished = 'Đã hoàn thành vận chuyển';

  // Get next status in the flow
  static String? getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case notStarted:
        return started;
      case started:
        return onLoadingGoods;
      case onLoadingGoods:
        return onDelivery;
      case onDelivery:
        return finished;
      case finished:
        return null; // No next status
      default:
        return null;
    }
  }
}
