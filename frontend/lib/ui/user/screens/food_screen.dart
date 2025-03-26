import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/buttons.dart';
import '../../../food.dart';
import '../../../food_menu.dart';
import '../../../models/titles.dart';
import '../../../sheets/navigator.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodScreen extends StatefulWidget {
  final Food food;
  const FoodScreen({super.key, required this.food});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  late List<bool> _selectedAddons;
  Addon? selectedSpiceAddon;

  @override
  void initState() {
    super.initState();
    _selectedAddons = List.filled(widget.food.availableAddons.length, false);
  }

  /// ✅ Add to cart
  void addToCart(Food food) {
    final foodMenu = Provider.of<FoodMenu>(context, listen: false);
    List<Addon> selectedAddons = [];
    for (int i = 0; i < widget.food.availableAddons.length; i++) {
      if (_selectedAddons[i]) {
        selectedAddons.add(widget.food.availableAddons[i]);
      }
    }

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
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ **Food Image with Glassmorphism Effect**
            Stack(
              children: [
                SizedBox(
                  width: screenWidth,
                  height: screenHeight * 0.4,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: Image.asset(widget.food.image, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: _buildBackButton(),
                ),
              ],
            ),

            /// ✅ **Food Details**
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenWidth * 0.03),
                  FoodName(foodName: widget.food.name),
                  SizedBox(height: screenWidth * 0.01),
                  FoodPrice(foodPrice: "₹${widget.food.price}"),
                  SizedBox(height: screenWidth * 0.02),
                  FoodDescription(description: widget.food.description),

                  SizedBox(height: screenWidth * 0.05),
                  _buildAddonSection(),

                  SizedBox(height: 20),

                  /// ✅ **Add to Cart Button with Gradient & Shadow**
                  Center(
                    child: CartButton(
                      name: 'Add to cart',
                      onTap: () => addToCart(widget.food),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ **Back Button with Glass Effect**
  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigation.goBack(context),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
      ),
    );
  }

  /// ✅ **Addons Section with Chip-Style UI**
  Widget _buildAddonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Description(description: 'Addons'),
        Divider(color: Colors.grey[400]),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.food.availableAddons.asMap().entries.map((entry) {
            int index = entry.key;
            Addon addon = entry.value;

            return ChoiceChip(
              label: Text(
                addon.name,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              selected: _selectedAddons[index],
              onSelected: (bool selected) {
                setState(() {
                  if (addon.spiceLevel != SpiceLevel.none) {
                    if (selected) {
                      // Unselect previous spice addon
                      if (selectedSpiceAddon != null) {
                        int prevIndex = widget.food.availableAddons.indexOf(selectedSpiceAddon!);
                        if (prevIndex != -1) {
                          _selectedAddons[prevIndex] = false;
                        }
                      }
                      selectedSpiceAddon = addon;
                    } else {
                      selectedSpiceAddon = null;
                    }
                  }
                  _selectedAddons[index] = selected;
                });
              },
              selectedColor: Colors.green.withOpacity(0.2),
              backgroundColor: Colors.grey[300],
              labelStyle: TextStyle(
                color: _selectedAddons[index] ? Colors.green[900] : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// ✅ **Animated "Added to Cart" Popup**
class AddedToCartPopup extends StatelessWidget {
  final Food food;

  const AddedToCartPopup({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: Tween(begin: 0.7, end: 1.0).animate(
          CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeOutBack),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text(
                '${food.name} added to cart!',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
