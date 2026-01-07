import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/chat_model.dart';
import 'models/product_model.dart';
import 'package:intl/intl.dart';

class ChatRoomPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatRoomPage({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _messageController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  final Color ucOrange = const Color(0xFFF39C12);
  
  String _myName = "User";
  String? _myProfileUrl;
  String? _receiverProfileUrl;

  String getChatRoomId() {
    List<String> ids = [_currentUser!.uid, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadReceiverData();
    _markAsRead();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    final snapshot = await FirebaseDatabase.instance.ref("users/${_currentUser.uid}").get();
    if (snapshot.exists) {
      final userData = snapshot.value as Map;
      setState(() {
        _myName = userData['username'] ?? "User";
        _myProfileUrl = userData['profileImageUrl'];
      });
    }
  }

  Future<void> _loadReceiverData() async {
    final snapshot = await FirebaseDatabase.instance.ref("users/${widget.receiverId}").get();
    if (snapshot.exists) {
      final userData = snapshot.value as Map;
      setState(() {
        _receiverProfileUrl = userData['profileImageUrl'];
      });
    }
  }

  void _markAsRead() {
    FirebaseDatabase.instance.ref("chats/${getChatRoomId()}/last_info").update({"isRead": true});
  }

  void _sendMessage({String? customMessage}) async {
    String text = customMessage ?? _messageController.text.trim();
    if (text.isEmpty) return;

    final chatRoomId = getChatRoomId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final newMessage = ChatMessage(
      senderId: _currentUser!.uid,
      receiverId: widget.receiverId,
      message: text,
      timestamp: timestamp,
    );

    DatabaseReference ref = FirebaseDatabase.instance.ref("chats/$chatRoomId");
    await ref.child("messages").push().set(newMessage.toMap());
    await ref.child("last_info").set({
      "last_msg": text.startsWith('TANYA_PRODUK|') ? "[Produk]" : text,
      "timestamp": timestamp,
      "senderId": _currentUser.uid,
      "senderName": _myName,
      "senderProfileUrl": _myProfileUrl,
      "receiverId": widget.receiverId,
      "receiverName": widget.receiverName,
      "receiverProfileUrl": _receiverProfileUrl,
      "isRead": false,
    });

    _messageController.clear();
  }

  // MODIFIKASI: Menambahkan Filter Stok (p.stock > 0)
  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.only(bottom: 20)),
              const Text("Pilih Produk untuk Ditanyakan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseDatabase.instance.ref("products").orderByChild("sellerId").equalTo(widget.receiverId).onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: Text("Penjual belum memiliki produk aktif."));
                    }
                    Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
                    
                    // FILTER: Hanya ambil produk yang STOKNYA MASIH ADA
                    List<ProductModel> products = data.entries
                        .map((e) => ProductModel.fromMap(e.value, e.key))
                        .where((p) => p.stock > 0) 
                        .toList();

                    if (products.isEmpty) {
                      return const Center(child: Text("Semua produk penjual sedang habis stok."));
                    }

                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(p.imageUrl ?? "", width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image)),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text("Rp ${p.price}", style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold)),
                            trailing: Icon(Icons.send_rounded, color: ucOrange),
                            onTap: () {
                              _sendMessage(customMessage: "TANYA_PRODUK|${p.name}|${p.price}|${p.imageUrl}");
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 2,
        titleSpacing: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: _receiverProfileUrl != null ? NetworkImage(_receiverProfileUrl!) : null,
              child: _receiverProfileUrl == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text("Online", style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref("chats/${getChatRoomId()}/messages").orderByChild("timestamp").onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("Mulai percakapan..."));
                Map<dynamic, dynamic> msgs = snapshot.data!.snapshot.value as Map;
                List<ChatMessage> list = msgs.entries.map((e) => ChatMessage.fromMap(e.value, e.key.toString())).toList();
                list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    bool isMe = list[index].senderId == _currentUser!.uid;
                    return _buildModernBubble(list[index], isMe);
                  },
                );
              },
            ),
          ),
          _buildEnhancedInputBox(),
        ],
      ),
    );
  }

  Widget _buildModernBubble(ChatMessage msg, bool isMe) {
    bool isProductQuery = msg.message.startsWith("TANYA_PRODUK|");
    String time = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(msg.timestamp));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isProductQuery)
            _buildProductCardBubble(msg.message, isMe)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(vertical: 4),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isMe ? ucOrange : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
              ),
              child: Text(msg.message, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProductCardBubble(String data, bool isMe) {
    List<String> parts = data.split('|');
    String name = parts[1];
    String price = parts[2];
    String img = parts[3];

    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(img, height: 130, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, size: 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text("Rp $price", style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    SizedBox(width: 5),
                    Text("Tanya ketersediaan stok", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEnhancedInputBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _showProductPicker,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: ucOrange.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.add_shopping_cart_rounded, color: ucOrange, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: "Tulis pesan...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: ucOrange,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}