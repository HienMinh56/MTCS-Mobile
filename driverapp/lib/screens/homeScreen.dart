import 'package:driverapp/components/function_card.dart';
import 'package:driverapp/models/delivery_status.dart';
import 'package:driverapp/screens/notificationScreen.dart';
import 'package:driverapp/services/auth_service.dart';
import 'package:driverapp/services/delivery_status_service.dart';
import 'package:driverapp/services/navigation_service.dart';
import 'package:driverapp/services/notification_service.dart';
import 'package:driverapp/services/profile_service.dart';
import 'package:driverapp/services/working_time_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:flutter/material.dart';

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
  
  int _unreadNotifications = 0;
  bool _isLoading = true;
  String _weeklyWorkingTime = '0 giờ 0 phút';
  String _dailyWorkingTime = '0 giờ 0 phút';
  List<DeliveryStatus> _deliveryStatuses = [];
  String _driverName = '';
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadUnreadNotificationCount();
      });
    } catch (e) {
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
        .map((s) => s.statusIndex)
        .reduce((a, b) => a < b ? a : b);
    
    return _deliveryStatuses
        .where((status) => status.statusIndex == minIndex)
        .map((status) => status.statusId)
        .toList();
  }
  
  List<String> _getCompletedStatuses() {
    if (_deliveryStatuses.isEmpty) return ["completed", "canceled"];
    
    final maxIndex = _deliveryStatuses
        .map((s) => s.statusIndex)
        .reduce((a, b) => a > b ? a : b);
    
    return _deliveryStatuses
        .where((status) => 
          status.statusIndex == maxIndex || status.statusId == "canceled")
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
      
      if (mounted) {
        Future.delayed(const Duration(seconds: 30), () {
          _loadUnreadNotificationCount();
        });
      }
    } catch (e) {
      if (mounted) {
        Future.delayed(const Duration(seconds: 30), () {
          _loadUnreadNotificationCount();
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
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
        child: Padding(
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

                      SizedBox(
                        height: 450,
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            FunctionCard(
                              title: "Trip Chưa Bắt Đầu",
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
                              title: "Trip Đang Xử Lý",
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
                              title: "Trip Đã Hoàn Thành",
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
      ),
    );
  }
}
