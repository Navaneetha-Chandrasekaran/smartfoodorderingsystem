import 'package:bitetimenew/models/constants.dart';
import 'package:bitetimenew/models/titles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/buttons.dart';
import '../sheets/food.dart';
import '../sheets/food_menu.dart';
import '../sheets/navigator.dart';

class FoodScreen extends StatefulWidget {
  final Food food;
  const FoodScreen({super.key, required this.food});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  late List<bool> _selectedAddons; // ✅ Track selected checkboxes
  Addon? selectedSpiceAddon; // ✅ Track the selected spice-level addon

  @override
  void initState() {
    super.initState();
    _selectedAddons = List.filled(widget.food.availableAddons.length, false);
  }

  // ✅ Add to cart
  void addToCart(Food food) {
    final foodMenu = Provider.of<FoodMenu>(context, listen: false);

    // ✅ Get selected addons
    List<Addon> selectedAddons = [];
    for (int i = 0; i < widget.food.availableAddons.length; i++) {
      if (_selectedAddons[i]) {
        selectedAddons.add(widget.food.availableAddons[i]);
      }
    }

    // ✅ Add food + selected addons to cart
    foodMenu.addToCart(food, selectedAddons);

    // ✅ Show animated confirmation popup
    showDialog(
      context: context,
      builder: (context) => AddedToCartPopup(food: food),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: screenWidth,
                  height: screenWidth * 0.9,
                  child: Image.asset(widget.food.image, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: InkWell(
                    onTap: () => Navigation.goBack(context),
                    child: Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenWidth * 0.03),
                  FoodName(foodName: widget.food.name),

                  SizedBox(height: screenWidth * 0.03),
                  FoodPrice(foodPrice: widget.food.price.toString()),

                  FoodDescription(description: widget.food.description),

                  SizedBox(height: screenWidth * 0.05),

                  Description(description: 'Addons'),
                  Divider(color: Colors.grey),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.food.availableAddons.length,
                    itemBuilder: (context, index) {
                      final addon = widget.food.availableAddons[index];

                      return CheckboxListTile(
                        title: Text(addon.name),
                        value: _selectedAddons[index],
                        onChanged: (bool? value) {
                          setState(() {
                            if (addon.spiceLevel != SpiceLevel.none) {
                              // ✅ If addon is a spice level, ensure only one is selected
                              if (value == true) {
                                // Uncheck previous spice addon
                                if (selectedSpiceAddon != null) {
                                  int previousIndex = widget.food.availableAddons.indexOf(selectedSpiceAddon!);
                                  if (previousIndex != -1) {
                                    _selectedAddons[previousIndex] = false;
                                  }
                                }
                                // Select new spice-level addon
                                selectedSpiceAddon = addon;
                              } else {
                                // Remove spice-level addon
                                selectedSpiceAddon = null;
                              }
                            }

                            _selectedAddons[index] = value ?? false;
                          });
                        },
                      );
                    },
                  ),

                  SizedBox(height: 20),

                  Center(
                    child: CartButton(
                      name: 'Add to cart',
                      onTap: () => addToCart(widget.food)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Animated Popup for "Added to Cart"
class AddedToCartPopup extends StatelessWidget {
  final Food food;

  const AddedToCartPopup({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: Tween(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeOutBack),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text('${food.name} added to cart!', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
