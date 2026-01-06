import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chat_room_page.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatelessWidget {
  final bool showBackButton;
  const ChatPage({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF39C12),
        title: const Text("Chat Box", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        // Tombol kembali otomatis
        leading: showBackButton ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ) : null,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: currentUser == null 
        ? const Center(child: Text("Silakan login"))
        : StreamBuilder(
            stream: FirebaseDatabase.instance.ref("chats").onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return _buildEmpty();

              Map<dynamic, dynamic> rooms = snapshot.data!.snapshot.value as Map;
              // Hanya ambil chat yang melibatkan saya
              var myRooms = rooms.entries.where((e) => e.key.toString().contains(currentUser.uid)).toList();

              if (myRooms.isEmpty) return _buildEmpty();

              return ListView.builder(
                itemCount: myRooms.length,
                itemBuilder: (context, index) {
                  var roomKey = myRooms[index].key.toString();
                  var roomData = myRooms[index].value['last_info'];
                  // Pengaman agar tidak error layar merah
                  if (roomData == null) return const SizedBox();

                  // Casting data dengan nilai aman agar tidak NULL
                  String senderId = roomData['senderId']?.toString() ?? "";
                  String senderName = roomData['senderName']?.toString() ?? "User";
                  String senderProfileUrl = roomData['senderProfileUrl']?.toString() ?? "";
                  String receiverId = roomData['receiverId']?.toString() ?? "";
                  String receiverName = roomData['receiverName']?.toString() ?? "User";
                  String receiverProfileUrl = roomData['receiverProfileUrl']?.toString() ?? "";
                  String lastMsg = roomData['last_msg']?.toString() ?? "";
                  int timestamp = roomData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;

                  // LOGIKA UTAMA: Menentukan Lawan Bicara
                  // Jika saya adalah pengirim terakhir, maka tampilkan nama penerima (Rina)
                  // Jika saya adalah penerima, tampilkan nama pengirimnya
                  bool isMeSender = senderId == currentUser.uid;
                  String otherName = isMeSender ? receiverName : senderName;
                  String otherId = isMeSender ? receiverId : senderId;
                  String otherProfileUrl = isMeSender ? receiverProfileUrl : senderProfileUrl;
                  
                  // Hitung Notifikasi (Khusus jika saya adalah penerima)
                  bool isReceiverMe = receiverId == currentUser.uid;
                  bool hasUnread = roomData['isRead'] == false && isReceiverMe;

                  // Build profile image widget
                  Widget profileWidget;
                  if (otherProfileUrl.isNotEmpty) {
                    if (otherProfileUrl.startsWith('data:')) {
                      // Base64 image
                      try {
                        profileWidget = CircleAvatar(
                          backgroundImage: MemoryImage(Uri.parse(otherProfileUrl).data!.contentAsBytes()),
                        );
                      } catch (e) {
                        profileWidget = CircleAvatar(
                          backgroundColor: const Color(0xFFF39C12).withOpacity(0.1),
                          child: Text(
                            otherName.isNotEmpty ? otherName[0].toUpperCase() : "?", 
                            style: const TextStyle(color: Color(0xFFF39C12), fontWeight: FontWeight.bold)
                          ),
                        );
                      }
                    } else {
                      // Network image
                      profileWidget = CircleAvatar(
                        backgroundImage: NetworkImage(otherProfileUrl),
                        onBackgroundImageError: (_, __) {},
                      );
                    }
                  } else {
                    profileWidget = CircleAvatar(
                      backgroundColor: const Color(0xFFF39C12).withOpacity(0.1),
                      child: Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : "?", 
                        style: const TextStyle(color: Color(0xFFF39C12), fontWeight: FontWeight.bold)
                      ),
                    );
                  }

                  return Card(
                    key: ValueKey(roomKey),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), 
                      side: BorderSide(color: Colors.grey.shade200)
                    ),
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => 
                        ChatRoomPage(receiverId: otherId, receiverName: otherName))),
                      leading: profileWidget,
                      title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp)), 
                            style: const TextStyle(fontSize: 10, color: Colors.grey)
                          ),
                          // Indikator Badge Merah jika ada pesan baru
                          if (hasUnread) 
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Text(
                                "!", 
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Text("Belum ada pesan"));
  }
}