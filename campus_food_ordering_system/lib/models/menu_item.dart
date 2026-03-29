class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isVeg;
  final bool isAvailable;
  final double rating;
  final int ratingCount;
  final List<String> tags;
  final int prepTimeMinutes;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isVeg = true,
    this.isAvailable = true,
    this.rating = 4.5,
    this.ratingCount = 0,
    this.tags = const [],
    this.prepTimeMinutes = 15,
  });
}
