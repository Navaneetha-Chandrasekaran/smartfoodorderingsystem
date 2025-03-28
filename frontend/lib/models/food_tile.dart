// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../food.dart';
import 'constants.dart';
import 'titles.dart';

class FoodTile extends StatelessWidget {
  final Food food;
  final void Function()? onTap;

  const FoodTile({
    super.key,
    required this.food,
    required this.onTap, required int availableItems,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double imageSize = screenWidth * 0.3;  // Set equal size for the food images

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ✅ Food Image with equal size
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      food.image,
                      width: imageSize,
                      height: imageSize,  // Make sure the height is equal to the width
                      fit: BoxFit.cover,   // Ensure the image fits correctly
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.07),

                  // ✅ Food Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FoodName(foodName: food.name),
                        FoodPrice(foodPrice: '\u{20B9}${food.price.toString()}'),
                        SizedBox(height: screenWidth * 0.03),
                        FoodDescription(description: food.description),

                        // ✅ Available Quantity Display
                        SizedBox(height: screenWidth * 0.03),
                        FoodDescription(description: 'Available: ${food.availableQuantity}', color: secondaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✅ Divider line:
        const Divider(color: Colors.transparent, endIndent: 25, indent: 25),
      ],
    );
  }
}
