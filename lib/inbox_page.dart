import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class InboxPage extends StatelessWidget {
  final bool showBackButton;
  const InboxPage({super.key, this.showBackButton = true});

  final Color ucOrange = const Color(0xFFF39C12);

  // Helper untuk warna status
  Color _getStatusColor(String? status) {
    if (status == "Delivered") return Colors.green;
    if (status == "Cancelled") return Colors.red;
    return Colors.orange; // Default Pending
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        centerTitle: true,
        title: const Text("Inbox Pesanan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: showBackButton,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: uid == null 
        ? const Center(child: Text("Silakan login"))
        : StreamBuilder(
            stream: FirebaseDatabase.instance.ref("orders").orderByChild("buyerId").equalTo(uid).onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return _buildEmptyState();
              }

              Map<dynamic, dynamic> ordersMap = snapshot.data!.snapshot.value as Map;
              List<dynamic> orderList = ordersMap.entries.toList();
              // Urutkan berdasarkan waktu terbaru
              orderList.sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderList.length,
                itemBuilder: (context, index) {
                  var orderId = orderList[index].key;
                  var data = orderList[index].value;

                  // Ambil data dengan Null-Safety
                  String status = data['status']?.toString() ?? "Pending";
                  String summary = data['productSummary']?.toString() ?? "Pesanan";
                  String total = data['totalHarga']?.toString() ?? "Rp 0";

                  return GestureDetector(
                    onTap: () {
                      // Set isRead jadi true agar badge hilang
                      FirebaseDatabase.instance.ref("orders/$orderId").update({"isRead": true});
                      _showOrderDetail(context, data);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                            child: Icon(Icons.shopping_bag_outlined, color: ucOrange),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(summary, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(total, style: TextStyle(color: ucOrange, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
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

  // MODAL DETAIL DENGAN PENGAMAN NULL
  void _showOrderDetail(BuildContext context, dynamic data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text("Detail Riwayat Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const Divider(height: 30),
            _detailRow("ID Pesanan", data['orderId']?.toString() ?? "-"),
            _detailRow("Status", data['status']?.toString() ?? "Pending"),
            _detailRow("Metode Bayar", data['paymentMethod']?.toString() ?? "-"),
            _detailRow("Alamat Ambil", data['address']?.toString() ?? "UC Market"),
            _detailRow("Waktu", data['timestamp'] != null 
                ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(data['timestamp']))
                : "-"),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(data['totalHarga']?.toString() ?? "Rp 0", 
                  style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)), 
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
        const Text("Belum ada riwayat pesanan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    ),
  );
}