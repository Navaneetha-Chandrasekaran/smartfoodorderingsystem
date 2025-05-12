// utils/get_full_image_url.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

String getFullImageUrl(String? imagePath) {
  // If no image path is provided, return a proper network URL for placeholder
  if (imagePath == null || imagePath.isEmpty) {
    print("🖼️ Using placeholder for empty image path");
    return 'https://via.placeholder.com/150';
  }

  // If the image path is already a full URL, return it as is
  if (imagePath.startsWith('http')) {
    print("🖼️ Using direct image URL: $imagePath");
    return imagePath;
  }

  // Get the base URL from environment variables
  String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  
  // Remove /api suffix if present
  if (baseUrl.endsWith('/api')) {
    baseUrl = baseUrl.replaceFirst('/api', '');
  }
  
  // Remove any leading slashes from the image path
  String cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
  
  // Construct and return the full URL
  final fullUrl = '$baseUrl/uploads/$cleanPath';
  print("🖼️ Constructed image URL: $fullUrl from path: $imagePath");
  return fullUrl;
}
