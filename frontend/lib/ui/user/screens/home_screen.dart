// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../models/constants.dart';
import '../../../models/error_dialog.dart';
import '../../../models/shop.dart';
import '../../../models/titles.dart';
import '../../../sheets/navigator.dart';
import 'isthara_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Shop>> _futureShops;

  @override
  void initState() {
    super.initState();
    _futureShops = fetchShops();
  }

  Future<List<Shop>> fetchShops() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    if (baseUrl.isEmpty) throw Exception("API_BASE_URL not set in .env");

    final url = Uri.parse('$baseUrl/shop/get-shops');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> shopsJson = data['shops'];
      final shops = shopsJson.map((json) => Shop.fromJson(json)).toList();
      shops.sort((a, b) => b.isOpen.toString().compareTo(a.isOpen.toString()));
      return shops;
    } else {
      throw Exception('Failed to load shops');
    }
  }

  void _retryFetch() {
    setState(() {
      _futureShops = fetchShops();
    });
  }

  @override
  Widget build(BuildContext context) {
    double sw = MediaQuery.of(context).size.width;
    double sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(sh * 0.3),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          title: Titles(title: 'Welcome'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                onPressed: () {
                  Navigation.navigateTo(context, NotificationScreen());
                },
                icon: Icon(Icons.notifications, color: Colors.black, size: sw * 0.08),
              ),
            ),
          ],
          flexibleSpace: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    bottomRight: Radius.circular(80),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 15,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SubTitles(title: 'Tap, Collect and Delight!', fontSize: sw * 0.045),
                          SizedBox(height: sh * 0.005),
                          Description(description: "Let's find your favorite food"),
                        ],
                      ),
                    ),
                    Image.asset('assets/fav.png', width: sw * 0.2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: FutureBuilder<List<Shop>>(
          future: _futureShops,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ErrorDialog.show(
                  context,
                  title: "Shop Load Failed",
                  message: snapshot.error.toString(),
                  onRetry: _retryFetch,
                );
              });
              return const SizedBox(); // Return empty widget to prevent build issues
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No shops available"));
            }

            final shops = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: sh * 0.02),
                SubTitles(title: 'Dish Up Your Cravings!'),
                SizedBox(height: sh * 0.04),
                ...shops.map((shop) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Shops(
                      icon: Image.asset('assets/shop.png', width: sw * 0.08, height: sh * 0.08),
                      shopName: SubTitles(title: shop.name, fontSize: sw * 0.04),
                      status: Image.asset(
                        shop.isOpen ? 'assets/open.png' : 'assets/close.png',
                        width: sw * 0.18,
                        height: sh * 0.18,
                      ),
                      destination: shop.name.toLowerCase() == 'isthara'
                          ? IstharaScreen(shopId: shop.id)  // Pass the shopId
                          : null, 
                      shop: shop,
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}
