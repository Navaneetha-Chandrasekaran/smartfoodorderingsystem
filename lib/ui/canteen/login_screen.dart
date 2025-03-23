import 'package:bitetimenew/ui/canteen/signup_screen.dart';
import 'package:bitetimenew/ui/user/sheets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/constants.dart';
import '../../../models/titles.dart';
import '../../sheets/navigator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
        body: ListView(
      children: [
        Column(
          children: [
            SizedBox(height: screenHeight * 0.1),
            Center(
              child: Text(
                "Canteen Staff Login",
                style: GoogleFonts.roboto(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                ),
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
                    controller: _emailController,
                    hintText: "Enter Staff ID or Email",  // ✅ Updated for staff login
                    prefixIcon: Icons.email,
                  ),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: "Enter Staff Password",  // ✅ Updated for staff login
                    prefixIcon: Icons.lock,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    togglePasswordVisibility: togglePasswordVisibility,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  GestureDetector(
                    onTap: () {
                      Navigation.navigateTo(context, CustomNavBar());
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
                          SizedBox(width: screenWidth * 0.27),
                          Text(
                            "Login",
                            style: GoogleFonts.roboto(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.17),
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
                      text: "Don't have an account?",
                      buttonText: "Sign Up",
                      destination: SignUpScreen()),
                ],
              ),
            ),
          ],
        ),
      ],
    ));
  }
}
