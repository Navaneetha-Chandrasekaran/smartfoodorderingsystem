// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AddedToCartPopup extends StatefulWidget {
  final bool isVisible;
  final String foodName;

  const AddedToCartPopup({
    super.key,
    required this.isVisible,
    required this.foodName,
  });

  @override
  _AddedToCartPopupState createState() => _AddedToCartPopupState();
}

class _AddedToCartPopupState extends State<AddedToCartPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // ✅ Scale bounce effect
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Smooth pop effect
    );

    // ✅ Fade-in for check icon
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void didUpdateWidget(AddedToCartPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible) {
      _controller.forward(from: 0.0); // Restart animation
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: widget.isVisible ? 80 : -100, // ✅ Slide up/down
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.isVisible ? 1.0 : 0.0, // ✅ Smooth fade-in/out
        child: ScaleTransition(
          scale: _scaleAnimation, // ✅ Apply bounce effect
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Animated Check Icon
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                ),
                const SizedBox(width: 10),
                Text(
                  "${widget.foodName} added to cart!",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
