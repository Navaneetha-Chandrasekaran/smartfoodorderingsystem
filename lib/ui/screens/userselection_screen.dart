// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/constants.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.2),
            Center(
              child: Text(
                "Select Your Role",
                style: GoogleFonts.roboto(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Image.asset("assets/user.png"),
            SizedBox(height: screenHeight * 0.04),
            userButton(userType: 'Student/Faculty'),
            SizedBox(height: screenHeight * 0.04),
            userButton(userType: 'Canteen Staff'),
            SizedBox(height: screenHeight * 0.04),
            // userButton(userType: 'Admin'),
          ],
        ),
      ),
    );
  }
}
