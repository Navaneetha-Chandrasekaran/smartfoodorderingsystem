import 'package:bitetimenew/ui/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:bitetimenew/models/constants.dart';

import '../ui/sheets/navigator.dart';
import 'titles.dart';

class MySliverAppBar extends StatelessWidget {
  final Widget child;
  final SubTitles title;
  final PreferredSizeWidget? bottom;
  final bool showVegOnly;
  final VoidCallback onToggle; // ✅ Callback for toggling

  const MySliverAppBar({
    super.key,
    required this.child,
    required this.title,
    this.bottom,
    required this.showVegOnly,
    required this.onToggle,
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
        // ✅ Veg/Non-Veg Toggle Button with Text
        IconButton(
          onPressed: onToggle,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Text(
              showVegOnly ? "🥦" : "🍗", // ✅ Text instead of an icon
              key: ValueKey<bool>(showVegOnly), // ✅ Smooth animation
              style: const TextStyle(
                fontSize: 16, // ✅ Adjust text size
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {Navigation.navigateTo(context, CartScreen());},
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
