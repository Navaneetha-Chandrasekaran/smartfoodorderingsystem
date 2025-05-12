import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/buttons.dart';
import '../../../models/constants.dart';
import '../../../models/error_dialog.dart';
import '../../../models/titles.dart';
import '../../../services/auth/login_auth.dart';
import '../sheets/navbar.dart';
import 'signup_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  /// ✅ **Handle Login**
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ErrorDialog.show(
        context,
        title: "Missing Fields",
        message: "⚠️ Please enter email and password.",
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print("⏳ Sending login request...");
      final response = await _authService.loginUser(email, password, 'student');
      print("✅ API Response: $response");

      if (response['success']) {
        print("🎉 Login Successful");

        // ✅ Delay navigation to avoid UI issues
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CustomNavBar()),
            );
          }
        });

        _showSuccessDialog("Login Successful", "✅ Welcome back!");
      } else {
        print("❌ Login Failed: ${response['message']}");
        ErrorDialog.show(
          context,
          title: "Login Failed",
          message: response['message'] ?? "Something went wrong",
          onRetry: _handleLogin,
        );
      }
    } catch (e) {
      print("🚨 Error during login: $e");
      ErrorDialog.show(
        context,
        title: "Error",
        message: "🚨 Login failed: $e",
        onRetry: _handleLogin,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ **Show Success Dialog**
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF40CF58), Color(0xFF4AFD69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.07),

              /// ✅ **Title**
              Text(
                "Login To Your Account",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              /// ✅ **Login Illustration**
              SizedBox(
                width: screenWidth * 0.6,
                child: Image.asset(
                  "assets/user-login.png",
                  width: screenWidth * 0.7,
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              /// ✅ **Login Form**
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ✅ **Email Field**
                    CustomTextField(
                      controller: _emailController,
                      hintText: "Email",
                      prefixIcon: Icons.email_outlined,
                    ),

                    /// ✅ **Password Field**
                    CustomTextField(
                      controller: _passwordController,
                      hintText: "Password",
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      togglePasswordVisibility: togglePasswordVisibility,
                    ),

                    SizedBox(height: screenHeight * 0.015),

                    /// ✅ **Login Button**
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            label: "Login",
                            onPressed: _handleLogin,
                            labelColor: Colors.white,
                            width: double.infinity,
                            height: screenHeight * 0.07,
                            icon: Icons.arrow_forward,
                          ),

                    SizedBox(height: screenHeight * 0.03),

                    /// ✅ **Sign Up Prompt**
                    Center(
                      child: rowText(
                        text: "Don't have an account?",
                        buttonText: "Sign Up",
                        destination: const SignUpScreen(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
