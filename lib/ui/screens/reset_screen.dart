// ignore_for_file: prefer_const_constructors


import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/buttons.dart';
import '../../models/constants.dart';
import '../../models/titles.dart';
import 'login_screen.dart';

class ResetScreen extends StatefulWidget {
  const ResetScreen({super.key});

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset("assets/icons/back.svg"),
        ),
      ),
      body: ListView(
        children: [
          SizedBox(height: screenHeight * 0.1),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Titles(title: "Reset Password!"),
                SizedBox(height: screenHeight * 0.02),
                Description(description: "Enter a password that no one knows"),
                SizedBox(height: screenHeight * 0.05),
                
                Description(description: "Password"),
                SizedBox(height: screenHeight * 0.03),
                CustomTextField(
                  controller: _passwordController,
                  hintText: "Enter your password",
                  prefixIcon: Icons.lock,
                  isPassword: true,
                  isPasswordVisible: _isPasswordVisible,
                  togglePasswordVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),

                SizedBox(height: screenHeight * 0.05),
                Description(description: "Confirm Password"),
                SizedBox(height: screenHeight * 0.03),
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: "Confirm your password",
                  prefixIcon: Icons.lock,
                  isPassword: true,
                  isPasswordVisible: _isConfirmPasswordVisible,
                  togglePasswordVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),

                SizedBox(height: screenHeight * 0.1),
                Center(child: button(
                  label: "Confirm", 
                  destination: LoginScreen(), 
                  bg: secondaryColor,
                  labelColor: Colors.black
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
