import 'package:bitetimenew/ui/canteen/screens/login_screen.dart';
import 'package:bitetimenew/ui/canteen/screens/profile_screen.dart';
import 'package:bitetimenew/ui/canteen/sheets/navbar.dart';
import 'package:bitetimenew/ui/user/screens/cart_screen.dart';
import 'package:bitetimenew/ui/user/screens/isthara_screen.dart';
import 'package:bitetimenew/ui/user/screens/login_screen.dart';
import 'package:bitetimenew/ui/user/screens/onboard_screen.dart';
import 'package:bitetimenew/ui/user/sheets/navbar.dart';
import 'package:bitetimenew/userselection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_menu.dart';
import 'theme/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

late SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Required before async ops

  // ✅ Load .env file
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded: API_URL = ${dotenv.env['API_URL']}");
  } catch (e) {
    print("❌ Failed to load .env: $e");
  }

  try {
    prefs = await SharedPreferences.getInstance(); // ✅ Initialize SharedPreferences
    print("✅ SharedPreferences initialized successfully!");
  } catch (e) {
    print("❌ Error initializing SharedPreferences: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FoodMenu()),
        
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IstharaScreen(), // ✅ Entry screen
      theme: Provider.of<ThemeProvider>(context).themeData,

      routes: {
        '/login': (context) => const UserLoginScreen(),
        '/cart': (context) => const CartScreen()
      },
    );
  }
}
