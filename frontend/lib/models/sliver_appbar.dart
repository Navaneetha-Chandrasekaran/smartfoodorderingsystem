import 'package:flutter/material.dart';
import '../sheets/navigator.dart';
import '../ui/user/screens/cart_screen.dart';
import 'constants.dart';
import 'titles.dart';

class MySliverAppBar extends StatelessWidget {
  final Widget child;
  final SubTitles title;
  final PreferredSizeWidget? bottom;
  final bool showVegOnly; // For Veg Toggle state
  final bool showNonVegOnly; // For Non-Veg Toggle state
  final VoidCallback onToggle; // Callback for Veg toggle
  final VoidCallback onNonVegToggle; // Callback for Non-Veg toggle

  const MySliverAppBar({
    super.key,
    required this.child,
    required this.title,
    this.bottom,
    required this.showVegOnly,
    required this.showNonVegOnly,
    required this.onToggle,
    required this.onNonVegToggle,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return SliverAppBar(
      expandedHeight: screenHeight * 0.1,
      collapsedHeight: screenHeight * 0.15,
      floating: false,
      pinned: true,
      centerTitle: true,
      actions: [
        // ✅ Veg Toggle Button
        IconButton(
          onPressed: onToggle,  // Corrected this callback to use the provided onToggle
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: showVegOnly ? Colors.green : Colors.transparent,  // Highlight green when Veg toggle is on
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "🥦",  // Veg Icon
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // ✅ Non-Veg Toggle Button
        IconButton(
          onPressed: onNonVegToggle,  // Corrected this callback to use the provided onNonVegToggle
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: showNonVegOnly ? Colors.red : Colors.transparent,  // Highlight red when Non-Veg toggle is on
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "🍗",  // Non-Veg Icon
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // ✅ Cart Button
        IconButton(
          onPressed: () => Navigation.navigateTo(context, CartScreen()),
          icon: const Icon(Icons.shopping_cart),
        ),
      ],
      backgroundColor: secondaryColor,
      title: title,
      flexibleSpace: FlexibleSpaceBar(
        background: child,
        centerTitle: true,
      ),
      bottom: bottom,
    );
  }
}
