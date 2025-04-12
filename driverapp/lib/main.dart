import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driverapp/screens/firebase_options.dart';
import 'package:driverapp/screens/loginScreen.dart';
import 'package:driverapp/screens/homeScreen.dart';
import 'package:driverapp/services/auth_service.dart';
import 'package:driverapp/services/status_manager.dart';
import 'package:permission_handler/permission_handler.dart';

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

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
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
  await FirebaseMessaging.instance.getToken();
}

// 🔹 Yêu cầu tất cả quyền cần thiết khi khởi động ứng dụng
Future<void> requestPermissions() async {
  // Danh sách các quyền cần thiết
await [
    Permission.location,
    Permission.locationAlways,
    Permission.notification,
  ].request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the foreground task
  
  // Yêu cầu tất cả quyền cần thiết khi khởi động
  await requestPermissions();
  
  // Initialize status manager to fetch delivery statuses
  await StatusManager.initialize();
  
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

  runApp(
      const MyApp(),
  );
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
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(userId: ''), // We'll replace this with dynamic userId when navigating
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Add a small delay for better user experience
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    // Check if permissions were granted
    bool hasLocationAlways = await Permission.locationAlways.isGranted;
    bool hasNotification = await Permission.notification.isGranted;
    
    // If permissions not granted, show explanation dialog
    if (!hasLocationAlways || !hasNotification) {
      if (!mounted) return;
      await _showPermissionExplanationDialog();
      return;
    }
    
    // If we have all permissions, proceed with login check
    final bool isLoggedIn = await AuthService.isLoggedIn();
    final String? userId = await AuthService.getUserId();
    
    if (isLoggedIn && userId != null) {
      // User is logged in, navigate to HomeScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => HomeScreen(userId: userId))
      );
    } else {
      // No valid session, navigate to LoginScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    }
  }
  
  Future<void> _showPermissionExplanationDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cấp quyền bắt buộc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Ứng dụng cần các quyền sau để hoạt động chính xác:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('• Quyền vị trí "Luôn cho phép": để theo dõi vị trí của tài xế khi giao hàng, ngay cả khi ứng dụng đang chạy nền'),
              SizedBox(height: 8),
              Text('• Quyền thông báo: để nhận thông báo về đơn hàng mới và cập nhật quan trọng'),
              SizedBox(height: 15),
              Text('Vui lòng cấp tất cả các quyền này trong phần Cài đặt ứng dụng để tiếp tục sử dụng.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // First request permissions within app
                await Permission.locationAlways.request();
                await Permission.notification.request();
                
                // Then open settings for full control
                await openAppSettings();
                
                // Wait a moment and check again after returning from settings
                await Future.delayed(const Duration(seconds: 2));
                _checkLoginStatus();
              },
              child: const Text('Đi đến Cài đặt'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "MTCS",
              style: TextStyle(
                fontSize: 36,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}