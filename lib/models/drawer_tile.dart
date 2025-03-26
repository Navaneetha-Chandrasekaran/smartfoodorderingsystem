import 'package:bitetimenew/models/titles.dart';
import 'package:flutter/material.dart';

class DrawerTile extends StatefulWidget {
  final SubTitles text;
  final IconData? icon;
  final void Function()? onTap;

  const DrawerTile({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  State<DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<DrawerTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Properly initialize animation controller & scale animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse(); // Reset animation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (widget.onTap != null) {
          widget.onTap!(); // Navigate after animation
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade300], // Soft highlight effect
                  ),
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: Colors.black),
                    const SizedBox(width: 15),
                    widget.text,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
