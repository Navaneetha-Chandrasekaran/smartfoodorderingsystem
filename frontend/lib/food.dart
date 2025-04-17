import 'package:flutter/material.dart';

enum FoodCategory {
  breakfast,
  lunch,
  snacks,
  beverages,
}

class Food {
  final int id;
  final String name;
  final String description;
  final String image;
  final double price;
  final FoodCategory category;
  int availableQuantity;
  final bool isVeg;

  Food({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.category,
    required this.availableQuantity,
    required this.isVeg,
  });

  static FoodCategory _parseCategory(String? value) {
    final normalized = value?.toLowerCase().trim() ?? '';
    debugPrint('Parsing category: "$normalized"');
    return FoodCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == normalized,
      orElse: () => FoodCategory.breakfast,
    );
  }

  static bool _parseIsVeg(dynamic value) {
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return ['true', 'yes', '1', 'veg'].contains(normalized);
    }
    if (value is bool) return value;
    if (value is int) return value == 1;
    return true;
  }

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['food_id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      category: Food._parseCategory(json['category']),
      availableQuantity: int.tryParse(json['availability']?.toString() ?? '0') ?? 0,
      isVeg: Food._parseIsVeg(json['type']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image': image,
        'price': price,
        'category': category.name,
        'availableQuantity': availableQuantity,
        'isVeg': isVeg,
      };

  Food copyWith({
    int? id,
    String? name,
    String? description,
    String? image,
    double? price,
    FoodCategory? category,
    int? availableQuantity,
    bool? isVeg,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      category: category ?? this.category,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      isVeg: isVeg ?? this.isVeg,
    );
  }

  @override
  String toString() {
    return 'Food(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Food &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
