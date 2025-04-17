// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../food_menu.dart';
import '../services/utils.dart';
import 'buttons.dart';
import 'cart_item.dart';

class CartTile extends StatefulWidget {
  final CartItem cartItem;

  const CartTile({super.key, required this.cartItem});

  @override
  State<CartTile> createState() => _CartTileState();
}

class _CartTileState extends State<CartTile> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final foodMenu = Provider.of<FoodMenu>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Food Image | Name & Price | Quantity Selector
            Row(
              children: [
                // ✅ Food Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    getFullImageUrl(widget.cartItem.food.image),
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: screenWidth * 0.2),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),

                // ✅ Food Name & Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cartItem.food.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '₹${(widget.cartItem.food.price * widget.cartItem.quantity).toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[800], fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // ✅ Quantity Selector
                QuantitySelector(
                  food: widget.cartItem.food,
                  quantity: widget.cartItem.quantity,
                  onIncrement: () {
                    foodMenu.addToCart(widget.cartItem.food);
                    setState(() {});
                  },
                  onDecrement: () {
                    foodMenu.removeFromCart(widget.cartItem);
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}