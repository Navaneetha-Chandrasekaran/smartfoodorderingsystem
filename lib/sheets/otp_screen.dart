// ignore_for_file: prefer_const_constructors, sort_child_properties_last

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../models/buttons.dart';
import '../models/constants.dart';
import '../models/titles.dart';
import '../ui/user/screens/reset_screen.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: SvgPicture.asset("assets/icons/back.svg"),
          ),
        ),
      ),
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
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.12),

              /// ✅ **OTP Illustration**
              Image.asset("assets/otp.png", width: screenWidth * 0.7),

              SizedBox(height: screenHeight * 0.05),

              /// ✅ **Title & Description**
              Titles(title: "OTP Verification"),
              SizedBox(height: screenHeight * 0.02),
              Description(description: "Enter the OTP sent to 95*******5"),
              SizedBox(height: screenHeight * 0.04),

              /// ✅ **OTP Input Field**
              Center(
                child: Pinput(
                  length: 4,
                  defaultPinTheme: PinTheme(
                    width: screenWidth * 0.14,
                    height: screenHeight * 0.07,
                    textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: secondaryColor),
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              /// ✅ **Resend OTP Section**
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the OTP?",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: isButtonDisabled ? null : startTimer,
                    child: Text(
                      isButtonDisabled ? "Resend in $countdown sec" : "Resend OTP",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellowAccent,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.05),

              /// ✅ **Verify OTP Button**
              /// ✅ **Verify OTP Button**
              /// ✅ **Verify OTP Button**
              CustomButton(
                label: "Verify OTP",
                destination: ResetScreen(),
                width: double.infinity,
                height: screenHeight * 0.07,
                gradientColors: [Color.fromARGB(255, 70, 255, 101), Color(0xFF2FA848)], // ✅ Dark Green Contrast
                labelColor: Colors.white,
                icon: Icons.check, // ✅ Check Icon (You can change this)
                hasBorder: true, // ✅ Add White Border
                borderColor: Colors.white,
              ),



              SizedBox(height: screenHeight * 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
