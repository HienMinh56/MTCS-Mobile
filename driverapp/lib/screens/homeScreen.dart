import 'dart:async';
import 'package:driverapp/components/function_card.dart';
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/screens/notificationScreen.dart';
import 'package:driverapp/services/auth_service.dart';
import 'package:driverapp/services/chat_service.dart';
import 'package:driverapp/services/delivery_status_service.dart';
import 'package:driverapp/services/MyTaskHandler.dart';
import 'package:driverapp/services/location_service.dart';
import 'package:driverapp/services/navigation_service.dart';
import 'package:driverapp/services/notification_service.dart';
import 'package:driverapp/services/profile_service.dart';
import 'package:driverapp/services/working_time_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NavigationService _navigationService = NavigationService();
  final NotificationService _notificationService = NotificationService();
  final ProfileService _profileService = ProfileService();
  final DeliveryStatusService _deliveryStatusService = DeliveryStatusService();
  final WorkingTimeService _workingTimeService = WorkingTimeService();
  final LocationService _locationService = LocationService();
  final ChatService _chatService = ChatService();

  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  bool _isLoading = true;
  String _weeklyWorkingTime = '0 giờ 0 phút';
  String _dailyWorkingTime = '0 giờ 0 phút';
  List<DeliveryStatus> _deliveryStatuses = [];
  String _driverName = '';
  bool _isTrackingActive = false;
  
  // Thêm các biến để quản lý timer
  Timer? _notificationsTimer;
  Timer? _messagesTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _checkIfForegroundServiceRunning();
    _loadUnreadMessagesCount();
  }

  Future<void> _checkIfForegroundServiceRunning() async {
    bool isRunning = await FlutterForegroundTask.isRunningService;
    setState(() {
      _isTrackingActive = isRunning;
    });
    
    // Only initialize LocationService if foreground service is not running
    if (!isRunning) {
      await _initLocationService();
    }
  }
  
  Future<void> _initLocationService() async {
    // Chỉ khởi tạo LocationService mà không bắt đầu theo dõi vị trí
    await _locationService.init(widget.userId);
  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_tracking_service',
        channelName: 'Location Tracking Service',
        channelDescription: 'Theo dõi vị trí',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> _checkRequiredPermissions() async {
    try {
      // Check and request location permission
      final locationPermission = await Geolocator.checkPermission();
      
      if (locationPermission == LocationPermission.denied) {
        final requestResult = await Geolocator.requestPermission();
        if (requestResult == LocationPermission.denied || 
            requestResult == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quyền truy cập vị trí bị từ chối. Không thể bắt đầu làm việc.'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      } else if (locationPermission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng vào cài đặt để bật quyền.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      // For Android 12+, check notification permission
      if (await Permission.notification.status.isDenied) {
        final status = await Permission.notification.request();
        if (status.isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quyền thông báo bị từ chối. Không thể hiển thị thông báo.'),
              backgroundColor: Colors.red,
            ),
          );
          // Continue even if notification permission is denied
        }
      }
      
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi kiểm tra quyền: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  Future<void> startForegroundLocationService() async {
    try {
      // Show confirmation dialog before starting the service
      bool confirmStart = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue.shade700,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bắt đầu làm việc',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sau khi bắt đầu, ứng dụng sẽ theo dõi vị trí của bạn. Vui lòng không tắt ứng dụng trong lúc làm việc để đảm bảo chia sẻ vị trí liên tục.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.grey.shade200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Xác nhận',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ) ?? false;
      
      if (!confirmStart) return;
      
      // Check permissions before starting
      final hasPermissions = await _checkRequiredPermissions();
      if (!hasPermissions) return;
      
      await _initForegroundTask();
      
      bool reqResult = await FlutterForegroundTask.startService(
        notificationTitle: 'Dịch vụ theo dõi vị trí đang hoạt động',
        notificationText: 'Đang chia sẻ vị trí',
        callback: startCallback,
      );
      
      if (reqResult) {
        setState(() {
          _isTrackingActive = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể bắt đầu dịch vụ theo dõi vị trí'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> stopForegroundLocationService() async {
    bool reqResult = await FlutterForegroundTask.stopService();
    if (reqResult) {
      setState(() {
        _isTrackingActive = false;
      });
      
      // Reinitialize the LocationService when foreground service stops
      await _initLocationService();
    }
  }

  @override
  void dispose() {
    // Hủy các timer khi widget bị dispose
    _notificationsTimer?.cancel();
    _messagesTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadDriverProfile(),
        _loadDeliveryStatuses(),
        _loadWorkingTimes(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Sử dụng timer một lần thay vì Future.delayed
      Future.microtask(() {
        _loadUnreadNotificationCount();
      });
    } catch (e) {
      print('Lỗi khi tải dữ liệu ban đầu: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWorkingTimes() async {
    try {
      final weeklyTime = await _workingTimeService.getWeeklyWorkingTime(widget.userId);
      final dailyTime = await _workingTimeService.getDailyWorkingTime(widget.userId);

      if (mounted) {
        setState(() {
          _weeklyWorkingTime = weeklyTime;
          _dailyWorkingTime = dailyTime;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weeklyWorkingTime = '0 giờ 0 phút';
          _dailyWorkingTime = '0 giờ 0 phút';
        });
      }
    }
  }

  Future<void> _loadDeliveryStatuses() async {
    try {
      final statuses = await _deliveryStatusService.getDeliveryStatuses();
      if (mounted) {
        setState(() {
          _deliveryStatuses = statuses;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deliveryStatuses = [];
        });
      }
    }
  }

  List<String> _getNotStartedStatuses() {
    if (_deliveryStatuses.isEmpty) return ["not_started"];

    final minIndex = _deliveryStatuses
        .where((s) => s.isActive == 1) // Chỉ xem xét trạng thái active
        .map((s) => s.statusIndex)
        .reduce((a, b) => a < b ? a : b);

    return _deliveryStatuses
        .where((status) => status.statusIndex == minIndex && status.isActive == 1)
        .map((status) => status.statusId)
        .toList();
  }

  List<String> _getCompletedStatuses() {
    if (_deliveryStatuses.isEmpty) return ["completed", "canceled"];

    final maxIndex = _deliveryStatuses
        .where((s) => s.isActive == 1) // Chỉ xem xét trạng thái active
        .map((s) => s.statusIndex)
        .reduce((a, b) => a > b ? a : b);

    return _deliveryStatuses
        .where((status) =>
            (status.statusIndex == maxIndex || status.statusId == "canceled") && 
            status.isActive == 1)
        .map((status) => status.statusId)
        .toList();
  }

  List<String> _getInProgressStatuses() {
    if (_deliveryStatuses.isEmpty) {
      return [
        "going_to_port",
        "picking_up_goods",
        "is_delivering",
        "at_delivery_point",
        "delaying",
      ];
    }

    final notStartedIds = _getNotStartedStatuses();
    final completedIds = _getCompletedStatuses();

    return _deliveryStatuses
        .where((status) => status.isActive == 1) // Chỉ xem xét trạng thái active
        .map((status) => status.statusId)
        .where((statusId) =>
            !notStartedIds.contains(statusId) &&
            !completedIds.contains(statusId))
        .toList();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final profile = await _profileService.getDriverProfile(widget.userId);
      if (mounted) {
        setState(() {
          _driverName = profile.fullName;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _driverName = 'Lỗi tải thông tin';
        });
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadNotificationCount(widget.userId);

      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }

      // Hủy timer cũ nếu có
      _notificationsTimer?.cancel();
      
      // Tạo timer mới nếu widget vẫn mounted
      if (mounted) {
        _notificationsTimer = Timer(const Duration(seconds: 30), () {
          _loadUnreadNotificationCount();
        });
      }
    } catch (e) {
      print('Lỗi khi tải số lượng thông báo chưa đọc: $e');
      // Hủy timer cũ nếu có
      _notificationsTimer?.cancel();
      
      // Tạo timer mới nếu widget vẫn mounted
      if (mounted) {
        _notificationsTimer = Timer(const Duration(seconds: 30), () {
          _loadUnreadNotificationCount();
        });
      }
    }
  }

  // Sửa phương thức đếm số tin nhắn chưa đọc
  Future<void> _loadUnreadMessagesCount() async {
    try {
      final count = await _chatService.getUnreadMessageCount(widget.userId);
      
      if (mounted) {
        setState(() {
          _unreadMessages = count;
        });
      }
      
      // Hủy timer cũ nếu có
      _messagesTimer?.cancel();
      
      // Tạo timer mới nếu widget vẫn mounted
      if (mounted) {
        _messagesTimer = Timer(const Duration(seconds: 30), () {
          _loadUnreadMessagesCount();
        });
      }
    } catch (e) {
      print('Lỗi khi tải số lượng tin nhắn chưa đọc: $e');
      // Hủy timer cũ nếu có
      _messagesTimer?.cancel();
      
      // Tạo timer mới nếu widget vẫn mounted
      if (mounted) {
        _messagesTimer = Timer(const Duration(seconds: 30), () {
          _loadUnreadMessagesCount();
        });
      }
    }
  }

  void _forceRefreshNotifications() {
    _loadUnreadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset(
          'img/logo.png',
        ),
        actions: [
          // Icon chat
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 26),
                onPressed: () => _navigationService.navigateToChatList(
                  context, widget.userId
                ),
              ),
              if (_unreadMessages > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadMessages > 99 ? '99+' : _unreadMessages.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Icon notification
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, size: 28),
                onPressed: () {
                  _forceRefreshNotifications();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(userId: widget.userId),
                    ),
                  ).then((_) {
                    _forceRefreshNotifications();
                  });
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotifications > 99 ? '99+' : _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadUnreadNotificationCount(),
            _loadDriverProfile(),
            _loadDeliveryStatuses(),
            _loadWorkingTimes(),
          ]);
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundColor: Color(0xFFBBDEFB),
                                child: Icon(Icons.person, size: 35, color: Colors.blue),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Xin Chào, $_driverName',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Chúc bạn có một ngày làm việc hiệu quả và an toàn',
                                      style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 0, 4, 255), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Thời gian làm việc tuần này',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _weeklyWorkingTime,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.blue.shade200,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Thời gian làm việc hôm nay',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _dailyWorkingTime,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(
                                _isTrackingActive ? Icons.location_on : Icons.location_off,
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTrackingActive ? Colors.green : Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                if (_isTrackingActive) {
                                  stopForegroundLocationService();
                                } else {
                                  await startForegroundLocationService();
                                }
                              },
                              label: Text(
                                _isTrackingActive 
                                    ? "Dừng chia sẻ vị trí" 
                                    : "Bắt đầu làm việc",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),

                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: GridView.count(
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              childAspectRatio: 1.3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: [
                                FunctionCard(
                                  title: "Chuyến Chưa Bắt Đầu",
                                  icon: Icons.pending_actions,
                                  color: Colors.amber.shade700,
                                  onTap: () => _navigationService.navigateToTripList(
                                    context, 
                                    widget.userId, 
                                    status: "not_started",
                                    statusList: _getNotStartedStatuses(),
                                  ),
                                ),
                                FunctionCard(
                                  title: "Chuyến Đang Xử Lý",
                                  icon: Icons.directions_car,
                                  color: Colors.blue.shade700,
                                  onTap: () => _navigationService.navigateToTripList(
                                    context, 
                                    widget.userId, 
                                    status: "in_progress",
                                    statusList: _getInProgressStatuses(),
                                  ),
                                ),
                                FunctionCard(
                                  title: "Chuyến Đã Hoàn Thành",
                                  icon: Icons.check_circle,
                                  color: Colors.green.shade700,
                                  onTap: () => _navigationService.navigateToTripList(
                                    context, 
                                    widget.userId, 
                                    status: "completed",
                                    statusList: _getCompletedStatuses(),
                                  ),
                                ),
                                FunctionCard(
                                  title: "Lịch Sử Báo Cáo",
                                  icon: Icons.description,
                                  color: Colors.teal,
                                  onTap: () => _navigationService.navigateToReportMenu(
                                    context, widget.userId
                                  ),
                                ),
                                FunctionCard(
                                  title: "Hồ Sơ Của Tôi",
                                  icon: Icons.account_circle,
                                  color: ColorConstants.profileColor,
                                  onTap: () => _navigationService.navigateToProfile(
                                    context, widget.userId
                                  ),
                                ),
                                FunctionCard(
                                  title: "Đăng Xuất",
                                  icon: Icons.logout,
                                  color: Colors.red.shade400,
                                  onTap: () => AuthService.logoutConfirm(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ), 
          ],
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}
