import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitetimenew/animations/loading.dart';
import 'package:bitetimenew/animations/order.dart';
import 'package:bitetimenew/models/cart_tile.dart';
import 'package:bitetimenew/models/constants.dart';
import 'package:bitetimenew/models/payment_selector.dart';
import 'package:bitetimenew/models/time_selector.dart';
import 'package:bitetimenew/models/titles.dart';
import 'package:bitetimenew/ui/user/screens/isthara/food_menu.dart';
import 'package:bitetimenew/sheets/navigator.dart';
import 'package:bitetimenew/ui/user/sheets/navbar.dart';
import 'package:bitetimenew/models/buttons.dart';
import 'package:bitetimenew/ui/user/screens/timeline_screen.dart';
import '../sheets/shared_prefs.dart';

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

  @override
  void initState() {
    super.initState();
    loadPaymentPreference().then((value) {
      if (mounted) {
        setState(() => _selectedPayment = value);
      }
    });
  }

  void _placeOrder() {
    if (_selectedTime == null) {
      setState(() => _showTimeError = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showTimeError = false);
      });
      return;
    }

    final foodMenu = Provider.of<FoodMenu>(context, listen: false);
    setState(() => _isOrderProcessing = true);

    // ✅ Show loading animation for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _isOrderProcessing = false;
        _isOrderPlaced = true;
      });

      // ✅ Show order placed animation for 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;

        setState(() => _isOrderPlaced = false);
        foodMenu.placeOrder();

        // ✅ Navigate to Timeline Screen after all animations
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TimelineScreen()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final foodMenu = Provider.of<FoodMenu>(context);
    final userCart = foodMenu.cart;
    final totalCost = foodMenu.getTotalPrice(); // ✅ Get total cost of cart

    return Scaffold(
      appBar: AppBar(
        title: Titles(title: 'Cart'),
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
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildCartItems(userCart),
                              const SizedBox(height: 10),

                              // ✅ Total Cost Section (Added Below Ordered Food)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Total Cost:",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "₹${totalCost.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ✅ Common Time Selector
                              TimeSelector(
                                selectedTime: _selectedTime,
                                onTimeSelected: (time) {
                                  setState(() {
                                    _selectedTime = time;
                                  });
                                },
                              ),

                              SizedBox(height: screenWidth * 0.1),

                              _buildPaymentSelector(),

                              SizedBox(height: screenWidth * 0.1),

                              // ✅ Order button
                              OrderButton(
                                onPressed: _isOrderProcessing ? null : _placeOrder,
                              ),

                              SizedBox(height: screenWidth * 0.1),
                            ],
                          ),
                        ),

          // ✅ Time Selection Error Popup
          if (_showTimeError) _buildTimeErrorPopup(),
        ],
      ),
    );
  }

  /// ✅ Builds the cart items list with spacing
  Widget _buildCartItems(List userCart) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userCart.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return CartTile(cartItem: userCart[index]);
      },
    );
  }

  /// ✅ Builds the Payment Selector UI
  Widget _buildPaymentSelector() {
    return PaymentSelector(
      selectedPayment: _selectedPayment,
      onPaymentChanged: (newPayment) {
        setState(() => _selectedPayment = newPayment);
        savePaymentPreference(newPayment);
      },
    );
  }

  /// ✅ UI for Empty Cart
  Widget _buildEmptyCartUI(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/empty.png', width: screenWidth * 0.5),
          const SizedBox(height: 20),
          const Text("Your cart is empty!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Looks like you haven't added anything yet.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          button(label: 'Tap to Order!', destination: CustomNavBar()),
        ],
      ),
    );
  }

  /// ✅ Time Selection Error Popup
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
          child: const Text("Please select a pickup time before ordering!", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
