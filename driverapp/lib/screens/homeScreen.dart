import 'package:driverapp/components/function_card.dart';
import 'package:driverapp/screens/notificationScreen.dart';
import 'package:driverapp/services/auth_service.dart';
import 'package:driverapp/services/navigation_service.dart';
import 'package:driverapp/services/notification_service.dart';
import 'package:driverapp/services/profile_service.dart';
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
  
  int _unreadNotifications = 0;
  bool _isLoading = true;
  int _totalWorkingTime = 0;
  int _currentWeekWorkingTime = 0;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    try {
      await _loadDriverProfile();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadUnreadNotificationCount();
      });
    } catch (e) {
      print("Error loading initial data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadDriverProfile() async {
    try {
      final profile = await _profileService.getDriverProfile(widget.userId);
      if (mounted) {
        setState(() {
          _totalWorkingTime = profile.totalWorkingTime;
          _currentWeekWorkingTime = profile.currentWeekWorkingTime;
        });
      }
    } catch (e) {
      print("Error loading driver profile: $e");
    }
  }
  
  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadNotificationCount(widget.userId);
      print("Loaded unread notifications: $count"); // Debug print
      
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
      
      // Refresh more frequently if needed
      if (mounted) {
        Future.delayed(const Duration(seconds: 30), () {
          _loadUnreadNotificationCount();
        });
      }
    } catch (e) {
      print("Error loading notification count: $e"); // Debug print
      // Keep trying to refresh despite errors
      if (mounted) {
        Future.delayed(const Duration(seconds: 30), () {
          _loadUnreadNotificationCount();
        });
      }
    }
  }
  
  // Add a method to force refresh notification count
  void _forceRefreshNotifications() {
    _loadUnreadNotificationCount();
  }
  
  // Function to truncate user ID for display
  String _formatUserId(String userId) {
    if (userId.length > 15) {
      return '${userId.substring(0, 12)}...';
    }
    return userId;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MTCS Ứng Dụng Tài Xế'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, size: 28),
                  onPressed: () {
                    // Force refresh before navigating
                    _forceRefreshNotifications();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsScreen(userId: widget.userId),
                      ),
                    ).then((_) {
                      // After returning from notifications screen
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
          await _loadUnreadNotificationCount();
          await _loadDriverProfile();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver welcome section
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
                                const Text(
                                  'Xin Chào, Tài Xế',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${_formatUserId(widget.userId)}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Working time summary
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
                                    '$_currentWeekWorkingTime giờ',
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
                                      'Tổng thời gian làm việc',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_totalWorkingTime giờ',
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
                                status: "not_started"
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
                                statusList: [
                                  "going_to_port",
                                  "picking_up_goods",
                                  "is_delivering",
                                  "at_delivery_point",
                                  "delaying",
                                ]
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
                                statusList: [
                                  "completed",
                                  "canceled",
                                ]
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
