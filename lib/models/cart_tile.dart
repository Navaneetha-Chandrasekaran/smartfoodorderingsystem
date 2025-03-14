import 'package:bitetimenew/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/sheets/food_menu.dart';
import 'buttons.dart';
import '../ui/sheets/food.dart';

class CartTile extends StatefulWidget {
  final CartItem cartItem;

  const CartTile({super.key, required this.cartItem});

  @override
  State<CartTile> createState() => _CartTileState();
}

class _CartTileState extends State<CartTile> {
  Addon? selectedAddon;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.cartItem.selectedAddons.isNotEmpty) {
      selectedAddon = widget.cartItem.selectedAddons.first;
    }
  }

  // ✅ Function to get icon based on spice level
  IconData getSpiceIcon(SpiceLevel? level) {
    switch (level) {
      case SpiceLevel.medium:
        return Icons.local_fire_department; // 🌶 Medium Spice
      case SpiceLevel.full:
        return Icons.whatshot; // 🔥 Full Spice
      default:
        return Icons.check_circle_outline; // ✅ No Spice
    }
  }

  // ✅ Open Time Selector
  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // ✅ Format time with AM/PM
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

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
            // ✅ Row 1: Image | Name | Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ Food Image (Left Side)
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

                // ✅ Food Name & Quantity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Food Name
                      Text(
                        widget.cartItem.food.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),

                      // ✅ Food Price (Updated Dynamically)
                      Text(
                        '₹${(widget.cartItem.food.price * widget.cartItem.quantity).toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[800], fontSize: 14),
                      ),
                      SizedBox(height: 4),

                      // ✅ Quantity Selector (Right Side)
                      QuantitySelector(
                        food: widget.cartItem.food,
                        quantity: widget.cartItem.quantity,
                        onIncrement: () {
                          foodMenu.addToCart(widget.cartItem.food, widget.cartItem.selectedAddons);
                          setState(() {}); // Refresh UI on change
                        },
                        onDecrement: () {
                          foodMenu.removeFromCart(widget.cartItem);
                          setState(() {}); // Refresh UI on change
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // ✅ Addon Dropdown & Time Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ Addon Dropdown or "No addons added"
                if (widget.cartItem.food.availableAddons.isNotEmpty)
                  Container(
                    width: screenWidth * 0.4,
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Addon>(
                        value: selectedAddon,
                        isDense: true,
                        isExpanded: false,
                        icon: Icon(Icons.arrow_drop_down, size: 16, color: Colors.black87),
                        dropdownColor: Colors.white,
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                        elevation: 4,
                        items: [
                          if (selectedAddon != null)
                            DropdownMenuItem<Addon>(
                              value: null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close, color: Colors.red, size: 14),
                                  SizedBox(width: 6),
                                  Text("Remove", style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ...widget.cartItem.food.availableAddons.map((addon) {
                            return DropdownMenuItem<Addon>(
                              value: addon,
                              child: Row(
                                children: [
                                  Icon(
                                    getSpiceIcon(addon.spiceLevel),
                                    color: addon.spiceLevel == SpiceLevel.full ? Colors.red : Colors.orange,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(addon.name, style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (newAddon) {
                          setState(() {
                            if (newAddon == null) {
                              widget.cartItem.selectedAddons.clear();
                              selectedAddon = null;
                            } else {
                              widget.cartItem.selectedAddons.clear();
                              widget.cartItem.selectedAddons.add(newAddon);
                              selectedAddon = newAddon;
                            }
                          });
                        },
                      ),
                    ),
                  )
                else
                  Text(
                    "No addons added",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                // ✅ Time Selector with AM/PM
                InkWell(
                  onTap: () => _pickTime(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue, size: 16),
                        SizedBox(width: 6),
                        Text(
                          selectedTime != null
                              ? _formatTime(selectedTime!)
                              : "Select Time",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
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
