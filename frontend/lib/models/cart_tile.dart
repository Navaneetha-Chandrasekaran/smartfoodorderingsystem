// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../food_menu.dart';
import 'buttons.dart';
import '../food.dart';
import 'cart_item.dart';
import 'constants.dart';
import 'titles.dart';

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
                  child: Image.asset(
                    widget.cartItem.food.image,
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    fit: BoxFit.cover,
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
                    foodMenu.addToCart(widget.cartItem.food, widget.cartItem.selectedAddons);
                    setState(() {});
                  },
                  onDecrement: () {
                    foodMenu.removeFromCart(widget.cartItem);
                    setState(() {});
                  },
                ),
              ],
            ),

            SizedBox(height: 8),

            // ✅ Addons Section with Right-Aligned Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FoodPrice(foodPrice: "Selected Addons:"),

                // ✅ Addon Selector (Right Aligned)
                if (widget.cartItem.food.availableAddons.isNotEmpty)
                  Container(
                    width: screenWidth * 0.4,
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Addon>(
                        hint: FoodDescription(description: "Select Addon", color: Colors.white),
                        isDense: true,
                        isExpanded: false,
                        icon: Icon(Icons.arrow_drop_down, size: 16, color: Colors.black87),
                        dropdownColor: Colors.white,
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                        elevation: 4,
                        items: widget.cartItem.food.availableAddons.map((addon) {
                          return DropdownMenuItem<Addon>(
                            value: addon,
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 14, color: Colors.green),
                                SizedBox(width: screenWidth * 0.07),
                                FoodPrice(foodPrice: addon.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newAddon) {
                          setState(() {
                            // ✅ If the selected addon is a spice level, ensure only one is selected
                            if (newAddon!.spiceLevel != SpiceLevel.none) {
                              widget.cartItem.selectedAddons.removeWhere(
                                  (addon) => addon.spiceLevel != SpiceLevel.none);
                            }
                            if (!widget.cartItem.selectedAddons.contains(newAddon)) {
                              widget.cartItem.selectedAddons.add(newAddon);
                            }
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 8),

            // ✅ Display Selected Addons (Centered)
            Center(
              child: widget.cartItem.selectedAddons.isNotEmpty
                  ? Wrap(
                      spacing: 6,
                      children: widget.cartItem.selectedAddons.map((addon) {
                        return Chip(
                          label: FoodDescription(description: addon.name),
                          backgroundColor: secondaryColor,
                          deleteIcon: Icon(Icons.close, size: 14, color: Colors.red),
                          onDeleted: () {
                            setState(() {
                              widget.cartItem.selectedAddons.remove(addon);
                            });
                          },
                        );
                      }).toList(),
                    )
                  : FoodDescription(description: "No addons added", color: const Color.fromARGB(255, 182, 182, 182)),
            ),
          ],
        ),
      ),
    );
  }
}
