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
  // Trước tiên yêu cầu quyền thông báo
  await Permission.notification.request();
  
  // Yêu cầu quyền vị trí cơ bản trước
  var locationStatus = await Permission.locationWhenInUse.request();
  
  // Chỉ yêu cầu quyền vị trí nền sau khi đã cấp quyền vị trí cơ bản
  if (locationStatus.isGranted) {
    await Permission.locationAlways.request();
  }
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
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.blue),
              SizedBox(width: 8),
              Text('Cấp quyền bắt buộc', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Để ứng dụng hoạt động đúng, bạn cần cấp các quyền sau:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                
                // Quyền vị trí
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Quyền vị trí "Luôn cho phép"', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Cần thiết để theo dõi vị trí khi giao hàng, ngay cả khi ứng dụng đang chạy nền'),
                      SizedBox(height: 8),
                      Text('Cách cấp quyền:', style: TextStyle(fontStyle: FontStyle.italic)),
                      SizedBox(height: 4),
                      Text('• Tại màn hình cài đặt, chọn "Vị trí"'),
                      Text('• Chọn "Luôn cho phép" hoặc "Allow all the time"'),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                
                // Quyền thông báo
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Quyền thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Cần thiết để nhận thông báo đơn hàng mới và cập nhật quan trọng'),
                      SizedBox(height: 8),
                      Text('Cách cấp quyền:', style: TextStyle(fontStyle: FontStyle.italic)),
                      SizedBox(height: 4),
                      Text('• Tại màn hình cài đặt, chọn "Thông báo"'),
                      Text('• Bật "Cho phép thông báo"'),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Lưu ý quan trọng
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sau khi bạn cấp quyền, hãy quay lại ứng dụng để tiếp tục sử dụng.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Mở cài đặt ứng dụng
                await openAppSettings();
                
                // Chờ một chút và kiểm tra lại sau khi quay lại từ cài đặt
                await Future.delayed(const Duration(seconds: 2));
                _checkLoginStatus();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Đi đến Cài đặt'),
                ],
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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