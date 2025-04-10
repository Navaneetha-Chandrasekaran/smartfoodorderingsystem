// ignore_for_file: prefer_const_constructors, sort_child_properties_last, deprecated_member_use

import 'dart:async';
import 'package:bitetimenew/ui/user/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../../../models/buttons.dart';
import '../../../models/constants.dart';
import '../../../models/error_dialog.dart';
import '../../../models/titles.dart';
import '../../../services/auth/otp_auth.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final OtpService _otpService = OtpService();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool isButtonDisabled = false;
  int countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// ✅ Resend Timer
  void startTimer() {
    setState(() {
      isButtonDisabled = true;
      countdown = 30;
    });

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

  /// ✅ OTP Verification
  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 4) {
      ErrorDialog.show(
        context,
        title: "Invalid OTP",
        message: "⚠️ Please enter a valid 4-digit OTP.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _otpService.verifyOtp(widget.email, otp);

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ OTP Verified Successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserLoginScreen()),
      );
    } else {
      ErrorDialog.show(
        context,
        title: "OTP Verification Failed",
        message: response['message'] ?? "Something went wrong. Try again.",
        onRetry: _handleVerifyOtp,
      );
    }

    setState(() {
      _isLoading = false;
    });
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

              /// ✅ OTP Illustration
              Image.asset("assets/otp.png", width: screenWidth * 0.7),

              SizedBox(height: screenHeight * 0.05),

              Titles(title: "OTP Verification"),
              SizedBox(height: screenHeight * 0.02),
              Description(description: "Enter the OTP sent to ${widget.email}"),
              SizedBox(height: screenHeight * 0.04),

              /// ✅ OTP Input
              Center(
                child: Pinput(
                  length: 4,
                  controller: _otpController,
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

              /// ✅ Resend OTP
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

              /// ✅ Verify Button
              _isLoading
                  ? CircularProgressIndicator()
                  : CustomButton(
                      label: "Verify OTP",
                      onPressed: _handleVerifyOtp,
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      gradientColors: [Color.fromARGB(255, 70, 255, 101), Color(0xFF2FA848)],
                      labelColor: Colors.white,
                      icon: Icons.check,
                      hasBorder: true,
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
