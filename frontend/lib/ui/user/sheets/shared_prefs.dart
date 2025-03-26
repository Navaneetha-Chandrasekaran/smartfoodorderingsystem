import 'package:shared_preferences/shared_preferences.dart';

Future<void> savePaymentPreference(String method) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paymentMethod', method);
    print("✅ Payment preference saved: $method"); // Debugging log
  } catch (e) {
    print("❌ Error saving payment preference: $e"); // Logs error if saving fails
  }
}

Future<String> loadPaymentPreference() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final paymentMethod = prefs.getString('paymentMethod') ?? "GPay";
    print("✅ Loaded payment preference: $paymentMethod"); // Debugging log
    return paymentMethod;
  } catch (e) {
    print("❌ Error loading payment preference: $e"); // Logs error if loading fails
    return "GPay"; // Return default value in case of an error
  }
}
