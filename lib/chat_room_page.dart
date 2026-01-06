import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/chat_model.dart';
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

  String getChatRoomId() {
    List<String> ids = [_currentUser!.uid, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  @override
  void initState() {
    super.initState();
    _markAsRead(); // Tandai pesan sudah dibaca saat dibuka
  }

  void _markAsRead() {
    FirebaseDatabase.instance.ref("chats/${getChatRoomId()}/last_info").update({"isRead": true});
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatRoomId = getChatRoomId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Ambil Nama Pengirim dari Profile
    String myName = _currentUser?.displayName ?? "User";

    final newMessage = ChatMessage(
      senderId: _currentUser!.uid,
      receiverId: widget.receiverId,
      message: _messageController.text.trim(),
      timestamp: timestamp,
    );

    DatabaseReference ref = FirebaseDatabase.instance.ref("chats/$chatRoomId");
    await ref.child("messages").push().set(newMessage.toMap());
    await ref.child("last_info").set({
      "last_msg": newMessage.message,
      "timestamp": timestamp,
      "senderId": _currentUser!.uid,
      "senderName": myName,
      "receiverId": widget.receiverId,
      "receiverName": widget.receiverName,
      "isRead": false,
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF39C12),
        elevation: 1,
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref("chats/${getChatRoomId()}/messages").orderByChild("timestamp").onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Mulai percakapan..."));
                }
                Map<dynamic, dynamic> msgs = snapshot.data!.snapshot.value as Map;
                List<ChatMessage> list = [];
                msgs.forEach((key, val) => list.add(ChatMessage.fromMap(val, key.toString())));
                list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    bool isMe = list[index].senderId == _currentUser!.uid;
                    return _buildBubble(list[index], isMe);
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe) {
    String time = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(msg.timestamp));
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFF39C12) : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isMe ? 15 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 15),
              ),
            ),
            child: Text(msg.message, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 15)),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Tulis pesan...",
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(backgroundColor: Color(0xFFF39C12), child: Icon(Icons.send, color: Colors.white, size: 20)),
          ),
        ],
      ),
    );
  }
}