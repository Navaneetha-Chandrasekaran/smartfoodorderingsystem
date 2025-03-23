import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/constants.dart';
import '../../../models/titles.dart';
import '../../../sheets/navigator.dart';
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
      body: ListView(
        children: [
          Column(
            children: [
              SizedBox(height: screenHeight * 0.1),
              Center(
                child: Text(
                  "Create Your Account",
                  style: GoogleFonts.roboto(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Image.asset("assets/logo.png", width: screenWidth * 0.7),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 30),
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
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              GestureDetector(
                onTap: () {
                  Navigation.navigateTo(context, OtpScreen());
                },
                child: Container(
                  width: screenWidth * 0.75,
                  height: screenHeight * 0.06,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: primaryColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: screenWidth * 0.22),
                      Text(
                        "Register",
                        style: GoogleFonts.roboto(
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      SizedBox(width: screenWidth * 0.12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: SvgPicture.asset("assets/icons/right.svg"),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              rowText(
                  text: "Already have an account?",
                  buttonText: "Sign In",
                  destination: LoginScreen()),
            ],
          ),
        ],
      ),
    );
  }
}
