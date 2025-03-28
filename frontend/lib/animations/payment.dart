// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../models/titles.dart';

class AnimatedPaymentSelector extends StatefulWidget {
  final String selectedPayment;
  final Function(String) onPaymentChanged;

  const AnimatedPaymentSelector({
    super.key,
    required this.selectedPayment,
    required this.onPaymentChanged,
  });

  @override
  State<AnimatedPaymentSelector> createState() => _AnimatedPaymentSelectorState();
}

class _AnimatedPaymentSelectorState extends State<AnimatedPaymentSelector> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _selectedPayment = "GPay";

  @override
  void initState() {
    super.initState();
    _selectedPayment = widget.selectedPayment;

    // ✅ Animation Setup
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedPaymentSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPayment != oldWidget.selectedPayment) {
      setState(() {
        _selectedPayment = widget.selectedPayment;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ Payment Selection Dropdown
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: screenWidth * 0.95,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            SubTitles(title: "Select Payment Method"),
            SizedBox(height: screenWidth * 0.04),
            DropdownButton<String>(
              value: _selectedPayment,
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              // style: TextStyle(color: Colors.black, fontSize: 14),
              isExpanded: true,
              underline: SizedBox(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPayment = newValue;
                  });
                  widget.onPaymentChanged(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: "GPay",
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.blue),
                      SizedBox(width: screenWidth * 0.05),
                      Description(description: "GPay"),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: "Cash",
                  child: Row(
                    children: [
                      Icon(Icons.money, color: Colors.green),
                      SizedBox(width: screenWidth * 0.05),
                      Description(description: "Cash"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

