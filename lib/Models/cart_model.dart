import 'product_model.dart';

class CartItemModel {
  final String productId;
  final String productName;
  final String price;
  int quantity;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
  });

  // Konversi ke Map untuk disimpan di Firebase
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  // Ambil dari Map Firebase
  factory CartItemModel.fromMap(Map<dynamic, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: map['price'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }
}