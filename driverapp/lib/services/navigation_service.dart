import 'package:flutter/material.dart';
import 'package:driverapp/profileScreen.dart';
import 'package:driverapp/order_list_screen.dart';

class NavigationService {
  void navigateToOrderList(BuildContext context, String status, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderListScreen(userId: userId, status: status),
      ),
    );
  }
  
  void navigateToProfile(BuildContext context, String driverId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(driverId: driverId),
      ),
    );
  }
}
