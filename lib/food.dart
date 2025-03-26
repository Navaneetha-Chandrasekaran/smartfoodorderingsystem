import 'dart:convert';

enum FoodCategory {
  breakfast,
  lunch,
  snacks,
  beverages,
}

enum SpiceLevel { none, medium, full }

class Addon {
  final String name;
  final SpiceLevel spiceLevel;

  Addon({
    required this.name,
    SpiceLevel? spiceLevel,
  }) : spiceLevel = spiceLevel ?? SpiceLevel.none;

  // Convert a JSON map into an Addon object
  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      name: json['name'],
      spiceLevel: SpiceLevel.values.firstWhere(
          (e) => e.toString().split('.').last == json['spiceLevel'],
          orElse: () => SpiceLevel.none),  // Default to SpiceLevel.none if not found
    );
  }

  // Convert Addon object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'spiceLevel': spiceLevel.toString().split('.').last,
    };
  }
}

class Food {
  final String name;
  final String description;
  final String image;
  final double price;
  final FoodCategory category;
  int availableQuantity; // Available food count
  List<Addon> availableAddons;
  final bool isVeg;

  Food({
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.category,
    required this.availableQuantity,
    required this.availableAddons,
    required this.isVeg,
  });

  // Deserialize JSON to Food object
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['name'],
      description: json['description'],
      image: json['image'],
      price: json['price'].toDouble(),
      category: FoodCategory.values.firstWhere(
          (e) => e.toString().split('.').last == json['category'],
          orElse: () => FoodCategory.breakfast), // Default to breakfast if category is missing
      availableQuantity: json['availableQuantity'],
      availableAddons: (json['availableAddons'] as List)
          .map((addonJson) => Addon.fromJson(addonJson))
          .toList(),
      isVeg: json['isVeg'],
    );
  }

  // Convert Food object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'price': price,
      'category': category.toString().split('.').last,
      'availableQuantity': availableQuantity,
      'availableAddons': availableAddons.map((addon) => addon.toJson()).toList(),
      'isVeg': isVeg,
    };
  }
}
