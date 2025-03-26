import 'package:bitetimenew/models/constants.dart';
import 'package:flutter/material.dart';

class EventCard extends StatefulWidget {
  final bool isPast;
  final Widget child;

  const EventCard({
    super.key,
    required this.isPast,
    required this.child,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // ✅ Smooth transition
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // ✅ Start animation when event is past
    if (widget.isPast) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPast && !oldWidget.isPast) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.all(25),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isPast ? secondaryColor : Colors.grey,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  if (widget.isPast)
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)
                ],
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
