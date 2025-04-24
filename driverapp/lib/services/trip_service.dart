import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driverapp/models/trip.dart';
import 'package:driverapp/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripService {
  final String _baseUrl = Constants.apiBaseUrl;
  
  // Thêm tham số để lấy dữ liệu order từ API nếu không có sẵn
  Future<List<Trip>> getDriverTrips(String driverId, {required String status, bool loadOrderDetails = true}) async {
    try {
      // Retrieve the saved token from secure storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      
      // Create headers with authentication token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/api/trips?driverId=$driverId&status=$status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200) {
          final List<dynamic> tripsJson = responseData['data'];
          List<Trip> trips = tripsJson.map((json) => Trip.fromJson(json)).toList();
          
          // Nếu cần tải thông tin order và trip không có thông tin order
          if (loadOrderDetails) {
            for (int i = 0; i < trips.length; i++) {
              if (trips[i].order == null) {
                try {
                  // Gọi API riêng để lấy thông tin order nếu không có sẵn trong trip
                  final orderData = await getOrderByTripId(trips[i].tripId);
                  trips[i].order = Order(
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
                } catch (e) {
                  print('Lỗi tải chuyến ${trips[i].tripId}: $e');
                }
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

  // Method to get detailed information about a specific trip
  Future<Trip> getTripDetail(String tripId) async {
    try {
      // Retrieve the saved token from secure storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      
      // Create headers with authentication token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/trips?tripId=$tripId'),
        headers: headers,
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
        // Retrieve the saved token from secure storage
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken') ?? '';
        
        // Create headers with authentication token
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        
        // Gọi API cũ để tương thích ngược
        final response = await http.get(
          Uri.parse('$_baseUrl/api/order/orders?tripId=$tripId'),
          headers: headers,
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
    final url = '$_baseUrl/api/trips/$tripId/status';
    
    try {
      // Retrieve the saved token from secure storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      
      // Create headers with authentication token
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: json.encode(newStatus),
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
