class Food {
  final String name;
  final String description;
  final String image;
  final double price;
  final FoodCategory category;
  List<Addon> availableAddons;
  final bool isVeg;

  Food({
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.category,
    required this.availableAddons,
    required this.isVeg
  });
}

enum FoodCategory {
  breakfast,
  lunch,
  snacks,
  beverages,
}

enum SpiceLevel { none, medium, full }

class Addon {
  final String name;
  final SpiceLevel spiceLevel; // ✅ Ensure this is never null

  Addon({
    required this.name,
    SpiceLevel? spiceLevel, // Allow null as input
  }) : spiceLevel = spiceLevel ?? SpiceLevel.none; // ✅ Default to 'none' if null
}
