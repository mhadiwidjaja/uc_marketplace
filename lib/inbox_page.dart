import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'models/notification_model.dart';
import 'models/order_model.dart';
import 'order_detail_page.dart';

class InboxPage extends StatefulWidget {
  final bool showBackButton;
  const InboxPage({super.key, this.showBackButton = true});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final Color ucOrange = const Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        centerTitle: true,
        title: const Text("Inbox Pesanan",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: widget.showBackButton,
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
                        // Menggunakan widget terpisah agar data tidak hilang saat switch tab
                        OrderListView(uid: uid, ucOrange: ucOrange),
                        NotificationListView(uid: uid, ucOrange: ucOrange),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// --- WIDGET LIST PESANAN DENGAN KEEP ALIVE ---
class OrderListView extends StatefulWidget {
  final String uid;
  final Color ucOrange;
  const OrderListView({super.key, required this.uid, required this.ucOrange});

  @override
  State<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends State<OrderListView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Menjaga state data tetap ada

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("orders").orderByChild("buyerId").equalTo(widget.uid).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return _buildEmptyState("Belum ada riwayat pesanan");

        Map<dynamic, dynamic> ordersMap = snapshot.data!.snapshot.value as Map;
        List<dynamic> orderList = ordersMap.entries.toList();
        orderList.sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orderList.length,
          itemBuilder: (context, index) {
            var orderId = orderList[index].key;
            var data = orderList[index].value;
            String status = data['status']?.toString() ?? "Pending";
            String summary = data['productSummary'] ?? data['productName'] ?? "Pesanan";
            String total = data['totalHarga'] ?? data['price'] ?? "Rp 0";

            return GestureDetector(
              onTap: () {
                FirebaseDatabase.instance.ref("orders/$orderId").update({"isRead": true});
                _showOrderDetail(context, data, widget.ucOrange);
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
                      child: Icon(Icons.shopping_bag_outlined, color: widget.ucOrange),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(summary, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(total, style: TextStyle(color: widget.ucOrange, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == "Delivered" || status == "Completed") color = Colors.green;
    if (status == "Cancelled") color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

// --- WIDGET LIST NOTIFIKASI DENGAN KEEP ALIVE ---
class NotificationListView extends StatefulWidget {
  final String uid;
  final Color ucOrange;
  const NotificationListView({super.key, required this.uid, required this.ucOrange});

  @override
  State<NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("notifications").orderByChild("userId").equalTo(widget.uid).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return _buildEmptyState("Belum ada notifikasi");

        Map<dynamic, dynamic> notificationsMap = snapshot.data!.snapshot.value as Map;
        List<dynamic> notifList = notificationsMap.entries.toList();
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
                
                // LOGIKA WALLET & KONFIRMASI TERIMA
                if (notification.type == 'receive_confirmation' && !notification.isConfirmed) {
                  _showReceiveConfirmationDialog(context, notification, widget.ucOrange);
                } else if (notification.type == 'new_order' || notification.type == 'wallet_update') {
                  _navigateToOrderDetail(context, notification.orderId);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: notification.isRead ? Colors.white : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: notification.isConfirmed || notification.type == 'wallet_update' ? Colors.green[100] : Colors.orange[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notification.type == 'wallet_update' ? Icons.account_balance_wallet : (notification.isConfirmed ? Icons.check_circle : Icons.notifications_outlined),
                        color: notification.isConfirmed || notification.type == 'wallet_update' ? Colors.green : widget.ucOrange,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(notification.message, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2),
                          Text(
                            DateFormat('dd MMM, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(notification.timestamp)),
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
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
}

// --- HELPER FUNCTIONS ---

Widget _buildEmptyState(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
        Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    ),
  );
}

void _showOrderDetail(BuildContext context, dynamic data, Color ucOrange) {
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
          _detailRow("ID Pesanan", data['orderId']?.toString() ?? "-"),
          _detailRow("Status", data['status']?.toString() ?? "Pending"),
          _detailRow("Metode Bayar", data['paymentMethod']?.toString() ?? "-"),
          const Divider(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(data['totalHarga']?.toString() ?? "Rp 0", style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold, fontSize: 16)),
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
        children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );

Future<void> _navigateToOrderDetail(BuildContext context, String orderId) async {
  if (orderId.isEmpty) return;
  final snapshot = await FirebaseDatabase.instance.ref("orders/$orderId").get();
  if (snapshot.exists) {
    final order = OrderModel.fromMap(snapshot.value as Map, orderId);
    if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailPage(order: order)));
  }
}

// --- LOGIKA WALLET & KONFIRMASI (FIXED) ---

void _showReceiveConfirmationDialog(BuildContext context, NotificationModel notification, Color ucOrange) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Konfirmasi Penerimaan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          const Text("Apakah Anda sudah menerima barang ini? Uang akan otomatis diteruskan ke wallet penjual.", textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ucOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => _confirmAndTransferWallet(context, notification),
              child: const Text("Konfirmasi Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

Future<void> _confirmAndTransferWallet(BuildContext context, NotificationModel notification) async {
  try {
    final orderRef = FirebaseDatabase.instance.ref("orders/${notification.orderId}");
    final orderSnapshot = await orderRef.get();
    
    if (!orderSnapshot.exists) return;
    final orderData = orderSnapshot.value as Map;
    final String sellerId = orderData['sellerId'];
    // Ambil nama produk untuk judul riwayat
    final String productName = orderData['productName'] ?? "Produk";
    
    final String priceStr = orderData['totalHarga'] ?? orderData['price'] ?? "0";
    final int amount = int.parse(priceStr.replaceAll(RegExp(r'[^0-9]'), ''));

    // 1. Update status Order & Notifikasi
    await orderRef.update({'receiveStatus': 'Complete', 'status': 'Completed'});
    await FirebaseDatabase.instance.ref("notifications/${notification.id}").update({
      'isConfirmed': true,
      'isRead': true,
    });

    // 2. Tambahkan saldo ke Wallet Penjual (Seller)
    final sellerWalletRef = FirebaseDatabase.instance.ref("users/$sellerId/walletBalance");
    await sellerWalletRef.runTransaction((Object? currentBalance) {
      int balance = (currentBalance as int?) ?? 0;
      return Transaction.success(balance + amount);
    });

    // 3. CATAT KE RIWAYAT TRANSAKSI (Node Baru agar UI Wallet tidak kosong)
    final historyRef = FirebaseDatabase.instance.ref("wallet_history/$sellerId").push();
    await historyRef.set({
      'type': 'income',
      'title': 'Penjualan $productName',
      'amount': amount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'orderId': notification.orderId,
    });

    // 4. Kirim notifikasi saldo masuk ke penjual
    final sellerNotifRef = FirebaseDatabase.instance.ref("notifications").push();
    await sellerNotifRef.set({
      'userId': sellerId,
      'orderId': notification.orderId,
      'type': 'wallet_update',
      'title': 'Saldo Wallet Bertambah!',
      'message': 'Pesanan selesai. Rp ${NumberFormat("#,###", "id_ID").format(amount)} masuk ke wallet Anda.',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
    });

    if (context.mounted) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil! Dana telah diteruskan ke penjual."), backgroundColor: Colors.green),
      );
    }
  } catch (e) {
    debugPrint("Error wallet transfer: $e");
  }
}