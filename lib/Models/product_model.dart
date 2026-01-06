class ProductModel {
  String? id;
  final String name;
  final String description;
  final String price;
  final String category;
  final String sellerId;
  final int stock;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final int targetSales;
  final int? targetDate; // Timestamp for goal deadline

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.sellerId,
    required this.stock,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.soldCount = 0,
    this.targetSales = 100,
    this.targetDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'sellerId': sellerId,
      'stock': stock,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'soldCount': soldCount,
      'targetSales': targetSales,
      'targetDate': targetDate,
    };
  }

  factory ProductModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toString() ?? '0',
      category: map['category'] ?? '',
      sellerId: map['sellerId'] ?? '',
      stock: (map['stock'] is int) ? map['stock'] : int.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      imageUrl: map['imageUrl'],
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      reviewCount: (map['reviewCount'] is int) ? map['reviewCount'] : 0,
      soldCount: (map['soldCount'] is int) ? map['soldCount'] : 0,
      targetSales: (map['targetSales'] is int) ? map['targetSales'] : 100,
      targetDate: map['targetDate'] is int ? map['targetDate'] : null,
    );
  }
}