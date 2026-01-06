class ChatMessage {
  final String? id; // Berikan tanda tanya agar boleh kosong saat dikirim
  final String senderId;
  final String receiverId; // Tetap wajib
  final String message;
  final int timestamp;
  final bool isRead;

  ChatMessage({
    this.id, // Hapus 'required' untuk ID
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      isRead: map['isRead'] ?? false,
    );
  }
}