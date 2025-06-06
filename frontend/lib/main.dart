import 'package:bitetimenew/ui/canteen/screens/login_screen.dart';
import 'package:bitetimenew/ui/canteen/screens/profile_screen.dart';
import 'package:bitetimenew/ui/canteen/sheets/navbar.dart';
import 'package:bitetimenew/ui/user/screens/cart_screen.dart';
import 'package:bitetimenew/ui/user/screens/isthara_screen.dart';
import 'package:bitetimenew/ui/user/screens/login_screen.dart';
import 'package:bitetimenew/ui/user/screens/onboard_screen.dart';
import 'package:bitetimenew/ui/user/screens/order_history_screen.dart';
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
import 'services/auth_service.dart' as auth;
import 'dart:async';
import 'dart:ui'; // Import for PlatformDispatcher
import 'package:flutter/foundation.dart'; // Import for BindingBase

late SharedPreferences prefs;
late OrderService orderService;

// Global key for error handling
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Error handler to show errors via snackbar
void showErrorMessage(String message) {
  navigatorKey.currentState?.overlay?.context != null
      ? ScaffoldMessenger.of(navigatorKey.currentState!.overlay!.context)
          .showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ))
      : print("Unable to show error: $message");
}

Future<void> main() async {
  // Set this flag to make zone errors fatal
  BindingBase.debugZoneErrorsAreFatal = true;

  // Move this initialization inside the same zone where runApp will be called
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load(fileName: ".env");
      if (dotenv.env['API_BASE_URL'] == null) {
        throw Exception('API_BASE_URL not found in .env file');
      }
      print("✅ .env loaded successfully");
      print("📍 API_URL = ${dotenv.env['API_URL']}");
      print("🌐 API_BASE_URL = ${dotenv.env['API_BASE_URL']}");
    } catch (e) {
      print("❌ Failed to load .env: $e");
      // You might want to show an error dialog here
      return;
    }

    try {
      prefs = await SharedPreferences.getInstance();
      print("✅ SharedPreferences initialized successfully!");
    } catch (e) {
      print("❌ Error initializing SharedPreferences: $e");
      return;
    }

    // Initialize OrderService
    orderService = OrderService();

    // Set error handler for Flutter errors and unhandled exceptions
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print("💥 Flutter Error: ${details.exception}");
      showErrorMessage("App Error: ${details.exception}");
    };

    // Handle unhandled async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      print("💥 Unhandled Platform Error: $error");
      print(stack);
      showErrorMessage("Unhandled Error: $error");
      return true;
    };
    
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
  }, (error, stackTrace) {
    print("💥 Unhandled Error in runZonedGuarded: $error");
    print(stackTrace);
    showErrorMessage("Unhandled Error: $error");
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _userRole;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final isAuthenticated = await auth.AuthService.isAuthenticated();
      
      if (isAuthenticated) {
        // Validate token
        final isTokenValid = await AuthService.validateToken();
        
        if (!isTokenValid) {
          print("⚠️ Invalid or expired token");
          await auth.AuthService.clearAuth(); // Clear invalid token
          _initialScreen = const UserSelectionScreen();
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
          return;
        }
        
        // Get user role to determine which screen to show
        _userRole = await auth.AuthService.getCurrentRole();
        print("🔑 User authenticated with role: $_userRole");
        
        // Set initial screen based on role
        if (_userRole == 'student') {
          _initialScreen = const CustomNavBar();
        } else if (_userRole == 'canteen_staff') {
          _initialScreen = const CanteenNavBar();
        } else {
          _initialScreen = const UserSelectionScreen();
        }
      } else {
        _initialScreen = const UserSelectionScreen();
      }
    } catch (e) {
      print("❌ Error checking login status: $e");
      _initialScreen = const UserSelectionScreen();
      // Show error in next frame when context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorMessage("Error checking login status: $e");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoggedIn = _userRole != null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure there's always a valid initial screen to avoid null errors
    if (_initialScreen == null) {
      _initialScreen = const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Loading app..."),
            ],
          ),
        ),
      );
    }
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: UserSelectionScreen(),
      // _isLoading 
      //     ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      //     : _initialScreen,
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
        '/order_history': (context) => const OrderHistoryScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling issues
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: child,
                // Catch errors and display error message
                resizeToAvoidBottomInset: true,
              );
            },
          ),
        );
      },
    );
  }
}
