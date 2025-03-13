import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driverapp/firebase_options.dart';
import 'package:driverapp/loginScreen.dart';

// 🔹 Plugin hiển thị thông báo cục bộ
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔹 Cấu hình Local Notifications
void setupLocalNotifications() {
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);

  flutterLocalNotificationsPlugin.initialize(initSettings);
}

// 🔹 Hiển thị thông báo trên thanh trạng thái
void showNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Thông báo',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

// 🔹 Xử lý thông báo khi app chạy nền
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  showNotification(message);
}

// 🔹 Lắng nghe thông báo từ Firebase khi app đang chạy
void setupFirebaseMessaging() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    showNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📩 Người dùng nhấn vào thông báo: ${message.notification?.title}");
  });
}

// 🔹 Lưu userId vào SharedPreferences sau khi đăng nhập
Future<void> saveUserId(String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', userId);
}

// 🔹 Lấy userId từ SharedPreferences
Future<String?> getUserId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}

// 🔹 Lưu FCM Token vào Firestore
Future<void> saveTokenToFirestore(String userId) async {
  String? token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    print("📲 Lưu FCM Token vào Firestore: $token");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo Local Notifications
  setupLocalNotifications();

  // Đăng ký xử lý thông báo khi app chạy nền
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Lắng nghe thông báo khi app đang chạy
  setupFirebaseMessaging();

  // Kiểm tra nếu user đã đăng nhập thì lưu token vào Firestore
  String? userId = await getUserId();
  if (userId != null) {
    await saveTokenToFirestore(userId);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
