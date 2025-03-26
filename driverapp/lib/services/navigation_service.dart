import 'package:driverapp/screens/delivery_reports_history_screen.dart';
import 'package:driverapp/screens/report_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:driverapp/screens/profileScreen.dart';
import 'package:driverapp/screens/incident_reports_history_screen.dart';
import 'package:driverapp/screens/fuel_reports_history_screen.dart';
import 'package:driverapp/screens/trip_list_screen.dart';

class NavigationService {
  
  
  void navigateToProfile(BuildContext context, String driverId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(driverId: driverId),
      ),
    );
  }
  
  void navigateToDeliveryReports(BuildContext context, String driverId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryReportsScreen(driverId: driverId),
      ),
    );
  }

  // Method to navigate to Reports Menu
  void navigateToReportMenu(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportMenuScreen(userId: userId),
      ),
    );
  }

  // Method to navigate to Fuel Reports
  void navigateToFuelReports(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FuelReportsScreen(userId: userId),
      ),
    );
  }

  // Method to navigate to Incident Reports
  void navigateToIncidentReports(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentReportsScreen(userId: userId),
      ),
    );
  }

  // Method to navigate to Trip List with filter by status
  void navigateToTripList(BuildContext context, String driverId, {
    required String status, 
    List<String>? statusList
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripListScreen(
          driverId: driverId, 
          status: status,
          statusList: statusList,
        ),
      ),
    );
  }
}
