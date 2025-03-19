import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/material.dart';

class AuthService {
  static const String _baseUrl = "https://mtcs-server.azurewebsites.net/api";

  /// 🟢 **Đăng nhập & giải mã JWT**
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Authen/driver-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['data']['token'];

        // 🔹 Giải mã JWT để lấy userId
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        String userId = decodedToken['sub']; // "sub" là userId trong JWT

        await _saveUserData(userId, token);
        await _saveTokenToFirestore(userId);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print("❌ Lỗi đăng nhập: $e");
      return null;
    }
  }

  /// 🟢 **Đăng nhập đầy đủ với xử lý kết quả**
  static Future<Map<String, dynamic>> loginAndNavigate(String email, String password) async {
    try {
      final response = await login(email.trim(), password.trim());
      
      if (response != null) {
        final loggedIn = await isLoggedIn();
        final userId = await getUserId();
        
        if (loggedIn && userId != null) {
          return {
            'success': true,
            'userId': userId,
            'message': 'Đăng nhập thành công'
          };
        } else {
          return {
            'success': false,
            'message': 'Xác thực người dùng thất bại'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Đăng nhập thất bại. Vui lòng thử lại!'
        };
      }
    } catch (e) {
      print("❌ Lỗi trong quá trình đăng nhập: $e");
      return {
        'success': false,
        'message': 'Có lỗi xảy ra. Vui lòng thử lại sau!'
      };
    }
  }

  /// 🔹 **Lưu userId & token vào SharedPreferences**
  static Future<void> _saveUserData(String userId, String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('authToken', token);
    // TODO: Consider using flutter_secure_storage for more secure token storage
  }

  /// 🔹 **Lưu FCM Token vào Firestore**
  static Future<void> _saveTokenToFirestore(String userId) async {
    String? newToken = await FirebaseMessaging.instance.getToken();
    if (newToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': newToken,
      }, SetOptions(merge: true));
    }
  }

  /// 🔹 **Lấy userId từ SharedPreferences**
  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  /// 🔹 **Kiểm tra người dùng đã đăng nhập hay chưa**
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    
    if (token == null) return false;
    
    // Check if token is expired
    try {
      bool isExpired = JwtDecoder.isExpired(token);
      return !isExpired;
    } catch (e) {
      return false;
    }
  }
  
  /// 🔹 **Lấy token xác thực từ SharedPreferences**
  static Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// 🔴 **Đăng xuất**
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('authToken');
    await FirebaseMessaging.instance.deleteToken();
    print("🔴 Đã đăng xuất!");
  }

  /// 🔴 **Xác nhận đăng xuất**
  static void logoutConfirm(BuildContext context) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Call the static logout method to clear credentials
                await AuthService.logout();
                // Navigate to login screen and clear navigation stack
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}
