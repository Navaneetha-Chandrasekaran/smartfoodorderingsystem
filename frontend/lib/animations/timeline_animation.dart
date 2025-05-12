import 'package:flutter/material.dart';

class TimelineAnimation extends StatefulWidget {
  final bool isPast;
  final Widget child;
  final String orderNumber;
  final Set<String> animatedOrders;
  final bool isRefreshing;

  const TimelineAnimation({
    super.key,
    required this.isPast,
    required this.child,
    required this.orderNumber,
    required this.animatedOrders,
    this.isRefreshing = false,
  });

  @override
  State<TimelineAnimation> createState() => _TimelineAnimationState();
}

class _TimelineAnimationState extends State<TimelineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.green.shade50,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if ((widget.isPast && !widget.animatedOrders.contains(widget.orderNumber)) || 
        widget.isRefreshing) {
      
      if (widget.isPast && !widget.animatedOrders.contains(widget.orderNumber)) {
        widget.animatedOrders.add(widget.orderNumber);
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final delay = widget.isRefreshing ? 100 : 500;
          Future.delayed(Duration(milliseconds: delay), () {
            if (mounted) {
              _controller.forward().then((_) {
                if (mounted) {
                  _controller.reverse();
                }
              });
            }
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(TimelineAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward().then((_) {
            if (mounted) {
              _controller.reverse();
            }
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
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: _colorAnimation.value,
                  borderRadius: BorderRadius.circular(12),
                ),
            child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}