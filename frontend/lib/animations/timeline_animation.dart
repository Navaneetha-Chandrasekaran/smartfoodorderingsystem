import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _rotateAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Schedule animation for next frame if needed
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndStartAnimation();
      }
    });
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.white.withOpacity(0.8),
      end: Colors.white,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.02, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Set initial state for past items
    if (widget.isPast && !widget.isRefreshing && !widget.animatedOrders.contains(widget.orderNumber)) {
      _controller.value = 1.0;
    }
  }

  void _checkAndStartAnimation() {
    if (!_isAnimating && (widget.animatedOrders.contains(widget.orderNumber) || widget.isRefreshing)) {
      _playAnimation();
    }
  }

  Future<void> _playAnimation() async {
    if (_isAnimating || !mounted) return;
    
    try {
      _isAnimating = true;
      await _controller.forward(from: 0.0);
      
      if (widget.isRefreshing && mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          await _controller.reverse();
          if (mounted) {
            await _controller.forward();
          }
        }
      }
    } catch (e) {
      print("Animation error: $e");
    } finally {
      if (mounted) {
        _isAnimating = false;
      }
    }
  }

  @override
  void didUpdateWidget(TimelineAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Schedule animation check for next frame
    if ((widget.isRefreshing && !oldWidget.isRefreshing) || 
        (widget.isPast && !oldWidget.isPast)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkAndStartAnimation();
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
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (widget.isPast)
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}