// ignore_for_file: prefer_const_constructors, sort_child_properties_last

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../../models/buttons.dart';
import '../../models/constants.dart';
import '../../models/titles.dart';
import 'reset_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool isButtonDisabled = false;
  int countdown = 0;
  Timer? _timer;

  // Start timer
  void startTimer() {
    setState(() {
      isButtonDisabled = true;
      countdown = 30;
    });

    // Countdown decreasing
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (countdown > 0) {
          countdown--;
        } else {
          isButtonDisabled = false;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
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
        padding: EdgeInsets.symmetric(horizontal: 20),
        children: [
          SizedBox(height: screenHeight * 0.05),
          Center(
            child: Image.asset("assets/otp.png", width: screenWidth * 1),
          ),
          SizedBox(height: screenHeight * 0.07),
          Titles(title: "OTP Verification"),
          SizedBox(height: screenHeight * 0.02),
          Description(description: "Enter the OTP sent to 95*******5"),
          SizedBox(height: screenHeight * 0.04),

          // OTP Input
          Center(
            child: Pinput(
              length: 4,
              defaultPinTheme: PinTheme(
                width: screenWidth * 0.15,
                height: screenHeight * 0.07,
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.05),

          // Resend OTP Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the OTP?",
                style: GoogleFonts.roboto(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: isButtonDisabled ? null : startTimer,
                child: Text(
                  isButtonDisabled ? "Resend in $countdown seconds" : "Resend OTP",
                  style: GoogleFonts.roboto(
                    color: Color.fromARGB(255, 78, 173, 252),
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.05),

          // Verify OTP Button
          button(label: "Verify OTP", destination: ResetScreen()),
        ],
      ),
    );
  }
}
