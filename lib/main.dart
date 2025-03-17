import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Ensure it's imported
import 'package:bitetimenew/ui/screens/isthara/isthara.dart';
import 'package:bitetimenew/ui/sheets/navbar.dart';
import 'package:bitetimenew/theme/theme_provider.dart';
import 'package:bitetimenew/ui/sheets/food_menu.dart';
import 'ui/screens/onboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Ensures Flutter is ready before running

  try {
    final prefs = await SharedPreferences.getInstance(); // ✅ Initialize SharedPreferences
    print("✅ SharedPreferences initialized successfully!"); // Debugging log
  } catch (e) {
    print("❌ Error initializing SharedPreferences: $e"); // Log error if it fails
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
      home: CustomNavBar(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
