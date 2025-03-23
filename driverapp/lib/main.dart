import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driverapp/screens/firebase_options.dart';
import 'package:driverapp/screens/loginScreen.dart';
import 'package:driverapp/screens/homeScreen.dart';
import 'package:driverapp/services/auth_service.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomeScreen(userId: ''), // We'll replace this with dynamic userId when navigating
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "MTCS",
              style: TextStyle(
                fontSize: 36,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}