import 'package:bitetimenew/ui/canteen/screens/login_screen.dart';
import 'package:bitetimenew/ui/canteen/screens/profile_screen.dart';
import 'package:bitetimenew/ui/canteen/sheets/navbar.dart';
import 'package:bitetimenew/ui/user/screens/cart_screen.dart';
import 'package:bitetimenew/ui/user/screens/isthara_screen.dart';
import 'package:bitetimenew/ui/user/screens/login_screen.dart';
import 'package:bitetimenew/ui/user/screens/onboard_screen.dart';
import 'package:bitetimenew/ui/user/screens/timeline_screen.dart';
import 'package:bitetimenew/ui/user/sheets/navbar.dart';
import 'package:bitetimenew/userselection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_menu.dart';
import 'theme/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/order_service.dart';
import 'services/auth/login_auth.dart';

late SharedPreferences prefs;
late OrderService orderService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded: API_URL = ${dotenv.env['API_URL']}");
  } catch (e) {
    print("❌ Failed to load .env: $e");
  }

  try {
    prefs = await SharedPreferences.getInstance();
    print("✅ SharedPreferences initialized successfully!");
  } catch (e) {
    print("❌ Error initializing SharedPreferences: $e");
  }

  // Initialize OrderService
  orderService = OrderService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FoodMenu()),
        Provider<OrderService>.value(value: orderService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final userId = await AuthService.getCurrentUserId();
    setState(() {
      _isLoggedIn = userId != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CanteenNavBar(),
      theme: Provider.of<ThemeProvider>(context).themeData,
      routes: {
        '/login': (context) => const UserLoginScreen(),
        '/cart': (context) => const CartScreen(),
        '/timeline': (context) => const TimelineScreen(),
        '/home': (context) => const CustomNavBar(),
        '/canteen': (context) => const CanteenNavBar(),
        '/canteen-login': (context) => const CanteenLoginScreen(),
        '/onboard': (context) => const OnboardScreen(),
        '/user-selection': (context) => const UserSelectionScreen(),
        '/menu': (context) => const CustomNavBar(),
      },
    );
  }
}
