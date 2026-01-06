class CartItemModel {
  final String productId;
  final String productName;
  final String price;
  final int quantity;
  final String sellerId; // Field yang menyebabkan error

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.sellerId, // Tambahkan di constructor
  });

  // Konversi ke Map untuk disimpan di Firebase
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
    };
  }

  // Ambil data dari Firebase ke Object Model
  factory CartItemModel.fromMap(Map<dynamic, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: map['price'] ?? '',
      quantity: map['quantity'] ?? 0,
      sellerId: map['sellerId'] ?? '', // Ambil dari database
    );
  }
}