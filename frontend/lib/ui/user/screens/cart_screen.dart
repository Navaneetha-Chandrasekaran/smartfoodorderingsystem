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
import '../../../services/auth_service.dart' as auth;

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
      // Store cart items before placing order - DEEP COPY to preserve all item details
      final List<CartItem> orderedItems = List.from(foodMenu.cart);
      
      // Add debug output for ordered items before API call
      print("📦 Captured ${orderedItems.length} items from cart before placing order");
      for (var item in orderedItems) {
        print("   📝 Item: ${item.food.name}, price=${item.food.price}, quantity=${item.quantity}");
      }

      final orderService = OrderService();
      
      // Convert TimeOfDay to DateTime
      final now = DateTime.now();
      final pickupDateTime = DateTime(
        now.year, 
        now.month, 
        now.day,
        _selectedTime!.hour, 
        _selectedTime!.minute
      );
      
      final List<Map<String, dynamic>> foodItemsForApi = orderedItems.map((item) => {
        'food_id': item.food.id,
        'quantity': item.quantity,
        // Include full item details for local storage
        'name': item.food.name,
        'price': item.food.price,
        'description': item.food.description,
        'image': item.food.image,
        'isVeg': item.food.isVeg,
        'category': item.food.category.name,
        'total_price': item.food.price * item.quantity,
      }).toList();
      
      final result = await orderService.placeOrder(
        await auth.AuthService.getCurrentUserId() ?? "",
        shopId,
        pickupDateTime,
        _selectedPayment,
        foodMenu.getTotalPrice(),
        foodItemsForApi,
      );

      print("📦 Order placement result: $result");

      if (!mounted) return;

      if (result['success'] == false) {
        print("❌ Error placing order: ${result['message']}");
        setState(() => _isOrderProcessing = false);
        
        // Handle authentication error specifically
        if (result['message'].toString().contains('Authentication failed')) {
          // Show auth error and prompt to login again
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(result['message'])),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ),
          );
          return;
        }
        
        // Handle other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        return;
      }

      // Create a well-formed order data object with complete food details
      final orderData = {
          'order_id': result['order_id'].toString(),
          'otp': result['otp'].toString(),
          'items': orderedItems.map((item) => {
            'id': item.food.id,
            'food_id': item.food.id,
            'name': item.food.name,
            'quantity': item.quantity,
            'price': item.food.price,
            'total_price': item.food.price * item.quantity,
            'total_item_price': item.food.price * item.quantity,
            'description': item.food.description,
            'image': item.food.image,
            'isVeg': item.food.isVeg,
            'category': item.food.category.name,
          }).toList(),
          'payment_method': _selectedPayment,
          'pickup_time': _selectedTime!.format(context),
          'total_amount': foodMenu.getTotalPrice(),
          'status': 'pending',
          'shop_id': shopId,
      };

      // Debug the items data before saving
      print("📦 Order data created with ${(orderData['items'] as List).length} items");
      for (var item in orderData['items'] as List) {
        print("📦 Order item: name=${item['name']}, price=${item['price']}, quantity=${item['quantity']}, total=${item['total_price']}");
      }

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
      
      // Get the latest order data from FoodMenu provider
      final foodMenu = Provider.of<FoodMenu>(context, listen: false);
      final orderData = foodMenu.latestOrderData;
      
      if (orderData == null) {
        print("❌ Error: No order data available for timeline");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error retrieving order data")),
        );
        Navigator.pushReplacementNamed(context, '/menu');
        return;
      }
      
      // Verify that items exist in the order data
      final items = orderData['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) {
        print("⚠️ Warning: Order data has no items! Order ID: ${orderData['order_id']}");
      } else {
        print("✅ Navigating to timeline with order #${orderData['order_id']} containing ${items.length} items");
        // Debug item contents before navigation
        for (var item in items) {
          print("   📝 Item: ${item['name']}, price=${item['price']}, quantity=${item['quantity']}, total=${item['total_price'] ?? item['total_item_price'] ?? 'N/A'}");
        }
      }
      
      // Create a proper deep copy of the order data with all required fields - VERY IMPORTANT
      final deepCopyOrderData = {
        'order_id': orderData['order_id']?.toString() ?? '',
        'otp': orderData['otp']?.toString() ?? '',
        'payment_method': orderData['payment_method']?.toString() ?? '',
        'pickup_time': orderData['pickup_time']?.toString() ?? '',
        'total_amount': orderData['total_amount'] is num ? orderData['total_amount'] : 0.0,
        'status': orderData['status']?.toString() ?? 'pending',
        'shop_id': orderData['shop_id']?.toString() ?? '',
        'shop_name': foodMenu.getShopNameById(orderData['shop_id']?.toString() ?? '') ?? 'Unknown Shop',
        'items': items != null ? items.map((item) => {
          'id': item['id']?.toString() ?? '',
          'food_id': item['food_id']?.toString() ?? item['id']?.toString() ?? '',
          'name': item['name']?.toString() ?? 'Unknown Item',
          'quantity': item['quantity'] is int ? item['quantity'] : 
                     (item['quantity'] is String ? int.tryParse(item['quantity']) ?? 1 : 1),
          'price': item['price'] is num ? item['price'] : 
                  (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
          'total_price': item['total_price'] is num ? item['total_price'] :
                        (item['total_item_price'] is num ? item['total_item_price'] : 
                        (item['price'] is num && item['quantity'] is num ? 
                          (item['price'] as num) * (item['quantity'] as num) : 0.0)),
          'total_item_price': item['total_item_price'] is num ? item['total_item_price'] :
                             (item['total_price'] is num ? item['total_price'] : 
                             (item['price'] is num && item['quantity'] is num ? 
                              (item['price'] as num) * (item['quantity'] as num) : 0.0)),
          'description': item['description']?.toString() ?? '',
          'image': item['image']?.toString() ?? '',
          'isVeg': item['isVeg'] is bool ? item['isVeg'] : true,
          'category': item['category']?.toString() ?? '',
        }).toList() : [],
      };
      
      // One more verification to ensure our deep copy worked correctly
      final copiedItems = deepCopyOrderData['items'] as List<dynamic>;
      if (copiedItems.isNotEmpty) {
        print("✅ Deep copy successful with ${copiedItems.length} items");
        for (var item in copiedItems) {
          print("   📝 Copied Item: ${item['name']}, price=${item['price']}, quantity=${item['quantity']}, total=${item['total_price']}");
        }
      } else {
        print("⚠️ Warning: Deep copy produced empty items list");
      }
      
      // Add a small delay to give the backend time to register the order
      // This is important to ensure the order is saved on the backend before we try to fetch it
      Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacementNamed(
        context,
        '/timeline',
          arguments: deepCopyOrderData,
      );
      });
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
