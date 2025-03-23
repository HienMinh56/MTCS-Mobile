import 'package:driverapp/models/trip.dart';

class MockTrips {
  static final Map<String, Trip> _trips = {};

  static Trip getDefaultTrip(String orderId) {
    // Return existing trip if it exists
    if (_trips.containsKey(orderId)) {
      return _trips[orderId]!;
    }

    // Create a new trip if it doesn't exist
    final trip = Trip(
      tripId: 'T${orderId.substring(1)}', // Create tripId from orderId
      orderId: orderId,
      driverId: 'D001',
      tractorId: 'TR001',
      trailerId: 'TL001',
      distance: '120 km',
      matchType: 'Tự động',
      matchBy: 'Hệ thống',
      matchTime: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      status: TripStatus.notStarted,
    );

    // Store trip for future reference
    _trips[orderId] = trip;
    
    return trip;
  }

  static void updateTripStatus(String orderId, String newStatus) {
    if (_trips.containsKey(orderId)) {
      _trips[orderId]!.status = newStatus;
    }
  }
}
