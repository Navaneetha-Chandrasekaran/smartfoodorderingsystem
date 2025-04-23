import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OrderProcessingAnimation extends StatelessWidget {
  const OrderProcessingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
    );
  }
}

// ✅ Order Confirmation Popup with Tick Pop-Up Animation
class OrderConfirmationPopup extends StatefulWidget {
  const OrderConfirmationPopup({super.key});

  @override
  _OrderConfirmationPopupState createState() =>
      _OrderConfirmationPopupState();
}

class _OrderConfirmationPopupState extends State<OrderConfirmationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Animation Controller for Tick Pop-Up Effect
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
      lowerBound: 0.5,
      upperBound: 1.0,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    // ✅ Start the Tick Pop Animation
    Future.delayed(Duration(milliseconds: 500), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 10),
              Text("Order Placed!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Your order has been placed successfully!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderPlacedAnimation extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  
  const OrderPlacedAnimation({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<OrderPlacedAnimation> createState() => _OrderPlacedAnimationState();
}

class _OrderPlacedAnimationState extends State<OrderPlacedAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Listen for animation status changes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasNavigated) {
        _hasNavigated = true;
        // Add a delay before navigation
        Future.delayed(const Duration(milliseconds: 800), () {
          widget.onAnimationComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/pay.json',
            controller: _controller,
            width: 300,
            height: 300,
            fit: BoxFit.contain,
            onLoaded: (composition) {
              _controller.duration = composition.duration;
              _controller.forward();
            },
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                const Text(
                  "Order Placed Successfully!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Redirecting to order timeline...",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

