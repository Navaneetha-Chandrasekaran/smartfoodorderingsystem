import 'package:bitetimenew/models/constants.dart';
import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final bool isPast;
  final Widget child;

  const EventCard({
    super.key,
    required this.isPast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1), // ✅ Smooth fade effect
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPast ? secondaryColor : Colors.grey,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (isPast) BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)
        ],
      ),
      child: child,
    );
  }
}
