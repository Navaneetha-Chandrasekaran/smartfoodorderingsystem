import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../animations/loading.dart';
import '../../../animations/order.dart';
import '../../../food_menu.dart';
import '../../../models/buttons.dart';
import '../../../models/cart_tile.dart';
import '../../../models/constants.dart';
import '../../../models/payment_selector.dart';
import '../../../models/time_selector.dart';
import '../../../models/titles.dart';
import '../../../services/auth/login_auth.dart';
import '../../../services/order_service.dart';
import '../../../services/shop_service.dart';
import '../../../sheets/navigator.dart';
import '../sheets/navbar.dart';
import '../sheets/shared_prefs.dart';
import 'timeline_screen.dart';
import '../../../models/cart_item.dart';
import 'package:lottie/lottie.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override 
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  String _selectedPayment = "GPay";
  bool _isOrderProcessing = false;
  bool _isOrderPlaced = false;
  bool _showTimeError = false;
  bool _canNavigate = false;
  TimeOfDay? _selectedTime; // ✅ Common time selector for the whole cart
  String? _otp;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    loadPaymentPreference().then((value) {
      if (mounted) {
        setState(() => _selectedPayment = value);
      }
    });
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }
  
  Future<void> _placeOrder() async {
    print("🛒 Starting order placement from cart screen...");
    
    // Prevent multiple order placements
    if (_isOrderProcessing || _isOrderPlaced) {
      return;
    }
    
    // Check if user is logged in first
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) {
      print("❌ User not logged in, redirecting to login...");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    print("✅ User authenticated: $userId");

    final foodMenu = Provider.of<FoodMenu>(context, listen: false);
    final shopId = await ShopService().getStoredShopId();
    print("🏪 Shop ID: $shopId");

    if (foodMenu.cart.isEmpty) {
      print("❌ Cart is empty!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty!")),
      );
      return;
    }
    print("✅ Cart has ${foodMenu.cart.length} items");

    if (_selectedTime == null) {
      print("❌ No pickup time selected!");
      setState(() => _showTimeError = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showTimeError = false);
      });
      return;
    }
    print("✅ Pickup time selected: ${_selectedTime!.format(context)}");

    if (shopId == null) {
      print("❌ No shop selected!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a shop first!")),
      );
      return;
    }

    print("🔄 Processing order...");
    setState(() {
      _isOrderProcessing = true;
      _isOrderPlaced = false;
      _canNavigate = false;
    });

    try {
      // Store cart items before placing order
      final List<CartItem> orderedItems = List.from(foodMenu.cart);
      print("📦 Stored ${orderedItems.length} items for order");

      final orderService = OrderService();
      final result = await orderService.placeOrder(
        userId: userId.toString(),
        shopId: shopId,
        pickupTime: _selectedTime!.format(context),
        paymentMethod: _selectedPayment,
        totalAmount: foodMenu.getTotalPrice(),
        cartItems: orderedItems,
        context: context,
      );

      print("📦 Order placement result: $result");

      if (!mounted) return;

      if (result.containsKey('error')) {
        print("❌ Error placing order: ${result['error']}");
        setState(() => _isOrderProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'])),
        );
        return;
      }

      final orderData = {
          'order_id': result['order_id'].toString(),
          'otp': result['otp'].toString(),
          'items': orderedItems.map((item) => {
          'id': item.food.id,
            'name': item.food.name,
            'quantity': item.quantity,
            'price': item.food.price,
            'description': item.food.description,
          'image': item.food.image,
          'isVeg': item.food.isVeg,
          'total_item_price': item.food.price * item.quantity,
          }).toList(),
          'payment_mode': _selectedPayment,
          'pickup_time': _selectedTime!.format(context),
          'total_amount': foodMenu.getTotalPrice(),
      };

      try {
        // Store the order data and clear cart
        await Provider.of<FoodMenu>(context, listen: false).setLatestOrderData(orderData);
        foodMenu.clearCart();
        print("✅ Cart cleared and order data stored");

        if (!mounted) return;

        // Show success animation
        setState(() {
          _isOrderProcessing = false;
          _isOrderPlaced = true;
          _otp = result['otp']?.toString();
          _canNavigate = false;
        });

        print("✔️ Order placed successfully. OTP: $_otp");
      } catch (e) {
        print("❌ Error handling order success: $e");
        if (mounted) {
          setState(() => _isOrderProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error completing order: $e")),
          );
        }
      }

    } catch (e) {
      print("❌ Exception while placing order: $e");
      if (mounted) {
      setState(() => _isOrderProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error placing order: $e")),
        );
      }
    }
  }

  void _handleAnimationComplete() {
    if (!_canNavigate && mounted && context.mounted) {
      setState(() => _canNavigate = true);
      print("🔄 Animation completed, navigating to timeline screen...");
      Navigator.pushReplacementNamed(
        context,
        '/timeline',
        arguments: Provider.of<FoodMenu>(context, listen: false).latestOrderData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final foodMenu = Provider.of<FoodMenu>(context);
    final userCart = foodMenu.cart;
    final totalCost = foodMenu.getTotalPrice();

    return WillPopScope(
      onWillPop: () async {
        if (_isOrderPlaced || _isOrderProcessing) {
          return false;
        }
        return true;
      },
      child: Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Titles(title: '🛒 Your Cart'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: secondaryColor,
          leading: (_isOrderPlaced || _isOrderProcessing)
            ? null
            : InkWell(
          onTap: () => Navigation.goBack(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: screenWidth * 0.05,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
            if (_isOrderPlaced)
              OrderPlacedAnimation(
                onAnimationComplete: _handleAnimationComplete,
              )
            else if (_isOrderProcessing)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              )
          else if (userCart.isEmpty)
            _buildEmptyCartUI(context)
          else
            Column(
              children: [
                Expanded(child: _buildCartItems(userCart)),
                _buildCheckoutSection(totalCost),
              ],
            ),

          if (_showTimeError) _buildTimeErrorPopup(),
        ],
        ),
      ),
    );
  }

  Widget _buildCartItems(List userCart) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: userCart.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return CartTile(cartItem: userCart[index]);
      },
    );
  }

  Widget _buildCheckoutSection(double totalCost) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🧾 Total Cost Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Text(
                "₹${totalCost.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ⏰ Time Picker
          TimeSelector(
            selectedTime: _selectedTime,
            onTimeSelected: (time) {
              if (time != _selectedTime) {
                setState(() => _selectedTime = time);
              }
            },
          ),

          const SizedBox(height: 16),

          // 💳 Payment Method
          _buildPaymentSelector(),

          const SizedBox(height: 25),

          // 🚀 Order Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isOrderProcessing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
              label: const Text(
                "Place Order",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelector() {
    return PaymentSelector(
      selectedPayment: _selectedPayment,
      onPaymentChanged: (newPayment) {
        if (newPayment != _selectedPayment) { // ✅ Avoid unnecessary rebuilds
          setState(() => _selectedPayment = newPayment);
          savePaymentPreference(newPayment);
        }
      },
    );
  }

  Widget _buildEmptyCartUI(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF6F8FB),
            const Color(0xFFEFF2F7),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.8,
                      height: screenWidth * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF00FF00).withOpacity(0.1),
                            const Color(0xFF008000).withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FF00).withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Lottie.asset(
                        'assets/lottie/cart-empty.json',
                        width: screenWidth * 0.4,
                        height: screenWidth * 0.4,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.1),
                AnimatedBuilder(
                  animation: _floatingController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 10 * sin(_floatingController.value * pi)),
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            const Color(0xFF00FF00),
                            const Color(0xFF008000),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          "Your cart is empty",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            const Color(0xFF00CC00),
                            const Color(0xFF00FF00),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          "Let's add some delicious food!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C00),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF00).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CustomNavBar()),
                        );
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.restaurant_menu_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Browse Menu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeErrorPopup() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text("⚠️ Please select a pickup time!", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
