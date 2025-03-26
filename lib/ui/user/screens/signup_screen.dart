import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/buttons.dart';
import '../../../models/constants.dart';
import '../../../models/titles.dart';
import 'login_screen.dart';
import '../../../sheets/otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final SignUpController _controller = SignUpController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _controller.disposeControllers();
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

              /// ✅ **Title**
              Text(
                "Create Your Account",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              /// ✅ **App Logo**
              Image.asset("assets/logo.png", width: screenWidth * 0.7),

              SizedBox(height: screenHeight * 0.03),

              /// ✅ **Sign Up Form with Button & Navigation**
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
                    CustomTextField(
                      controller: _controller.nameController,
                      hintText: "Full Name",
                      prefixIcon: Icons.person,
                    ),
                    CustomTextField(
                      controller: _controller.emailController,
                      hintText: "College Mail ID",
                      prefixIcon: Icons.email,
                    ),
                    CustomTextField(
                      controller: _controller.phoneController,
                      hintText: "Phone Number",
                      prefixIcon: Icons.call,
                    ),
                    CustomTextField(
                      controller: _controller.passwordController,
                      hintText: "Password",
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      togglePasswordVisibility: togglePasswordVisibility,
                    ),
                    CustomTextField(
                      controller: _controller.confirmPasswordController,
                      hintText: "Confirm Password",
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      isPasswordVisible: _isConfirmPasswordVisible,
                      togglePasswordVisibility: toggleConfirmPasswordVisibility,
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    /// ✅ **Register Button**
                    CustomButton(
                      label: "Register",
                      destination: OtpScreen(),
                      labelColor: Colors.white,
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      icon: Icons.arrow_forward, // ✅ Icon on the right
                    ),



                    SizedBox(height: screenHeight * 0.02),

                    /// ✅ **Already Have an Account?**
                    Center(
                      child: rowText(
                        text: "Already have an account?",
                        buttonText: "Sign In",
                        destination: UserLoginScreen(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.07)
            ],
          ),
        ),
      ),
    );
  }
}
