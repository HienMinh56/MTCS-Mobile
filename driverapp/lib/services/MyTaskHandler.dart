import 'dart:async';
import 'dart:isolate';
import 'package:driverapp/services/auth_service.dart';
import 'package:driverapp/services/location_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signalr_core/signalr_core.dart';

class MyTaskHandler extends TaskHandler {
  Timer? _timer;
  late HubConnection _connection;
  String? _token;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  bool _isServiceRunning = false;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Đánh dấu dịch vụ đã bắt đầu chạy
    _isServiceRunning = true;
    
    _token = await AuthService.getAuthToken();

    await _initSignalRConnection();

    // Gửi vị trí mỗi 5 giây
    _timer = Timer.periodic(Duration(seconds: 5), (_) async {
      if (_isServiceRunning) {
        await _sendLocation();
      }
    });
  }

  Future<void> _initSignalRConnection() async {
    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            'https://mtcs-server.azurewebsites.net/locationHub',
            HttpConnectionOptions(
              accessTokenFactory: () async => _token!,
              // Sử dụng ServerSentEvents để tương thích tốt hơn
              transport: HttpTransportType.serverSentEvents,
              skipNegotiation: false,
              logging: (level, message) => print('ForegroundTask: SignalR Log: $message'),
            ),
          )
          .withAutomaticReconnect()
          .build();

      // Xử lý khi kết nối bị ngắt
      _connection.onclose((error) async {
        if (_reconnectAttempts < _maxReconnectAttempts && _isServiceRunning) {
          _reconnectAttempts++;
          await Future.delayed(Duration(seconds: 3 * _reconnectAttempts));
          await _initSignalRConnection();
        }
      });

      // Bắt đầu kết nối với xử lý lỗi tốt hơn
      try {
        await _connection.start();
        _reconnectAttempts = 0;
      } catch (e) {
        throw e;
      }
    } catch (e) {
      if (_reconnectAttempts < _maxReconnectAttempts && _isServiceRunning) {
        _reconnectAttempts++;
        await Future.delayed(Duration(seconds: 3 * _reconnectAttempts));
        await _initSignalRConnection();
      }
    }
  }

  Future<void> _sendLocation() async {
    try {
      if (!_isServiceRunning) return;
      
      if (_connection.state == HubConnectionState.connected) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        );

        await _connection.invoke('SendLocation', args: [
          _token,
          position.latitude,
          position.longitude
        ]);
      } else if (_connection.state == HubConnectionState.disconnected) {
        if (_reconnectAttempts < _maxReconnectAttempts && _isServiceRunning) {
          await _initSignalRConnection();
        }
      }
    } catch (e) {
      // Ghi log lỗi thay vì throw exception để tránh crash task handler
      print('Error sending location: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    if (_isServiceRunning) {
      await _sendLocation();
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    try {
      _isServiceRunning = false;
      _timer?.cancel();
      if (_connection.state != HubConnectionState.disconnected) {
        _connection.stop();
      }
      // Đảm bảo dừng dịch vụ vị trí khi foreground task bị hủy (khi app bị kill)
      LocationService.stopLocationService();
    } catch (e) {
      print('Error stopping location service: $e');
    }
  }

  @override
  void onNotificationPressed() {
    // Xử lý khi người dùng nhấn vào thông báo
    FlutterForegroundTask.launchApp();
  }
}

