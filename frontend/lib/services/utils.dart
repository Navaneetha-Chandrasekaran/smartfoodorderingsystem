// utils/get_full_image_url.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

String getFullImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return 'https://via.placeholder.com/150'; // Fallback
  }

  String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  if (baseUrl.endsWith('/api')) {
    baseUrl = baseUrl.replaceFirst('/api', '');
  }

  if (imagePath.startsWith('/')) {
    imagePath = imagePath.substring(1);
  }

  return '$baseUrl/uploads/$imagePath';
}
