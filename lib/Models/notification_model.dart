class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'receive_confirmation', 'order_update', etc.
  final String orderId;
  final String title;
  final String message;
  final int timestamp;
  final bool isRead;
  final bool isConfirmed; // For receive confirmation
  final List<NotificationItem> items;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.orderId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.isConfirmed = false,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'orderId': orderId,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'isConfirmed': isConfirmed,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  factory NotificationModel.fromMap(Map<dynamic, dynamic> map, String id) {
    List<NotificationItem> itemsList = [];
    if (map['items'] != null) {
      if (map['items'] is List) {
        itemsList = (map['items'] as List)
            .map((e) => NotificationItem.fromMap(e as Map<dynamic, dynamic>))
            .toList();
      } else if (map['items'] is Map) {
        (map['items'] as Map).forEach((key, value) {
          itemsList.add(NotificationItem.fromMap(value as Map<dynamic, dynamic>));
        });
      }
    }

    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      orderId: map['orderId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      isRead: map['isRead'] ?? false,
      isConfirmed: map['isConfirmed'] ?? false,
      items: itemsList,
    );
  }
}

class NotificationItem {
  final String productId;
  final String productName;
  final int quantity;

  NotificationItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
    };
  }

  factory NotificationItem.fromMap(Map<dynamic, dynamic> map) {
    return NotificationItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] is int ? map['quantity'] : int.tryParse(map['quantity'].toString()) ?? 0,
    );
  }
}
