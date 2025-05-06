import 'package:driverapp/models/trip.dart';
import 'package:driverapp/utils/api_utils.dart';

class TripService {
  
  // Thêm tham số để lấy dữ liệu order từ API nếu không có sẵn
  Future<List<Trip>> getDriverTrips(String driverId, {required String status, bool loadOrderDetails = false}) async {
    // First get the trips using safeApiCall
    List<Trip> trips = await ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/trips',
        queryParams: {
          'driverId': driverId,
          'status': status
        }
      ),
      onSuccess: (responseData) {
        if (responseData['data'] == null) {
          return <Trip>[];
        }
        
        final List<dynamic> tripsJson = responseData['data'];
        return tripsJson.map((json) => Trip.fromJson(json)).toList();
      },
      defaultValue: <Trip>[],
      defaultErrorMessage: 'Không thể tải danh sách chuyến'
    );
    
    // Then load order details separately if needed
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
  }

  // Thêm phương thức mới để sử dụng API gộp (trips/getTripsMo)
  Future<List<Trip>> getDriverTripsByGroup(String driverId, {required String groupType}) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/trips/getTripsMo',
        queryParams: {
          'driverId': driverId,
          'groupType': groupType
        }
      ),
      onSuccess: (responseData) {
        if (responseData['data'] == null) {
          return <Trip>[];
        }
        
        final List<dynamic> tripsJson = responseData['data'];
        return tripsJson.map((json) => Trip.fromMoJson(json)).toList();
      },
      defaultValue: <Trip>[],
      defaultErrorMessage: 'Không thể tải danh sách chuyến'
    );
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
        // Sử dụng safeApiCall để tránh exception khi gọi API
        final orderData = await ApiUtils.safeApiCall(
          apiCall: () => ApiUtils.get(
            '/api/order/orders',
            queryParams: {'tripId': trip.tripId}
          ),
          onSuccess: (data) {
            if (data['status'] == 1 && data['data'] != null && data['data'].isNotEmpty) {
              return data['data'][0];
            } else {
              return null;
            }
          },
          defaultValue: null,
          defaultErrorMessage: 'Không thể tải thông tin đơn hàng'
        );
        
        if (orderData != null) {
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
    } catch (e) {
      // Không throw exception để không làm fail toàn bộ quá trình load
      print('❌ Lỗi khi tải thông tin order cho chuyến ${trip.tripId}: $e');
    }
  }

  // Method to get detailed information about a specific trip
  Future<Trip> getTripDetail(String tripId) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.get(
        '/api/trips',
        queryParams: {'tripId': tripId}
      ),
      onSuccess: (responseData) {
        if (responseData['data'] != null && responseData['data'].isNotEmpty) {
          // API trả về một mảng, lấy phần tử đầu tiên
          return Trip.fromJson(responseData['data'][0]);
        } else {
          throw Exception('Không tìm thấy thông tin chuyến');
        }
      },
      defaultValue: Trip(
        tripId: tripId, 
        driverId: '', 
        status: 'unknown', 
        statusName: 'Không xác định',
        orderId: '',
      ),
      defaultErrorMessage: 'Không thể tải thông tin chi tiết chuyến'
    );
  }

  // Phương thức này không cần thiết nữa vì thông tin order đã được bao gồm trong trip
  // Chỉ giữ lại cho khả năng tương thích với mã hiện tại
  Future<Map<String, dynamic>> getOrderByTripId(String tripId) async {
    return ApiUtils.safeApiCall(
      apiCall: () async {
        final trip = await getTripDetail(tripId);
        if (trip.order != null) {
          return ApiUtils.get('/api/trips', queryParams: {'tripId': tripId});
        } else {
          return ApiUtils.get('/api/order/orders', queryParams: {'tripId': tripId});
        }
      },
      onSuccess: (data) {
        // Nếu đã lấy được dữ liệu từ trip
        if (data['data'] != null && data['data'].isNotEmpty) {
          final tripData = data['data'][0];
          if (tripData['order'] != null) {
            return tripData['order'];
          }
        }
        
        // Nếu lấy dữ liệu từ order API
        if (data['data'] != null && data['data'].isNotEmpty) {
          return data['data'][0];
        }
        
        return <String, dynamic>{};
      },
      defaultValue: <String, dynamic>{},
      defaultErrorMessage: 'Không thể tải thông tin đơn hàng'
    );
  }

  Future<Map<String, dynamic>> updateTripStatus(String tripId, String newStatus) async {
    return ApiUtils.safeApiCall(
      apiCall: () => ApiUtils.patch(
        '/api/trips/$tripId/status',
        newStatus
      ),
      onSuccess: (data) {
        return {
          'success': data['status'] == 200 || data['status'] == 1,
          'message': data['message'] ?? data['messageVN'] ?? 'Cập nhật trạng thái thành công',
          'newStatus': newStatus,
        };
      },
      defaultValue: {
        'success': false,
        'message': 'Lỗi khi cập nhật trạng thái chuyến',
        'newStatus': null,
      },
      defaultErrorMessage: 'Không thể cập nhật trạng thái chuyến'
    );
  }
}
