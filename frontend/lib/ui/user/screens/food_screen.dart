  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:flutter_dotenv/flutter_dotenv.dart';

  import '../../../models/buttons.dart';
  import '../../../food.dart';
  import '../../../food_menu.dart';
  import '../../../models/shop.dart';
  import '../../../models/titles.dart';
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

  class _FoodScreenState extends State<FoodScreen> {
    @override
    void initState() {
      super.initState();
    }

  // void addToCart(Food food) async {
  //   final foodMenu = Provider.of<FoodMenu>(context, listen: false);

  //   foodMenu.addToCart(food);

  //   final baseUrl = dotenv.env['API_BASE_URL']?.trim();
  //   if (baseUrl == null || baseUrl.isEmpty) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("API base URL not configured")),
  //       );
  //     }
  //     return;
  //   }

  //   try {
  //     // Fetch the shop data dynamically
  //     final shopService = ShopService();
  //     List<Shop> shops = await shopService.fetchShops();  // This resolves the Future and gives us the list of shops

  //     if (shops.isEmpty) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text("No shops available")),
  //         );
  //       }
  //       return;
  //     }

  //     // Get the shopId from the first shop or implement logic to select the appropriate shop
  //     final shopId = shops[0].id; // Use the first shop's ID for now, modify as needed

  //     // Fetch the userId (you can get it from your app's user session or provider)
  //     final userId = await _getUserId(); // This is a method you'll need to define

  //     final payload = {
  //       'user_id': userId,  // Assuming you have a method to get the userId dynamically
  //       'shop_id': shopId.toString(),
  //       'food_id': food.id,
  //       'quantity': 1,
  //     };

  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
  //     );

  //     final response = await http
  //         .post(
  //           Uri.parse('$baseUrl/cart/add'),
  //           headers: {'Content-Type': 'application/json'},
  //           body: jsonEncode(payload),
  //         )
  //         .timeout(const Duration(seconds: 10), onTimeout: () {
  //       throw TimeoutException("The connection has timed out");
  //     });

  //     if (mounted) Navigator.of(context, rootNavigator: true).pop();

  //     print("Response status: ${response.statusCode}");
  //     print("Response body: ${response.body}");  // Print the response body for debugging

  //     if (response.statusCode == 200) {
  //       if (mounted) {
  //         showDialog(
  //           context: context,
  //           builder: (context) => AddedToCartPopup(food: food),
  //         );
  //       }
  //     } else {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("Server error: ${response.body}")),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       Navigator.of(context, rootNavigator: true).maybePop();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Connection error: $e")),
  //       );
  //     }
  //   }
  // }

  void addToCart(Food food) async {
  final foodMenu = Provider.of<FoodMenu>(context, listen: false);
  foodMenu.addToCart(food);

  final baseUrl = dotenv.env['API_BASE_URL']?.trim();
  if (baseUrl == null || baseUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("API base URL not configured")),
    );
    return;
  }

  try {
    final shopService = ShopService();
    List<Shop> shops = await shopService.fetchShops();

    if (shops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No shops available")),
      );
      return;
    }

    final shopId = shops[0].id.toString();
    final userId = await _getUserId();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    // ✅ Use CartService now
    final cartService = CartService();
    final result = await cartService.addToCart(userId, shopId, food.id.toString());

    print("User ID: $userId");
    print("Shop ID: $shopId");
    print('Food ID: ${food.id}');

    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    if (result['success']) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AddedToCartPopup(food: food),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${result['message']}")),
      );
    }
  } catch (e) {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error: $e")),
      );
    }
  }
}


  // You can define this method to retrieve the userId dynamically (for example, from an AuthService or a provider)
  Future<String> _getUserId() async {
    // Implement your logic here to fetch the userId (from a provider, user session, etc.)
    // For example, using a provider or AuthService to get the current user ID
    return ''; // Replace this with actual logic
  }


    @override
    Widget build(BuildContext context) {
      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;

      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: screenWidth,
                    height: screenHeight * 0.4,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child: Image.network(
                        getFullImageUrl(widget.food.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: _buildBackButton(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenWidth * 0.03),
                    FoodName(foodName: widget.food.name),
                    SizedBox(height: screenWidth * 0.01),
                    FoodPrice(foodPrice: "₹${widget.food.price}"),
                    SizedBox(height: screenWidth * 0.02),
                    FoodDescription(description: widget.food.description),
                    SizedBox(height: screenWidth * 0.05),
                    SizedBox(height: 20),
                    Center(
                      child: CartButton(
                        name: 'Add to cart',
                        onTap: () {
                          if (widget.food.availableQuantity > 0) {
                            addToCart(widget.food);
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => const OutOfStockPopup(),
                            );
                          }
                        },
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
      return InkWell(
        onTap: () => Navigation.goBack(context),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, spreadRadius: 2),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
      );
    }
  }

  class AddedToCartPopup extends StatelessWidget {
    final Food food;

    const AddedToCartPopup({super.key, required this.food});

    @override
    Widget build(BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 10),
              Text(
                '${food.name} added to cart!',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the popup first
                  Navigator.pushNamed(context, '/cart'); // Then navigate to cart
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('OK'),
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
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 60),
              const SizedBox(height: 10),
              const Text(
                'Out of Stock!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    }
  }