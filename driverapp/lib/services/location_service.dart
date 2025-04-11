import 'dart:async';
import 'dart:convert';
import 'package:driverapp/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/io.dart';

class LocationService {
  late IOWebSocketChannel _channel;
  bool _isInitialized = false;
  String _userId = '';

  Timer? _locationTimer;

Future<void> init(String userId) async {
  if (_isInitialized) return;
  _userId = userId;

  // Check permission như cũ
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return;
  }

  // Kết nối WebSocket
  print("🔌 Connecting WebSocket...");
  _channel = IOWebSocketChannel.connect("wss://mtcs-server.azurewebsites.net/ws");
  _isInitialized = true;
  print("✅ WebSocket connected");

  // Gửi vị trí mỗi 5 phút
  _locationTimer = Timer.periodic(Duration(minutes: 1), (_) async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
      final token = await AuthService.getAuthToken();
    final data = {
      'type': 'location_update',
      'userId': _userId,
      'lat': position.latitude,
      'lng': position.longitude,
      'token':token,
    };

    print('📡 Sending location: $data');
    _channel.sink.add(jsonEncode(data));
  });
}

void dispose() {
  if (_isInitialized) {
    _channel.sink.close();
    _locationTimer?.cancel();
    _isInitialized = false;
  }
}
}