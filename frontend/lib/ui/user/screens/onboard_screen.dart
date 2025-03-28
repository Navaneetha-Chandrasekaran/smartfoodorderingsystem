// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/constants.dart';
import '../sheets/onboard_data.dart';
import '../../../userselection_screen.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({Key? key}) : super(key: key);

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  final controller = OnboardDetails();
  final pageController = PageController();
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 🌿 Green Gradient Background
          Container(
            decoration: const BoxDecoration(gradient: primaryColor),
          ),

          PageView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: controller.items.length,
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Column(
                children: [
                  SizedBox(height: screenHeight * 0.12),

                  // 🍃 Green-themed container for image
                  Container(
                    height: screenHeight * 0.45,
                    width: screenWidth * 0.85,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Glass Effect
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: Center(
                      child: Image.asset(
                        controller.items[index].image,
                        height: screenHeight * 0.8,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // 🌿 Title with Improved Styling
                  Text(
                    controller.items[index].title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // 📜 Description inside a rounded container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Semi-transparent for glass effect
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      controller.items[index].description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 🌿 Bottom Navigation Controls (Styled)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: currentPageIndex != controller.items.length - 1
                  ? Row(
                      key: const ValueKey('row'),
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => pageController.jumpToPage(controller.items.length - 1),
                          child: Text(
                            "Skip",
                            style: GoogleFonts.roboto(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // 🌿 Green-Themed Next Button in Rounded Container
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: IconButton(
                            onPressed: () => pageController.nextPage(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                            ),
                            icon: SvgPicture.asset(
                              "assets/icons/right.svg",
                              color: Colors.black,
                              width: screenWidth * 0.05,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      key: const ValueKey('center'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const UserSelectionScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          icon: SvgPicture.asset(
                            "assets/icons/check.svg",
                            color: Colors.black,
                            width: screenWidth * 0.05,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
