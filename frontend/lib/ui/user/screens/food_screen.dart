import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../food.dart';
import '../../../food_menu.dart';
import '../../../models/shop.dart';
import '../../../services/auth/login_auth.dart';
import '../../../services/cart_service.dart';
import '../../../services/shop_service.dart';
import '../../../sheets/navigator.dart';
import '../../../services/utils.dart';

class FoodScreen extends StatefulWidget {
  final Food food;
  const FoodScreen({super.key, required this.food});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> with TickerProviderStateMixin {
  String? userName;

  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserName();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.elasticOut),
    );

    // Start the animations
    _fadeController!.forward();
  }

  void _loadUserName() async {
    final name = await AuthService.getCurrentName();
    setState(() {
      userName = name ?? 'Guest';
    });
  }

  Future<int?> _getUserId() async {
    final userId = await AuthService.getCurrentUserId();
    print("User ID from AuthService: $userId");

    if (userId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      throw Exception("User not logged in");
    }
    return userId;
  }

  void addToCart(Food food) async {
    try {
      final userId = await _getUserId();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final foodMenu = Provider.of<FoodMenu>(context, listen: false);
      foodMenu.addToCart(food);

      final baseUrl = dotenv.env['API_BASE_URL']?.trim();
      if (baseUrl == null || baseUrl.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      final shopService = ShopService();
      List<Shop> shops = await shopService.fetchShops();

      final shopId = shops.isNotEmpty ? shops[0].id.toString() : null;

      if (shopId == null) {
        Navigator.of(context).pop();
        return;
      }

      final cartService = CartService();
      final result = await cartService.addToCart(userId.toString(), shopId, food.id.toString());

      Navigator.of(context).pop();

      if (result['success']) {
        showDialog(
          context: context,
          builder: (context) => AddedToCartPopup(food: food),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${result['message']}")),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: screenWidth,
                  height: screenHeight * 0.42,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(getFullImageUrl(widget.food.image)),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: _buildBackButton(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userName != null)
                    Text(
                      "Hello, $userName 👋",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                    ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: SlideTransition(
                      position: _slideAnimation!,
                      child: Text(
                        widget.food.name,
                        style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Text(
                      "₹${widget.food.price}",
                      style: GoogleFonts.poppins(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Text(
                      widget.food.description,
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation!,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.food.availableQuantity > 0) {
                              addToCart(widget.food);
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => const OutOfStockPopup(),
                              );
                            }
                          },
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('Add to Cart'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigation.goBack(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: const Center(
          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    super.dispose();
  }
}

class AddedToCartPopup extends StatelessWidget {
  final Food food;

  const AddedToCartPopup({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            Text(
              '${food.name} added to cart!',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Great!'),
            ),
          ],
        ),
      ),
    );
  }
}

class OutOfStockPopup extends StatelessWidget {
  const OutOfStockPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Out of Stock!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}