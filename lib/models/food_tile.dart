import 'package:bitetimenew/models/titles.dart';
import 'package:flutter/material.dart';
import '../ui/sheets/food.dart';

class FoodTile extends StatelessWidget {
  final Food food;
  final void Function()? onTap;

  const FoodTile({
    super.key,
    required this.food,
    required this.onTap

  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
            
                //Food Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FoodName(foodName: food.name),
                      FoodPrice(foodPrice: '₹${food.price.toString()}'),

                      SizedBox(height: screenWidth * 0.03),
                      FoodDescription(description: food.description)
                    ],
                  )
                ),

                SizedBox(width: screenWidth * 0.07),
            
                //Food Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(food.image, width: screenWidth * 0.3,)
                )
              ],
            ),
          ),
        ),


        //Divider line:
        const Divider(
          color: Colors.transparent,
          endIndent: 25,
          indent: 25,
        )
      ],
    );
  }
}
