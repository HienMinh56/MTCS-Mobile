import 'package:driverapp/components/function_card.dart';
import 'package:driverapp/components/status_counter.dart';
import 'package:driverapp/notificationScreen.dart';
import 'package:driverapp/services/navigation_service.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/services/notification_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OrderService _orderService = OrderService();
  final NavigationService _navigationService = NavigationService();
  final NotificationService _notificationService = NotificationService();
  
  Map<String, int> _orderCounts = {
    'assigned': 0,
    'processing': 0,
    'completed': 0
  };
  int _unreadNotifications = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadOrderCounts();
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadUnreadNotificationCount();
    });
  }
  
  Future<void> _loadOrderCounts() async {
    try {
      final counts = await _orderService.getOrderCounts(widget.userId);
      setState(() {
        _orderCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
        title: const Text('MTCS Driver App'),
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
          await _loadOrderCounts();
          await _loadUnreadNotificationCount();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver welcome section - Fix the overflow here
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFFBBDEFB), // Colors.blue.shade100
                          child: Icon(Icons.person, size: 35, color: Colors.blue),
                        ),
                        const SizedBox(width: 16),
                        Expanded( // Wrap in Expanded to prevent overflow
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Welcome, Driver',
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
                    
                    const SizedBox(height: 30),
                    
                    // Order status summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorConstants.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StatusCounter(
                            label: "Assigned",
                            count: _orderCounts['assigned'].toString(),
                            color: ColorConstants.assignedColor,
                          ),
                          StatusCounter(
                            label: "Processing",
                            count: _orderCounts['processing'].toString(),
                            color: ColorConstants.processingColor,
                          ),
                          StatusCounter(
                            label: "Completed",
                            count: _orderCounts['completed'].toString(),
                            color: ColorConstants.completedColor,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Main function grid
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          FunctionCard(
                            title: "Assigned Orders",
                            icon: Icons.assignment,
                            color: ColorConstants.assignedColor,
                            onTap: () => _navigationService.navigateToOrderList(
                              context, "assigned", widget.userId
                            ),
                          ),
                          FunctionCard(
                            title: "Processing Orders",
                            icon: Icons.local_shipping,
                            color: ColorConstants.processingColor,
                            onTap: () => _navigationService.navigateToOrderList(
                              context, "processing", widget.userId
                            ),
                          ),
                          FunctionCard(
                            title: "Finished Orders",
                            icon: Icons.done_all,
                            color: ColorConstants.completedColor,
                            onTap: () => _navigationService.navigateToOrderList(
                              context, "completed", widget.userId
                            ),
                          ),
                          FunctionCard(
                            title: "My Profile",
                            icon: Icons.account_circle,
                            color: ColorConstants.profileColor,
                            onTap: () => _navigationService.navigateToProfile(
                              context, widget.userId
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
