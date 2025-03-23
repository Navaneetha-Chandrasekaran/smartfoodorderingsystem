class Food {
  final String name;
  final String description;
  final String image;
  final double price;
  final FoodCategory category;
  int availableQuantity; // ✅ NEW: Available food count
  List<Addon> availableAddons;
  final bool isVeg;

  Food({
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.category,
    required this.availableQuantity, // ✅ Added
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
  final SpiceLevel spiceLevel;

  Addon({
    required this.name,
    SpiceLevel? spiceLevel,
  }) : spiceLevel = spiceLevel ?? SpiceLevel.none;
}
