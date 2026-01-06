class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final int price;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItem.fromMap(Map<dynamic, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] is int ? map['quantity'] : int.tryParse(map['quantity'].toString()) ?? 0,
      price: map['price'] is int ? map['price'] : int.tryParse(map['price'].toString()) ?? 0,
      imageUrl: map['imageUrl'],
    );
  }
}

class OrderModel {
  final String id;
  final String sellerId;
  final String buyerId;
  final String productName;
  final String price;
  final String status; // Pending, Delivered, Cancelled
  final String receiveStatus; // Pending, Complete, Canceled
  final int timestamp;
  final List<OrderItem> items;
  final String? pickupAddress;
  final String? buyerName;
  final String? buyerPhone;
  final String? paymentMethod;

  OrderModel({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    required this.productName,
    required this.price,
    required this.status,
    this.receiveStatus = 'Pending',
    required this.timestamp,
    required this.items,
    this.pickupAddress,
    this.buyerName,
    this.buyerPhone,
    this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'buyerId': buyerId,
      'productName': productName,
      'price': price,
      'status': status,
      'receiveStatus': receiveStatus,
      'timestamp': timestamp,
      'items': items.map((e) => e.toMap()).toList(),
      'pickupAddress': pickupAddress,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'paymentMethod': paymentMethod,
    };
  }

  factory OrderModel.fromMap(Map<dynamic, dynamic> map, String id) {
    List<OrderItem> itemsList = [];
    if (map['items'] != null) {
      if (map['items'] is List) {
        itemsList = (map['items'] as List)
            .map((e) => OrderItem.fromMap(e as Map<dynamic, dynamic>))
            .toList();
      } else if (map['items'] is Map) {
         (map['items'] as Map).forEach((key, value) {
            itemsList.add(OrderItem.fromMap(value as Map<dynamic, dynamic>));
         });
      }
    }

    return OrderModel(
      id: id,
      sellerId: map['sellerId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      productName: map['productName'] ?? map['productSummary'] ?? '',
      price: map['price'] ?? map['totalHarga'] ?? '',
      status: map['status'] ?? 'Pending',
      receiveStatus: map['receiveStatus'] ?? 'Pending',
      timestamp: map['timestamp'] ?? 0,
      items: itemsList,
      pickupAddress: map['pickupAddress'],
      buyerName: map['buyerName'],
      buyerPhone: map['buyerPhone'],
      paymentMethod: map['paymentMethod'],
    );
  }
}