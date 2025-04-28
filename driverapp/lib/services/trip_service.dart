import 'dart:convert';
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/utils/api_utils.dart';

class TripService {
  
  // Thêm tham số để lấy dữ liệu order từ API nếu không có sẵn
  Future<List<Trip>> getDriverTrips(String driverId, {required String status, bool loadOrderDetails = false}) async {
    try {
      final response = await ApiUtils.get(
        '/api/trips',
        queryParams: {
          'driverId': driverId,
          'status': status
        }
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200) {
          final List<dynamic> tripsJson = responseData['data'];
          List<Trip> trips = tripsJson.map((json) => Trip.fromJson(json)).toList();
          
          // Nếu cần tải thông tin order và có trip không có thông tin order
          if (loadOrderDetails) {
            int tripsWithoutOrder = trips.where((trip) => trip.order == null).length;
            
            if (tripsWithoutOrder > 0) {
              // Tạo danh sách các chuyến cần tải thông tin đơn hàng
              final List<Future<void>> orderLoads = [];
              
              for (int i = 0; i < trips.length; i++) {
                if (trips[i].order == null) {
                  // Thêm task vào danh sách các task cần thực hiện
                  orderLoads.add(_loadOrderForTrip(trips[i]));
                }
              }
              
              // Thực hiện tất cả các task tải đơn hàng song song
              if (orderLoads.isNotEmpty) {
                await Future.wait(orderLoads);
              }
            }
          }
          
          return trips;
        } else {
          throw Exception('API error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load trips: $e');
    }
  }

  // Hàm riêng để tải thông tin đơn hàng cho một chuyến
  Future<void> _loadOrderForTrip(Trip trip) async {
    try {
      // Sử dụng getTripDetail trước để thử lấy thông tin mới nhất
      final tripDetail = await getTripDetail(trip.tripId);
      
      if (tripDetail.order != null) {
        // Nếu order đã có trong trip detail, sử dụng nó luôn
        trip.order = tripDetail.order;
      } else {
        // Gọi API riêng để lấy thông tin order
        final response = await ApiUtils.get(
          '/api/order/orders',
          queryParams: {'tripId': trip.tripId}
        );
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['status'] == 1 && data['data'] != null && data['data'].isNotEmpty) {
            final orderData = data['data'][0];
            trip.order = Order(
              orderId: orderData['orderId'] ?? '',
              trackingCode: orderData['trackingCode'] ?? '',
              pickUpLocation: orderData['pickUpLocation'] ?? '',
              deliveryLocation: orderData['deliveryLocation'] ?? '',
              conReturnLocation: orderData['conReturnLocation'] ?? '',
              containerNumber: orderData['containerNumber'] ?? '',
              contactPerson: orderData['contactPerson'] ?? '',
              contactPhone: orderData['contactPhone'] ?? '',
              deliveryDate: orderData['deliveryDate'] ?? '',
            );
          }
        }
      }
    } catch (e) {
      // Không throw exception để không làm fail toàn bộ quá trình load
    }
  }

  // Method to get detailed information about a specific trip
  Future<Trip> getTripDetail(String tripId) async {
    try {
      final response = await ApiUtils.get(
        '/api/trips',
        queryParams: {'tripId': tripId}
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200 && responseData['data'] != null && responseData['data'].isNotEmpty) {
          // API trả về một mảng, lấy phần tử đầu tiên
          return Trip.fromJson(responseData['data'][0]);
        } else {
          throw Exception('Không tìm thấy thông tin chuyến');
        }
      } else {
        throw Exception('Failed to load trip details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load trip details: $e');
    }
  }

  // Phương thức này không cần thiết nữa vì thông tin order đã được bao gồm trong trip
  // Chỉ giữ lại cho khả năng tương thích với mã hiện tại
  Future<Map<String, dynamic>> getOrderByTripId(String tripId) async {
    try {
      final trip = await getTripDetail(tripId);
      if (trip.order != null) {
        return {
          'orderId': trip.order!.orderId,
          'trackingCode': trip.order!.trackingCode,
          'pickUpLocation': trip.order!.pickUpLocation,
          'deliveryLocation': trip.order!.deliveryLocation,
          'conReturnLocation': trip.order!.conReturnLocation,
          'containerNumber': trip.order!.containerNumber,
          'contactPerson': trip.order!.contactPerson,
          'contactPhone': trip.order!.contactPhone,
        };
      } else {
        // Gọi API cũ để tương thích ngược
        final response = await ApiUtils.get(
          '/api/order/orders',
          queryParams: {'tripId': tripId}
        );
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['status'] == 1) {
            return data['data'][0];
          } else {
            throw Exception('API error: ${data['message']}');
          }
        } else {
          throw Exception('Failed to load order details: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Failed to load order details: $e');
    }
  }

  Future<Map<String, dynamic>> updateTripStatus(String tripId, String newStatus) async {
    try {
      final response = await ApiUtils.patch(
        '/api/trips/$tripId/status',
        newStatus
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': data['status'] == 200,
          'message': data['message'],
          'newStatus': newStatus,
        };
      } else {
        throw Exception('Failed to update trip status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update trip status: $e');
    }
  }
}
