// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

import '../../../models/constants.dart';
import '../../../models/error_dialog.dart';
import '../../../models/shop.dart';
import '../../../models/titles.dart';
import '../../../models/common_lottie.dart';
import '../../../sheets/navigator.dart';
import 'isthara_screen.dart';
import 'notification_screen.dart';
import '../../../services/shop_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late Future<List<Shop>> _futureShops;
  String? _selectedShopId;
  late AnimationController _animationController;
  late Animation<double> _floatingAnimation;
  final GlobalKey _headerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _futureShops = fetchShops();
    _loadSelectedShopId();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _floatingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedShopId() async {
    try {
      final shopService = ShopService();
      final shopId = await shopService.getStoredShopId();
      print("🔍 Loaded selected shop ID: $shopId");
      if (mounted) {
        setState(() {
          _selectedShopId = shopId;
        });
      }
    } catch (e) {
      print("❌ Error loading selected shop ID: $e");
    }
  }

  Future<List<Shop>> fetchShops() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      if (baseUrl.isEmpty) {
        print("❌ API_BASE_URL is not set in .env");
        throw Exception("API_BASE_URL not set in .env");
      }

      print("🌐 Fetching shops from: $baseUrl/shop/get-shops");
      final url = Uri.parse('$baseUrl/shop/get-shops');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.get(url, headers: headers);
      print("📥 Response status: ${response.statusCode}");
      
      // Guard against empty body
      if (response.body.isEmpty) {
        print("⚠️ Response body is empty");
        return [];
      }
      
      print("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>?;
          if (data == null) {
            print("❌ Failed to parse response as JSON");
            return [];
          }
          
          if (data['shops'] == null) {
            print("❌ No shops found in response");
            return [];
          }
          
          final List<dynamic>? shopsJson = data['shops'] as List<dynamic>?;
          if (shopsJson == null || shopsJson.isEmpty) {
            print("❌ Shops list is null or empty");
            return [];
          }
          
          final shops = shopsJson
              .where((json) => json != null) // Filter out null entries
              .map((json) => Shop.fromJson(json as Map<String, dynamic>))
              .toList();
              
          if (shops.isEmpty) {
            print("⚠️ No valid shops found after parsing");
            return [];
          }
          
          // Sort shops with null-safety
          shops.sort((a, b) {
            if (a.isOpen == null && b.isOpen == null) return 0;
            if (a.isOpen == null) return 1; // Null isOpen goes last
            if (b.isOpen == null) return -1;
            return b.isOpen.toString().compareTo(a.isOpen.toString());
          });
          
          print("✅ Successfully loaded ${shops.length} shops");
          
          // Store the first shop's ID if no shop is selected and there are valid shops
          if (_selectedShopId == null && shops.isNotEmpty && shops[0].id != null) {
            final shopService = ShopService();
            await shopService.storeSelectedShopId(shops[0].id!);
            _selectedShopId = shops[0].id;
            print("📝 Stored default shop ID: ${shops[0].id}");
          }
          
          return shops;
        } catch (e) {
          print("❌ Error parsing response: $e");
          throw Exception("Failed to parse shops data: $e");
        }
      } else if (response.statusCode == 404) {
        print("❌ Endpoint not found: ${response.statusCode}");
        throw Exception("Shop endpoint not found. Please check the API configuration.");
      } else if (response.statusCode == 500) {
        print("❌ Server error: ${response.statusCode}");
        throw Exception("Server error occurred. Please try again later.");
      } else {
        print("❌ Failed to load shops: ${response.statusCode}");
        throw Exception("Failed to load shops: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching shops: $e");
      throw Exception("Failed to load shops: $e");
    }
  }

  void _retryFetch() {
    print("🔄 Retrying shop fetch...");
    setState(() {
      _futureShops = fetchShops();
    });
  }

  @override
  Widget build(BuildContext context) {
    double sw = MediaQuery.of(context).size.width;
    double sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with scrolling
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Animated Header
                SliverToBoxAdapter(
                  child: _buildAnimatedHeader(sw, sh),
                ),
                // Content area
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.05),
                    child: _buildShopsList(sw, sh),
                  ),
                ),
                // Add some padding at the bottom
                SliverToBoxAdapter(
                  child: SizedBox(height: sh * 0.1),
                ),
              ],
            ),
            
            // Notification button (stays fixed at top)
            Positioned(
              top: sh * 0.02,
              right: sw * 0.05,
              child: _buildNotificationButton(sw),
            ),
          ],
        ),
      ),
      // Floating action button to refresh the shop list
      floatingActionButton: FloatingActionButton(
        backgroundColor: kLogoGreen,
        elevation: 4,
        onPressed: _retryFetch,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (_, child) {
            return Transform.rotate(
              angle: _animationController.value * 0.5 * pi,
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: sw * 0.06,
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildNotificationButton(double sw) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(sw * 0.06),
      child: InkWell(
        onTap: () {
          Navigation.navigateTo(context, const NotificationScreen());
        },
        borderRadius: BorderRadius.circular(sw * 0.06),
        child: Container(
          padding: EdgeInsets.all(sw * 0.02),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(sw * 0.06),
          ),
          child: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: kLogoGreen,
                size: sw * 0.07,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: sw * 0.02,
                  height: sw * 0.02,
                decoration: BoxDecoration(
                    color: kLogoOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedHeader(double sw, double sh) {
    return Container(
      key: _headerKey,
      height: sh * 0.28,
      width: sw,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kLogoGreen,
            kLogoGreen.withOpacity(0.8),
            kLogoGreen.withOpacity(0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(sw * 0.08),
          bottomRight: Radius.circular(sw * 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: sw * 0.05,
            spreadRadius: sw * 0.01,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative elements
          Positioned(
            top: -sw * 0.1,
            right: -sw * 0.1,
            child: Container(
              width: sw * 0.4,
              height: sw * 0.4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
                ),
              ),
              Positioned(
            bottom: -sw * 0.15,
            left: -sw * 0.15,
            child: Container(
              width: sw * 0.5,
              height: sw * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.06, vertical: sh * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          'Welcome to',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: sw * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'BiteTime',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sw * 0.08,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    
                    // Hero image
                    AnimatedBuilder(
                      animation: _floatingAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, sin(_animationController.value * pi) * 5),
                          child: Image.asset(
                            'assets/fav.png',
                            width: sw * 0.25,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: sh * 0.02),
                
                // Slogan with animation
                AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.6 + (_animationController.value * 0.4),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.04,
                      vertical: sw * 0.02,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(sw * 0.04),
                    ),
                    child: Text(
                      'Tap, Collect, and Delight!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sw * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: sh * 0.01),
                
                // Subtitle
                Text(
                  "Let's find your favorite food",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: sw * 0.035,
                    fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
  
  Widget _buildShopsList(double sw, double sh) {
    return FutureBuilder<List<Shop>>(
          future: _futureShops,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: sh * 0.3,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CommonLottie.loading(size: sw * 0.2),
                  SizedBox(height: sh * 0.02),
                  Text(
                    "Discovering food spots...",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: sw * 0.035,
                    ),
                  ),
                ],
              ),
            ),
              );
            } else if (snapshot.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ErrorDialog.show(
                  context,
                  title: "Shop Load Failed",
                  message: snapshot.error.toString(),
                  onRetry: _retryFetch,
                );
              });
          return SizedBox(
            height: sh * 0.3,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[300],
                    size: sw * 0.15,
                  ),
                  SizedBox(height: sh * 0.02),
                  Text(
                    "Couldn't load food spots",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: sw * 0.04,
                    ),
                  ),
                  Text(
                    "Tap the refresh button to try again",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: sw * 0.035,
                    ),
                  ),
                ],
              ),
            ),
          );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: sh * 0.3,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/no-order.json',
                    width: sw * 0.3,
                    height: sw * 0.3,
                  ),
                  SizedBox(height: sh * 0.02),
                  Text(
                    "No food spots available",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: sw * 0.04,
                    ),
                  ),
                ],
              ),
            ),
          );
            }

            final shops = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            SizedBox(height: sh * 0.03),
            
            // Section title with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(20 * (1 - value), 0),
                    child: child,
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: sw * 0.02,
                    height: sh * 0.04,
                    decoration: BoxDecoration(
                      color: kLogoGreen,
                      borderRadius: BorderRadius.circular(sw * 0.01),
                    ),
                  ),
                  SizedBox(width: sw * 0.02),
                  Text(
                    'Dish Up Your Cravings!',
                    style: TextStyle(
                      fontSize: sw * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: sh * 0.015),
            
            // Subheading
            Padding(
              padding: EdgeInsets.only(left: sw * 0.04),
              child: Text(
                'Select your preferred food spot',
                style: TextStyle(
                  fontSize: sw * 0.035,
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            SizedBox(height: sh * 0.03),
            
            // List of shops with staggered animation
            ...List.generate(shops.length, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500 + (index * 100)),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildShopCard(shops[index], sw, sh),
              );
            }),
          ],
        );
      },
    );
  }
  
  Widget _buildShopCard(Shop shop, double sw, double sh) {
    bool isSelected = _selectedShopId == shop.id;
    
    return Container(
      margin: EdgeInsets.only(bottom: sh * 0.02),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(sw * 0.04),
          onTap: () async {
            // Haptic feedback would be nice here
            await ShopService().storeSelectedShopId(shop.id);
            setState(() {
              _selectedShopId = shop.id;
            });
            
            // Navigate if it's a special shop
            if (shop.name.toLowerCase() == 'isthara' && shop.id != null) {
              Navigation.navigateTo(context, IstharaScreen(shopId: shop.id!));
            }
          },
          splashColor: kLogoGreen.withOpacity(0.1),
          highlightColor: kLogoGreen.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.all(sw * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(sw * 0.04),
              color: isSelected ? Colors.green.shade50 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                    ? kLogoGreen.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.05),
                  blurRadius: sw * 0.02,
                  spreadRadius: isSelected ? sw * 0.003 : sw * 0.001,
                  offset: Offset(0, sw * 0.01),
                ),
              ],
              border: Border.all(
                color: isSelected 
                  ? kLogoGreen.withOpacity(0.5) 
                  : Colors.grey.withOpacity(0.1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Shop icon with status indicator
                Stack(
                  children: [
                    Container(
                      width: sw * 0.15,
                      height: sw * 0.15,
                      decoration: BoxDecoration(
                        color: kLogoGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/shop.png',
                          width: sw * 0.08,
                          height: sw * 0.08,
                          color: kLogoGreen,
                        ),
                      ),
                    ),
                    
                    // Status indicator dot
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: sw * 0.04,
                        height: sw * 0.04,
                        decoration: BoxDecoration(
                          color: shop.isOpen == true ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(width: sw * 0.04),
                
                // Shop details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Shop name
                          Text(
                            shop.name,
                            style: TextStyle(
                              fontSize: sw * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: sw * 0.02),
                            Icon(
                              Icons.check_circle,
                              color: kLogoGreen,
                              size: sw * 0.045,
                            ),
                          ],
                        ],
                      ),
                      
                      SizedBox(height: sh * 0.005),
                      
                      // Shop status
                      Row(
                        children: [
                          Container(
                            width: sw * 0.02,
                            height: sw * 0.02,
                            decoration: BoxDecoration(
                              color: shop.isOpen == true ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: sw * 0.01),
                          Text(
                            shop.isOpen == true ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: sw * 0.035,
                              color: shop.isOpen == true ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action indicator
                Icon(
                  Icons.arrow_forward_ios,
                  color: kLogoGreen,
                  size: sw * 0.04,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
