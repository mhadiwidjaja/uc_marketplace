import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'models/notification_model.dart';

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
        : DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: ucOrange,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: ucOrange,
                    tabs: const [
                      Tab(text: "Pesanan"),
                      Tab(text: "Notifikasi"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOrdersTab(context, uid),
                      _buildNotificationsTab(context, uid),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildOrdersTab(BuildContext context, String uid) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("orders").orderByChild("buyerId").equalTo(uid).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _buildEmptyState("Belum ada riwayat pesanan");
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
            String summary = data['productSummary']?.toString() ?? data['productName']?.toString() ?? "Pesanan";
            String total = data['totalHarga']?.toString() ?? data['price']?.toString() ?? "Rp 0";

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
    );
  }

  Widget _buildNotificationsTab(BuildContext context, String uid) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("notifications").orderByChild("userId").equalTo(uid).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _buildEmptyState("Belum ada notifikasi");
        }

        Map<dynamic, dynamic> notificationsMap = snapshot.data!.snapshot.value as Map;
        List<dynamic> notifList = notificationsMap.entries.toList();
        // Sort by timestamp descending
        notifList.sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifList.length,
          itemBuilder: (context, index) {
            var notifId = notifList[index].key;
            var data = notifList[index].value;
            
            final notification = NotificationModel.fromMap(data, notifId);

            return GestureDetector(
              onTap: () {
                FirebaseDatabase.instance.ref("notifications/$notifId").update({"isRead": true});
                if (notification.type == 'receive_confirmation') {
                  _showReceiveConfirmationDialog(context, notification);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: notification.isRead ? Colors.white : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  border: notification.isConfirmed 
                      ? Border.all(color: Colors.green, width: 1.5) 
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: notification.isConfirmed ? Colors.green[100] : Colors.orange[100], 
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notification.isConfirmed ? Icons.check_circle : Icons.notifications_outlined, 
                        color: notification.isConfirmed ? Colors.green : ucOrange,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            notification.message, 
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(notification.timestamp)
                            ),
                            style: TextStyle(color: Colors.grey[400], fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    if (notification.type == 'receive_confirmation' && !notification.isConfirmed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ucOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Konfirmasi",
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (notification.isConfirmed)
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReceiveConfirmationDialog(BuildContext context, NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Konfirmasi Penerimaan Barang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 30),
            const Text(
              "Apakah Anda sudah menerima barang berikut?",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // List of items
            ...notification.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text("x${item.quantity}", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: notification.isConfirmed ? Colors.grey : ucOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: notification.isConfirmed 
                        ? null 
                        : () => _confirmReceive(context, notification),
                    child: Text(
                      notification.isConfirmed ? "Sudah Dikonfirmasi" : "Konfirmasi Terima",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReceive(BuildContext context, NotificationModel notification) async {
    try {
      // Update notification as confirmed
      await FirebaseDatabase.instance.ref("notifications/${notification.id}").update({
        'isConfirmed': true,
      });

      // Update order receiveStatus to Complete and status to Completed
      await FirebaseDatabase.instance.ref("orders/${notification.orderId}").update({
        'receiveStatus': 'Complete',
        'receiveConfirmed': true,
        'status': 'Completed',
      });

      // Increase soldCount for each product in the order
      for (var item in notification.items) {
        if (item.productId.isEmpty) {
          debugPrint('Warning: Empty productId for item ${item.productName}');
          continue;
        }
        
        final productRef = FirebaseDatabase.instance.ref("products/${item.productId}");
        
        // First get the current value
        final snapshot = await productRef.get();
        if (snapshot.exists && snapshot.value != null) {
          final productData = Map<String, dynamic>.from(snapshot.value as Map);
          int currentSoldCount = productData['soldCount'] ?? 0;
          int newSoldCount = currentSoldCount + item.quantity;
          
          // Update with new value
          await productRef.update({'soldCount': newSoldCount});
          debugPrint('Updated soldCount for ${item.productId}: $currentSoldCount -> $newSoldCount');
        } else {
          debugPrint('Product not found: ${item.productId}');
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terima kasih! Penerimaan barang dikonfirmasi."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // MODAL DETAIL DENGAN PENGAMAN NULL
  void _showOrderDetail(BuildContext context, dynamic data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text("Detail Riwayat Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const Divider(height: 30),
            _detailRow("ID Pesanan", data['orderId']?.toString() ?? data['id']?.toString() ?? "-"),
            _detailRow("Status", data['status']?.toString() ?? "Pending"),
            _detailRow("Metode Bayar", data['paymentMethod']?.toString() ?? "-"),
            _detailRow("Alamat Ambil", data['pickupAddress']?.toString() ?? data['address']?.toString() ?? "UC Market"),
            _detailRow("Waktu", data['timestamp'] != null 
                ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(data['timestamp']))
                : "-"),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(data['totalHarga']?.toString() ?? data['price']?.toString() ?? "Rp 0", 
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

  Widget _buildEmptyState(String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
        Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    ),
  );
}