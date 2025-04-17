import 'package:flutter/material.dart';

import '../services/shop_service.dart';
import 'constants.dart';
import 'titles.dart';

class Shop {
  final String id;
  final String name;
  final bool isOpen;

  Shop({
    required this.id,
    required this.name,
    required this.isOpen,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    try {
      return Shop(
        id: json['id'].toString(),
        name: json['name'] ?? 'Unnamed Shop',
        isOpen: json['isOpen'] == true,
      );
    } catch (e) {
      throw Exception('Error parsing shop: $e');
    }
  }
}





class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final ShopService _shopService = ShopService();
  late Future<List<Shop>> _futureShops;

  @override
  void initState() {
    super.initState();
    _futureShops = _shopService.fetchShops();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text("Available Shops")),
      body: FutureBuilder<List<Shop>>(
        future: _futureShops,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No shops available."));
          }

          final shops = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Shops(
                  icon: Image.asset('assets/shop.png', width: screenWidth * 0.1, height: screenWidth * 0.1),
                  shopName: SubTitles(title: shop.name),
                  status: Image.asset(
                    shop.isOpen ? 'assets/open.png' : 'assets/close.png',
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                  ),
                  destination: null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}