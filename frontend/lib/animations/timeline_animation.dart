import 'package:flutter/material.dart';

class TimelineAnimation extends StatefulWidget {
  final bool isPast;
  final Widget child;
  final String orderNumber;
  final Set<String> animatedOrders;

  const TimelineAnimation({
    super.key,
    required this.isPast,
    required this.child,
    required this.orderNumber,
    required this.animatedOrders
  });

  @override
  State<TimelineAnimation> createState() => _TimelineAnimationState();
}

class _TimelineAnimationState extends State<TimelineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // ✅ Quick effect
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if(widget.isPast && !widget.animatedOrders.contains(widget.orderNumber)){
      widget.animatedOrders.add(widget.orderNumber);
      Future.delayed(const Duration(milliseconds: 500), (){
        if(mounted){
          _controller.forward().then((_){
            _controller.reverse();
          });
        }
      });
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
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}