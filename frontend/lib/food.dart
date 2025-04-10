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

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      name: json['name'] ?? 'Unnamed Addon',
      spiceLevel: SpiceLevel.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (json['spiceLevel']?.toLowerCase() ?? ''),
        orElse: () => SpiceLevel.none,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'spiceLevel': spiceLevel.toString().split('.').last,
      };
}

class Food {
  final String name;
  final String description;
  final String image;
  final double price;
  final FoodCategory category;
  int availableQuantity;
  List<Addon> availableAddons;
  final bool isVeg;
  final String type; // Newly added for display/editing

  Food({
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.category,
    required this.availableQuantity,
    required this.availableAddons,
    required this.isVeg,
    required this.type,
  });

  static FoodCategory _parseCategory(String? value) {
    final normalized = value?.toLowerCase().trim() ?? '';
    return FoodCategory.values.firstWhere(
      (c) => c.name == normalized,
      orElse: () => FoodCategory.breakfast,
    );
  }

  static bool _parseIsVeg(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' ||
          normalized == 'yes' ||
          normalized == '1' ||
          normalized == 'veg';
    }
    if (value is int) return value == 1;
    return false; // safer fallback
  }

  factory Food.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type']?.toString().toLowerCase().trim() ?? 'veg';
    return Food(
      name: json['name'] ?? 'Unnamed',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      category: _parseCategory(json['category']),
      availableQuantity: int.tryParse(json['availability']?.toString() ?? '0') ?? 0,
      availableAddons: (json['availableAddons'] as List<dynamic>? ?? [])
          .map((addon) => Addon.fromJson(addon))
          .toList(),
      isVeg: _parseIsVeg(typeValue),
      type: typeValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'image': image,
        'price': price,
        'category': category.name,
        'availableQuantity': availableQuantity,
        'availableAddons': availableAddons.map((a) => a.toJson()).toList(),
        'isVeg': isVeg,
        'type': type,
      };
}
