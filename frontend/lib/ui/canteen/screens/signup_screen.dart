import 'package:bitetimenew/services/auth/signup_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/buttons.dart';
import '../../../models/constants.dart';
import '../../../models/error_dialog.dart';
import '../../../models/titles.dart';
import '../../user/screens/otp_screen.dart';
import 'login_screen.dart';

class CanteenSignUpScreen extends StatefulWidget {
  const CanteenSignUpScreen({super.key});

  @override
  State<CanteenSignUpScreen> createState() => _CanteenSignUpScreenState();
}

class _CanteenSignUpScreenState extends State<CanteenSignUpScreen> {
  final CanteenReg _canteenReg = CanteenReg();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  /// ✅ Handle Signup
  Future<void> _handleSignup() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ErrorDialog.show(
        context,
        title: "Missing Fields",
        message: "Please fill all fields.",
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final response = await _canteenReg.registerCanteenStaff(name, email, phone, password, confirmPassword);

    if (response['success']) {
      _showSuccessDialog("Signup Successful", "✅ OTP has been sent to your email");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(email: response['email']),
        ),
      );
    } else {
      ErrorDialog.show(
        context,
        title: "Signup Failed",
        message: response['message'] ?? "An error occurred.",
        onRetry: _handleSignup,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// ✅ Success Dialog
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
              SizedBox(height: screenHeight * 0.08),

              /// ✅ Title
              Text(
                "Create Your Account",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              /// ✅ Logo
              Image.asset("assets/logo.png", width: screenWidth * 0.7),

              SizedBox(height: screenHeight * 0.03),

              /// ✅ Sign Up Form
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
                    CustomTextField(controller: _nameController, hintText: "Full Name", prefixIcon: Icons.person),
                    CustomTextField(controller: _emailController, hintText: "Canteen Mail ID", prefixIcon: Icons.email),
                    CustomTextField(controller: _phoneController, hintText: "Phone Number", prefixIcon: Icons.call),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: "Password",
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      togglePasswordVisibility: togglePasswordVisibility,
                    ),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: "Confirm Password",
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      isPasswordVisible: _isConfirmPasswordVisible,
                      togglePasswordVisibility: toggleConfirmPasswordVisibility,
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    /// ✅ Register Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            label: "Register",
                            onPressed: _handleSignup,
                            labelColor: Colors.white,
                            width: double.infinity,
                            height: screenHeight * 0.07,
                            icon: Icons.arrow_forward,
                          ),

                    SizedBox(height: screenHeight * 0.02),

                    /// ✅ Already Have an Account?
                    Center(
                      child: rowText(
                        text: "Already have an account?",
                        buttonText: "Sign In",
                        destination: const CanteenLoginScreen(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.07),
            ],
          ),
        ),
      ),
    );
  }
}
