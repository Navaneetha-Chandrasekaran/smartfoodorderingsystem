import 'dart:async';
import 'dart:math'; 
import 'package:flutter/material.dart';
import '../../models/buttons.dart';
import '../../models/confirm_dialog.dart';
import '../../models/event_card.dart';
import '../../models/timeline.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  int _currentStep = 0;
  String _orderOtp = ''; 

  @override
  void initState() {
    super.initState();
    _generateOtp();
    _startTimelineAnimation();
  }

  void _generateOtp() {
    Random random = Random();
    setState(() {
      _orderOtp = (1000 + random.nextInt(9000)).toString();
    });
  }

  void _startTimelineAnimation() async {
    for (int i = 0; i <= 3; i++) {
      await Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentStep = i + 1;
          });
        }
      });
    }
  }

  void _cancelOrder() {
    setState(() {
      _currentStep = 0;
      _orderOtp = '';
    });
    Navigator.pop(context); // Go back to the previous screen (e.g., CartScreen)
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Order Timeline"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: InkWell(
            onTap: () => Navigator.pop(context), // Go back to the previous screen
            child: Container(
              width: screenWidth * 0.05,
              height: screenWidth * 0.05,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        children: [
          const SizedBox(height: 20),

          // Display OTP
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Order OTP: $_orderOtp",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Timeline Steps
          Timeline(
            isFirst: true,
            isLast: false,
            isPast: _currentStep >= 1,
            eventCard: EventCard(isPast: _currentStep >= 1, child: const Text('Order Placed')),
          ),
          Timeline(
            isFirst: false,
            isLast: false,
            isPast: _currentStep >= 2,
            eventCard: EventCard(isPast: _currentStep >= 2, child: const Text('Order Confirmed')),
          ),
          Timeline(
            isFirst: false,
            isLast: false,
            isPast: _currentStep >= 3,
            eventCard: EventCard(isPast: _currentStep >= 3, child: const Text('Order getting ready')),
          ),
          Timeline(
            isFirst: false,
            isLast: true,
            isPast: _currentStep >= 4,
            eventCard: EventCard(isPast: _currentStep >= 4, child: const Text('Ready for Pickup')),
          ),

          // Cancel Order Button
          SizedBox(height: screenWidth * 0.08),
          button(
            label: 'Cancel Order',
            bg: const Color.fromARGB(255, 255, 18, 1),
            onPressed: () => _showCancelOrderDialog(context), // Show cancel confirmation dialog
          ),
          SizedBox(height: screenWidth * 0.1)
        ],
      ),
    );
  }

  // Show confirmation dialog before canceling the order
  void _showCancelOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          onConfirm: _cancelOrder,
        );
      },
    );
  }
}
