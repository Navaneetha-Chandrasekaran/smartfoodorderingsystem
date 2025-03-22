import 'package:flutter/material.dart';

import '../ui/screens/timeline_screen.dart';
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
    this.labelColor, // New parameter for text color
  });

  final String label;
  final Widget? destination;
  final double? width;
  final double? height;
  final VoidCallback? onPressed;
  final Color? bg;
  final Color? labelColor; // Allows setting text color dynamically

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () {
          if (onPressed != null) {
            onPressed!();
          }
          if (destination != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination!),
            );
          }
        },
        child: Container(
          width: width ?? screenWidth * 0.75,
          height: height ?? screenHeight * 0.06,
          decoration: BoxDecoration(
            color: bg ?? Colors.transparent,
            gradient: bg == null
                ? const LinearGradient(colors: [Colors.blue, Colors.green])
                : null,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: labelColor ?? Colors.white, // Default to white if not provided
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CancelButton extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? labelColor;

  const CancelButton({
    super.key,
    required this.label,
    this.color,
    this.labelColor, required Function() onTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: () => _showCancelReasonSheet(context), // ✅ Show BottomSheet on tap
      child: Container(
        width: screenWidth * 0.75,
        height: screenWidth * 0.15, // ✅ Adjusted height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color ?? Colors.red,
        ),
        child: Center(child: SubTitles(title: label, color: labelColor ?? Colors.white)),
      ),
    );
  }

  // ✅ Show BottomSheet for cancel reasons
  void _showCancelReasonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CancelReasonSheet(
          onConfirm: (String reason) {
            Navigator.pop(context); // ✅ Close BottomSheet
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Order cancelled: $reason")),
            );
            _triggerNoOrdersScreen(context); // ✅ Trigger "No Orders" screen
          },
        );
      },
    );
  }

  // ✅ Navigates to "No Orders" Screen
  void _triggerNoOrdersScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TimelineScreen()), // ✅ Reloads timeline to show "No Orders"
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