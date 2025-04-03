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
  final foodMenu = Provider.of<FoodMenu>(context, listen: false);
  
  if (foodMenu.cart.isEmpty) return; // ✅ Prevent order placement when cart is empty

  if (_selectedTime == null) {
    setState(() => _showTimeError = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTimeError = false);
    });
    return;
  }

  setState(() => _isOrderProcessing = true);

  Future.delayed(const Duration(seconds: 5), () { // Combined loading + order placed delay
    if (!mounted) return;

    setState(() {
      _isOrderProcessing = false;
      _isOrderPlaced = true;
    });

    foodMenu.placeOrder(_selectedTime); // ✅ Pass pickup time to order

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _isOrderPlaced = false);

      // ✅ Prevent duplicate navigation by checking if mounted
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TimelineScreen()),
        );
      }
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

  /// ✅ Builds the cart items list with spacing
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

  /// ✅ Floating Checkout Card
  Widget _buildCheckoutSection(double totalCost) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      children: [
        // ✅ Total Cost
        Row(
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
        const SizedBox(height: 15),

        // ✅ Time Selector
        TimeSelector(
          selectedTime: _selectedTime,
          onTimeSelected: (time) {
            if (time != _selectedTime) { // ✅ Avoid unnecessary state updates
              setState(() {
                _selectedTime = time;
              });
            }
          },
        ),

        const SizedBox(height: 15),

        // ✅ Payment Selector
        _buildPaymentSelector(),

        const SizedBox(height: 15),

        // ✅ Order Button
        OrderButton(
          onPressed: _isOrderProcessing ? null : _placeOrder, // ✅ Prevent multiple taps
        ),
      ],
      ),
    );
  }


  /// ✅ Builds the Payment Selector UI
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


  /// ✅ UI for Empty Cart
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
          child: const Text("⚠️ Please select a pickup time!", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}