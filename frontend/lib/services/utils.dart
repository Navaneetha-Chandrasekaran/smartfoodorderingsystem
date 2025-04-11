import 'package:flutter_dotenv/flutter_dotenv.dart';


String getFullImageUrl(String imagePath) {
  String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  if (baseUrl.endsWith('/api')) {
    baseUrl = baseUrl.replaceFirst('/api', '');
  }

  return '$baseUrl/uploads/$imagePath';
}
