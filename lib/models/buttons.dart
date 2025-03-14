import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/sheets/food.dart';
import 'constants.dart';
import 'titles.dart';

class CartButton extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const CartButton({
    super.key,
    required this.name,
    required this.onTap,
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
    required this.destination,
  });

  final String label;
  final Widget destination;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => destination));
      },
      child: Container(
        width: screenWidth * 0.75,
        height: screenHeight * 0.06,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            gradient: primaryColor, borderRadius: BorderRadius.circular(50)),
        child: Center(
          child: Text(label,
              style: GoogleFonts.roboto(
                  fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold)),
        ),
      ),
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