// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/buttons.dart';
import '../../../models/constants.dart';
import '../../../models/titles.dart';
import '../sheets/navbar.dart';
import 'signup_screen.dart';

class CanteenLoginScreen extends StatefulWidget {
  const CanteenLoginScreen({super.key});

  @override
  State<CanteenLoginScreen> createState() => CanteenrLoginScreenState();
}

class CanteenrLoginScreenState extends State<CanteenLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

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
                  "assets/canteen-login.png",
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
                      hintText: "Canteen mail / Number",
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
                    /// ✅ **Login Button**
                    CustomButton(
                      label: "Login",
                      destination: CanteenNavBar(),
                      labelColor: Colors.white,
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      icon: Icons.arrow_forward, // ✅ Icon on the right
                    ),



                    SizedBox(height: screenHeight * 0.03),

                    /// ✅ **Sign Up Prompt**
                    Center(
                      child: rowText(
                        text: "Don't have an account?",
                        buttonText: "Sign Up",
                        destination: CanteenSignUpScreen(),
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
