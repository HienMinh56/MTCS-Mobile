import 'dart:async';
import 'package:driverapp/services/auth_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signalr_core/signalr_core.dart';

class LocationService {
  late HubConnection _connection;
  bool _isInitialized = false;
  bool _isTracking = false;
  String? _token;
  Timer? _locationTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  // Chỉ kiểm tra quyền và chuẩn bị token, không bắt đầu theo dõi
  Future<void> init(String userId) async {
    if (_isInitialized) return;
    _token = await AuthService.getAuthToken();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _isInitialized = true;
    // Không gọi _initSignalRConnection() ở đây nữa
  }

  // Phương thức mới để bắt đầu theo dõi vị trí khi người dùng nhấn nút
  Future<void> startTracking() async {
    if (!_isInitialized || _isTracking) return;
    
    await _initSignalRConnection();
    _isTracking = true;
  }

  // Phương thức mới để dừng theo dõi vị trí
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    
    try {
      if (_connection.state != HubConnectionState.disconnected) {
        await _connection.stop();
      }
      _locationTimer?.cancel();
      _isTracking = false;
    } catch (e) {
      print('Error stopping tracking: $e');
    }
  }

  Future<void> _initSignalRConnection() async {
    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            'https://mtcs-server.azurewebsites.net/locationHub',
            HttpConnectionOptions(
              accessTokenFactory: () async => _token!,
              // Using ServerSentEvents instead of WebSockets for better compatibility
              transport: HttpTransportType.serverSentEvents,
              skipNegotiation: false,
              logging: (level, message) => print('LocationService: SignalR Log: $message'),
            ),
          )
          .withAutomaticReconnect()
          .build();

      // Xử lý khi kết nối bị ngắt
      _connection.onclose((error) async {
        if (_reconnectAttempts < _maxReconnectAttempts && _isTracking) {
          _reconnectAttempts++;
          await Future.delayed(Duration(seconds: 3 * _reconnectAttempts));
          await _initSignalRConnection();
        }
      });

      // Bắt đầu kết nối với xử lý lỗi tốt hơn
      try {
        await _connection.start();
        _reconnectAttempts = 0;

        // Bắt đầu gửi vị trí sau khi kết nối thành công
        _startLocationUpdates();
      } catch (e) {
        throw e;
      }
    } catch (e) {
      if (_reconnectAttempts < _maxReconnectAttempts && _isTracking) {
        _reconnectAttempts++;
        await Future.delayed(Duration(seconds: 3 * _reconnectAttempts));
        await _initSignalRConnection();
      }
    }
  }

  void _startLocationUpdates() {
    // Hủy timer cũ nếu có
    _locationTimer?.cancel();
    
    // Tạo timer mới để gửi vị trí định kỳ
    _locationTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      await _sendLocation();
    });
  }

  Future<void> _sendLocation() async {
    try {
      if (!_isTracking) return;
      
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
        if (_reconnectAttempts < _maxReconnectAttempts && _isTracking) {
          await _initSignalRConnection();
        }
      }
    } catch (e) {
      throw e;
    }
  }

  Future<bool> isConnected() async {
    return _isTracking && _connection.state == HubConnectionState.connected;
  }

  Future<bool> isTracking() async {
    return _isTracking;
  }

  // Thêm phương thức mới để dừng dịch vụ vị trí khi ứng dụng bị kill
  static Future<void> stopLocationService() async {
    try {
      // Kiểm tra xem dịch vụ foreground task có đang chạy không
      bool isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning) {
        // Dừng dịch vụ foreground nếu đang chạy
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      print('Error stopping location service: $e');
    }
  }

  void dispose() {
    try {
      if (_isTracking) {
        _connection.stop();
        _locationTimer?.cancel();
        _isTracking = false;
      }
      _isInitialized = false;
      _reconnectAttempts = 0;
    } catch (e) {
      throw e;
    }
  }
}