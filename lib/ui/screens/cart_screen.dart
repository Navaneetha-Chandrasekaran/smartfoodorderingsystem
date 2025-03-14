import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_tile.dart';
import '../../models/constants.dart';
import '../../models/titles.dart';
import '../sheets/food_menu.dart';
import '../sheets/navigator.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Consumer<FoodMenu>(
      builder: (context, foodMenu, child) {
        final userCart = foodMenu.cart;

        return Scaffold(
          appBar: AppBar(
            title: Titles(title: 'Cart'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: secondaryColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigation.goBack(context);
              },
            ),
          ),
          body: userCart.isEmpty
              ? _buildEmptyCartUI(screenWidth)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: userCart.length,
                        itemBuilder: (context, index) {
                          return CartTile(cartItem: userCart[index]);
                        },
                      ),
                    ),
                    _buildCheckoutButton(context),
                    SizedBox(height: screenWidth * 0.1)
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyCartUI(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/empty.png',
            width: screenWidth * 0.5,
          ),
          SizedBox(height: 20),
          Text("Your cart is empty!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Looks like you haven't added anything yet.", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50)),
      onPressed: () {
        print("Proceeding to checkout...");
      },
      child: SubTitles(title: "Go to Checkout", color: Colors.white),
    );
  }
}
