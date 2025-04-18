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

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override 
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _selectedPayment = "GPay";
  bool _isOrderProcessing = false;
  bool _isOrderPlaced = false;
  bool _showTimeError = false;
  TimeOfDay? _selectedTime; // ✅ Common time selector for the whole cart
  String? _otp;

  @override
  void initState() {
    super.initState();
    loadPaymentPreference().then((value) {
      if (mounted) {
        setState(() => _selectedPayment = value);
      }
    });
  }

  // void _placeOrder() async {
  //   final foodMenu = Provider.of<FoodMenu>(context, listen: false);
  //   final shopId = await ShopService().getStoredShopId(); // Get the selected shopId

  //   if (foodMenu.cart.isEmpty) return; // ✅ Prevent order placement when cart is empty

  //   if (_selectedTime == null) {
  //     setState(() => _showTimeError = true);
  //     Future.delayed(const Duration(seconds: 3), () {
  //       if (mounted) setState(() => _showTimeError = false);
  //     });
  //     return;
  //   }

  //   if (shopId == null) {
  //     setState(() => _showTimeError = true); // Display an error if no shop is selected
  //     Future.delayed(const Duration(seconds: 3), () {
  //       if (mounted) setState(() => _showTimeError = false);
  //     });
  //     return;
  //   }

  //   setState(() => _isOrderProcessing = true);

  //   // Simulate order placement delay
  //   Future.delayed(const Duration(seconds: 5), () { // Combined loading + order placed delay
  //     if (!mounted) return;

  //     setState(() {
  //       _isOrderProcessing = false;
  //       _isOrderPlaced = true;
  //     });

  //     // Pass the necessary data (time, otp, payment method, and shopId) to place the order
  //     foodMenu.placeOrder(_selectedTime, _otp, _selectedPayment, shopId);

  //     Future.delayed(const Duration(seconds: 3), () {
  //       if (mounted) {
  //         setState(() => _isOrderPlaced = false);
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => const TimelineScreen()),
  //         );
  //       }
  //     });
  //   });
  // }

  void _placeOrder() async {
  final foodMenu = Provider.of<FoodMenu>(context, listen: false);
  final shopId = await ShopService().getStoredShopId(); // Get the selected shopId

  // Retrieve userId from shared preferences using AuthService
  final userId = await AuthService.getCurrentUserId(); // This uses the static method

  print("🔍 ShopId: $shopId"); // Debug: Print shopId
  print("🔍 UserId: $userId"); // Debug: Print userId

  if (foodMenu.cart.isEmpty) {
    print("❌ Cart is empty!"); // Debug: Cart is empty
    return; // ✅ Prevent order placement when cart is empty
  }

  if (_selectedTime == null) {
    print("❌ No pickup time selected!"); // Debug: No time selected
    setState(() => _showTimeError = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTimeError = false);
    });
    return;
  }

  if (shopId == null) {
    print("❌ No shop selected!"); // Debug: No shop selected
    setState(() => _showTimeError = true); // Display an error if no shop is selected
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTimeError = false);
    });
    return;
  }

  print("🔄 Placing order..."); // Debug: Order is being placed
  setState(() => _isOrderProcessing = true);

  // Now call the OrderService to place the order
  final orderService = OrderService();

  // Pass the data to place the order
  final result = await orderService.placeOrder(
    userId: userId.toString(),  // Pass the userId retrieved from shared preferences
    shopId: shopId,
    pickupTime: _selectedTime!.format(context), // Assuming you need the formatted time string
    paymentMethod: _selectedPayment,
    totalAmount: foodMenu.getTotalPrice(), // Pass total amount
    cartItems: foodMenu.cart, // Pass cart items
  );

  print("📦 Order placement result: $result"); // Debug: Log the result of the API call

  if (result.containsKey('error')) {
    // Handle error (e.g., show a message to the user)
    print("❌ Error placing order: ${result['error']}"); // Debug: Log error message
    setState(() {
      _isOrderProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['error'])),
    );
    return;
  }

  // Success
  setState(() {
    _isOrderProcessing = false;
    _isOrderPlaced = true;

    // Check if 'otp' exists and is of a valid type
    if (result['otp'] != null) {
      _otp = result['otp'].toString();  // Convert it to a String if it's not null
    } else {
      _otp = null;  // Handle the case where OTP is missing
    }
  });


  print("✔️ Order placed successfully. OTP: $_otp"); // Debug: Order placed successfully

  // Navigate to the timeline screen
  Future.delayed(const Duration(seconds: 5), () {
    if (mounted) {
      setState(() => _isOrderPlaced = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TimelineScreen()),
      );
    }
  });
}



  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final foodMenu = Provider.of<FoodMenu>(context);
    final userCart = foodMenu.cart;
    final totalCost = foodMenu.getTotalPrice(); // ✅ Get total cost of cart

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Titles(title: '🛒 Your Cart'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: secondaryColor,
        leading: InkWell(
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
          _isOrderProcessing
              ? LoadingAnimation()
              : _isOrderPlaced
                  ? OrderPlacedAnimation()
                  : userCart.isEmpty
                      ? _buildEmptyCartUI(context)
                      : Column(
                          children: [
                            Expanded(child: _buildCartItems(userCart)),

                            // ✅ Floating Checkout Card
                            _buildCheckoutSection(totalCost),
                          ],
                        ),

          // ✅ Time Selection Error Popup
          if (_showTimeError) _buildTimeErrorPopup(),
        ],
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/empty.png', width: screenWidth * 0.5),
          const SizedBox(height: 20),
          const Text("Oops! Your cart is empty.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Let's add some delicious food!", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Browse Menu 🍽️',
            destination: CustomNavBar(),
          )
        ],
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
