import 'package:flutter/material.dart';
import '../food.dart';
import '../services/utils.dart';
import 'constants.dart';
import 'titles.dart';

class FoodTile extends StatelessWidget {
  final Food food;
  final void Function()? onTap;

  const FoodTile({
    super.key,
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double imageSize = screenWidth * 0.3;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ✅ Food Image (Asset or Network)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildImage(food.image, imageSize),
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

                        SizedBox(height: screenWidth * 0.03),
                        FoodDescription(
                          description: 'Available: ${food.availableQuantity}',
                          color: secondaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✅ Divider for spacing
        const Divider(color: Colors.transparent, endIndent: 25, indent: 25),
      ],
    );
  }

  /// ✅ Handle both asset and network images
  Widget _buildImage(String imagePath, double size) {
    final String fullImageUrl = getFullImageUrl(imagePath);

    return Image.network(
      fullImageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
    );
  }
}
