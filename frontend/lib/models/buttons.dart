import 'package:flutter/material.dart';

import '../ui/user/screens/timeline_screen.dart';
import '../food.dart';
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


class CustomButton extends StatelessWidget {
  final String label;
  final Widget? destination;
  final double? width;
  final double? height;
  final VoidCallback? onPressed;
  final List<Color>? gradientColors; // ✅ Custom Gradient Colors
  final Color? labelColor;
  final IconData? icon;
  final bool iconRight;
  final bool hasBorder; // ✅ Optional Border
  final Color? borderColor; // ✅ Custom Border Color

  const CustomButton({
    super.key,
    required this.label,
    this.destination,
    this.width,
    this.height,
    this.onPressed,
    this.gradientColors, // ✅ Allows custom gradients
    this.labelColor,
    this.icon,
    this.iconRight = true,
    this.hasBorder = false, // ✅ Default: No Border
    this.borderColor,
  });

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
            gradient: LinearGradient(
              colors: gradientColors ?? [Color(0xFF40CF58), Color(0xFF4AFD69)], // ✅ Default Gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            border: hasBorder ? Border.all(color: borderColor ?? Colors.white, width: 2) : null, // ✅ Optional Border
            boxShadow: [
              BoxShadow(
                color: (gradientColors ?? [Colors.green, Colors.blue])[0].withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              /// ✅ **Centered Button Text**
              Center(
                child: Titles(title: label, color: Colors.white)
              ),

              /// ✅ **Optional Icon (Right or Left)**
              if (icon != null)
                Positioned(
                  right: iconRight ? 15 : null,
                  left: iconRight ? null : 15,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(icon, color: gradientColors?[0] ?? Colors.green),
                  ),
                ),
            ],
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