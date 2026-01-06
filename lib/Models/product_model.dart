class ProductModel {
  String? id;
  final String name;
  final String description;
  final String price;
  final String category;
  final String sellerId;
  final int stock;
  final String? imageUrl; // Baris ini wajib ada

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.sellerId,
    required this.stock,
    this.imageUrl, // Baris ini wajib ada
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
      imageUrl: map['imageUrl'], // Baris ini wajib ada
    );
  }
}