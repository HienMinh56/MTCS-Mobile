import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'package:driverapp/services/auth_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/io.dart';

class MyTaskHandler extends TaskHandler {
  Timer? _timer;
  late IOWebSocketChannel _channel;
  String _userId = '';

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _userId = await AuthService.getUserId() ?? '';
    final uri = Uri.parse("wss://mtcs-server.azurewebsites.net/ws?userId=$_userId");
    _channel = IOWebSocketChannel.connect(uri.toString());

    _timer = Timer.periodic(Duration(seconds: 10), (_) async {
      Position position = await Geolocator.getCurrentPosition();
      final data = {
        'type': 'location_update',
        'userId': _userId,
        'Latitude': position.latitude,
        'Longitude': position.longitude,
      };
      print('Location updated: ${position.latitude}, ${position.longitude}');
      _channel.sink.add(jsonEncode(data));
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final data = {
        'type': 'location_update',
        'userId': _userId,
        'Latitude': position.latitude,
        'Longitude': position.longitude,
      };
      _channel.sink.add(jsonEncode(data));
      print('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error in onRepeatEvent: $e');
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    _timer?.cancel();
    _channel.sink.close();
  }
}
