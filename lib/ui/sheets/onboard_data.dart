// ignore_for_file: unused_import

import 'package:flutter/material.dart';

class OnboardData {
  final String title;
  final String description;
  final String image;

  OnboardData({
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardDetails {
  List<OnboardData> items = [
    OnboardData(
      title: 'Welcome to BiteTime!',
      description:
          "Skip the lines! Browse the menu, order your meals, and schedule pickups—all in a few taps.",
      image: "assets/onboard/1.png",
    ),
    OnboardData(
      title: "Seamless Ordering & Secure Payments",
      description:
          "Choose your dish, customize your order, and pay securely with Google Pay. Quick and easy!",
      image: "assets/onboard/2.png",
    ),
    OnboardData(
      title: "Real-Time Updates & Effortless Pickup",
      description:
          "Get notified when your order is ready. Scan your QR code for a fast, hassle-free pickup!",
      image: "assets/onboard/3.png",
    ),
  ];
}
