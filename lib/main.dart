import 'package:bitetimenew/ui/screens/isthara/isthara.dart';
import 'package:bitetimenew/ui/sheets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitetimenew/theme/theme_provider.dart';
import 'package:bitetimenew/ui/sheets/food_menu.dart';

import 'ui/screens/onboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FoodMenu()), // ✅ Ensuring FoodMenu is available
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
