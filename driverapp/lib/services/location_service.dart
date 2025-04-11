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


  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
  }
  if (permission == LocationPermission.deniedForever) return;


  final token = await AuthService.getAuthToken();


  final uri = Uri.parse("wss://mtcs-server.azurewebsites.net/ws?userId=$_userId&token=$token&action=send");
  _channel = IOWebSocketChannel.connect(uri.toString());
  _isInitialized = true;


  _locationTimer = Timer.periodic(Duration(seconds: 10), (_) async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final data = {
      'type': 'location_update',
      'userId': _userId,
      'Latitude': position.latitude,
      'Longitude': position.longitude,
    };

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