import 'package:driverapp/components/form_fields.dart';
import 'package:driverapp/screens/homeScreen.dart';
import 'package:driverapp/services/auth_service.dart';
import 'package:driverapp/utils/validators.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      final result = await AuthService.loginAndNavigate(email, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userId: result['userId']),
          ),
          (route) => false,
        );
      } else {
        _showErrorMessage(result['message']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorMessage('Có lỗi xảy ra. Vui lòng thử lại sau!');
    }
  }
  
  void _showErrorMessage(String message) {
    // Show error message in a SnackBar with clearer formatting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Image(
                      image: AssetImage("img/logo.png"),
                      width: 120,
                    ),
                    const SizedBox(height: 32),
                    FormFields.buildEmailField(
                      controller: _emailController,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    FormFields.buildPasswordField(
                      controller: _passwordController,
                      isPasswordVisible: _isPasswordVisible,
                      togglePasswordVisibility: _togglePasswordVisibility,
                      validator: Validators.validatePassword,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 24),
                    FormFields.buildSubmitButton(
                      isLoading: _isLoading,
                      onPressed: _login,
                      buttonText: "Đăng Nhập",
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Nếu quên mật khẩu, vui lòng liên hệ quản lý để được giải quyết",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
