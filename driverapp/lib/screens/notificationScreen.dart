import 'package:driverapp/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:driverapp/components/notification_item.dart';
import 'package:driverapp/components/empty_notification.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // We no longer mark all as read when screen opens
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thông báo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Just refresh the list, don't mark as read
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: StreamBuilder<List<Map<String, dynamic>>>(
          // This stream gets ALL notifications for the user, not just unread ones
          stream: _notificationService.getNotifications(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && 
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyNotification();
            }

            var notifications = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return NotificationItem(
                  notification: notifications[index],
                  onReadStatusChanged: () {
                    // This will be called when a notification is marked as read
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
