import 'package:bitetimenew/ui/canteen/screens/profile_screen.dart';
import 'package:bitetimenew/ui/canteen/sheets/navbar.dart';
import 'package:bitetimenew/ui/user/screens/onboard_screen.dart';
import 'package:bitetimenew/ui/user/sheets/navbar.dart';
import 'package:bitetimenew/userselection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'food_menu.dart';
import 'theme/theme_provider.dart';
late SharedPreferences prefs;
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Ensures Flutter is ready before running

  try {
    prefs = await SharedPreferences.getInstance(); // ✅ Initialize SharedPreferences
    print("✅ SharedPreferences initialized successfully!"); // Debugging log
  } catch (e) {
    print("❌ Error initializing SharedPreferences: $e"); // Log error if it fails
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FoodMenu()),
        // ChangeNotifierProvider(create: (context) => TimelineModel(), child: MyApp())
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
      home: CustomNavBar(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
