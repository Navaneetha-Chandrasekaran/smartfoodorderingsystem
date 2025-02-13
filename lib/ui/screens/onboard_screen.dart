// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/constants.dart';
import '../sheets/onboard_data.dart';
import 'userselection_screen.dart';

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
          Container(
            // margin: EdgeInsets.symmetric(horizontal: 20),
            child: PageView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: controller.items.length,
              controller: pageController,
              onPageChanged: (index) {
                setState(() {
                  currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.15),
                      Container(
                        height: screenHeight * 0.55,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20)),
                        child: Center(
                          child: Image.asset(
                            controller.items[index].image,
                            height: screenHeight * 0.9,
                            width: screenWidth * 0.8,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // SizedBox(height: screenHeight * 0.01),
                      Text(
                        controller.items[index].title,
                        style: GoogleFonts.roboto(
                          fontSize: screenWidth * 0.047,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 45),
                        child: Text(
                          controller.items[index].description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
                          onPressed: () => pageController
                              .jumpToPage(controller.items.length - 1),
                          child: Text(
                            "Skip",
                            style: GoogleFonts.roboto(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                              gradient: primaryColor, shape: BoxShape.circle),
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 20.0,
                            child: IconButton(
                                onPressed: () => pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 600),
                                      curve: Curves.easeIn,
                                    ),
                                icon:
                                    SvgPicture.asset("assets/icons/right.svg")),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      key: const ValueKey('center'),
                      child: Container(
                        decoration: const BoxDecoration(
                            gradient: primaryColor, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 20.0,
                          backgroundColor: Colors.transparent,
                          child: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const UserSelectionScreen(),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      var begin = 0.0;
                                      var end = 1.0;
                                      var curve = Curves.easeInOut;

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));

                                      return FadeTransition(
                                        opacity: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              icon: SvgPicture.asset("assets/icons/check.svg")),
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
