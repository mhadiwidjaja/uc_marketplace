class ProductModel {
  String? id;
  final String name;
  final String description;
  final String price;
  final String category;
  final String sellerId; // Field untuk menyimpan ID pengguna
  final int stock;

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.sellerId,
    required this.stock,
  });

  // Konversi ke Map untuk Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'sellerId': sellerId,
      'stock': stock,
    };
  }

  // Ambil dari Map Firebase
  factory ProductModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] ?? '',
      category: map['category'] ?? '',
      sellerId: map['sellerId'] ?? '',
      stock: map['stock'] ?? 0,
    );
  }
}