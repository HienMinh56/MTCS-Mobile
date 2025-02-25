import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  TextEditingController otpController = TextEditingController();
  bool isResendEnabled = true; // Cho phép gửi lại OTP

  void resendOtp() {
    setState(() {
      isResendEnabled = false;
    });
    // Gửi lại OTP ở đây (gọi API hoặc Firebase)
    Future.delayed(Duration(seconds: 30), () {
      setState(() {
        isResendEnabled = true;
      });
    });
  }

  void login() {
    // Xử lý logic đăng nhập với OTP
    print("OTP nhập vào: ${otpController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "MTCS",
              style: TextStyle(fontSize: 32, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 40),

            // Ô nhập OTP
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Nhập OTP",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isResendEnabled ? resendOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Re Send"),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Thông báo OTP có hiệu lực
            Text(
              "Mã OTP có hiệu lực trong vòng 5 phút",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),

            // Nút Đăng Nhập
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  "Đăng Nhập",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
