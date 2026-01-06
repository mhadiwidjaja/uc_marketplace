class OrderModel {
  final String id;
  final String sellerId;
  final String buyerId;
  final String productName;
  final String price;
  final String status; // Pending, Delivered, Cancelled
  final int timestamp;

  OrderModel({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    required this.productName,
    required this.price,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'buyerId': buyerId,
      'productName': productName,
      'price': price,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory OrderModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return OrderModel(
      id: id,
      sellerId: map['sellerId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      productName: map['productName'] ?? '',
      price: map['price'] ?? '',
      status: map['status'] ?? 'Pending',
      timestamp: map['timestamp'] ?? 0,
    );
  }
}