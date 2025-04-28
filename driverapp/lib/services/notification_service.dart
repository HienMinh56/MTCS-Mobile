import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications with read status
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('Notifications')
        .where('UserId', isEqualTo: userId)
        .orderBy('Timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              var data = doc.data();
              return {
                "id": doc.id,
                "title": data["Title"],
                "body": data["Body"],
                "timestamp": data["Timestamp"],
                "isRead": data["isRead"] ?? false, // Default to false if field doesn't exist
              };
            }).toList());
  }

  // Get count of unread notifications
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Notifications')
          .where('UserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false) // Only get unread notifications
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
  
  // Mark all notifications as read for a user
  Future<void> markNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Notifications')
          .where('UserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      // Use batch to update multiple documents efficiently
      WriteBatch batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }
  
  // Mark a specific notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('Notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
