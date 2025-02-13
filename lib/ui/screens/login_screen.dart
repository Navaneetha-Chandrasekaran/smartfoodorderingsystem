// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import


import 'package:bitetimenew/ui/screens/otp_screen.dart';
import 'package:bitetimenew/ui/screens/reset_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/constants.dart';
import '../../models/titles.dart';
import '../sheets/navigator.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for the text fields (optional but recommended)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        body: ListView(children: [
      Column(
        children: [
          SizedBox(height: screenHeight * 0.1),
          Center(
            child: Text(
              "Login To Your Account",
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
                Text(
                  "Name / College mail ID",
                  style: GoogleFonts.roboto(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        style: BorderStyle.solid,
                        color: Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    hintText: "Enter your name or college mail ID",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "Password",
                  style: GoogleFonts.roboto(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        style: BorderStyle.solid,
                        color: Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    hintText: "Enter your password",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: screenWidth * 0.5),
                  child: TextButton(
                    onPressed: () {
                      Navigation.navigateTo(context, OtpScreen());
                    },
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.roboto(
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 78, 173, 252),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                GestureDetector(
                  onTap: () {},
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
                          child: SvgPicture.asset(
                            "assets/icons/right.svg",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                rowText(
                    text: "Don't have an account?",
                    buttonText: "Sign Up",
                    destination: SignUpScreen())
              ],
            ),
          ),
        ],
      ),
    ]));
  }
}
