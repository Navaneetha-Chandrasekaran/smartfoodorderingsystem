import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/sheets/food.dart';
import 'constants.dart';
import 'titles.dart';

class CartButton extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;
  final Widget? destination;

  const CartButton({
    super.key,
    required this.name,
    this.onTap, 
    this.destination,
    
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox( 
      width: screenWidth * 0.7,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20), 
          child: Container(
            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03), 
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: SubTitles(title: name),
            ),
          ),
        ),
      ),
    );
  }
}

class button extends StatelessWidget {
  const button({
    super.key,
    required this.label,
    this.destination,
    this.width,
    this.height,
    this.onPressed,
    this.bg,
  });

  final String label;
  final Widget? destination;
  final double? width;
  final double? height;
  final VoidCallback? onPressed; // onPressed callback for button
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onPressed, // Trigger the onPressed callback
        child: Container(
          width: width ?? screenWidth * 0.75,
          height: height ?? screenHeight * 0.06,
          decoration: BoxDecoration(
            color: bg ?? Colors.transparent, // Background color if provided
            gradient: bg == null ? const LinearGradient(colors: [Colors.blue, Colors.green]) : null, // Default gradient if no bg
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class OrderButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const OrderButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      child: Description(description: "Place Order", color: Colors.white),
    );
  }
}




class QuantitySelector extends StatelessWidget {
  final int quantity;
  final Food food;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.food,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Icon(Icons.remove, size: screenWidth * 0.05, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FoodPrice(foodPrice: quantity.toString()), // ✅ Updated quantity
          ),
          GestureDetector(
            onTap: onIncrement,
            child: Icon(Icons.add, size: screenWidth * 0.05, color: Colors.white),
          ),
        ],
      ),
    );
  }
}