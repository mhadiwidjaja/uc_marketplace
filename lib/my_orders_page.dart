import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'models/order_model.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  final Color ucOrange = const Color(0xFFF39C12);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatRupiah(dynamic price) {
    try {
      int value;
      if (price is int) {
        value = price;
      } else {
        value = int.parse(price.toString().replaceAll(RegExp(r'[^0-9]'), ''));
      }
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
    } catch (e) {
      return "Rp $price";
    }
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
        title: const Text(
          "My Orders",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? const Center(child: Text("Silakan login terlebih dahulu"))
          : StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref("orders")
                  .orderByChild("buyerId")
                  .equalTo(uid)
                  .onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return _buildEmptyState();
                }

                Map<dynamic, dynamic> ordersMap = snapshot.data!.snapshot.value as Map;
                List<OrderModel> orderList = [];

                ordersMap.forEach((key, value) {
                  orderList.add(OrderModel.fromMap(value, key));
                });

                // Sort by timestamp descending (newest first)
                orderList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orderList.length,
                  itemBuilder: (context, index) {
                    final order = orderList[index];
                    return _buildOrderCard(context, order);
                  },
                );
              },
            ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    // Get first item image or show placeholder
    String? firstImageUrl;
    if (order.items.isNotEmpty && order.items.first.imageUrl != null) {
      firstImageUrl = order.items.first.imageUrl;
    }

    int totalItems = order.items.fold(0, (sum, item) => sum + item.quantity);
    String formattedDate = DateFormat('dd MMM yyyy, HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(order.timestamp));

    return GestureDetector(
      onTap: () => _showOrderDetail(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: firstImageUrl != null && firstImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        firstImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 16),

            // Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$totalItems Item${totalItems > 1 ? 's' : ''} • ${_formatRupiah(order.price)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              const Center(
                child: Text(
                  "Detail Pesanan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 30),

              // Order Info Section
              _buildDetailSection("Informasi Pesanan", [
                _buildDetailRow("Order ID", order.id.substring(0, 8).toUpperCase()),
                _buildDetailRow("Tanggal", DateFormat('dd MMMM yyyy, HH:mm')
                    .format(DateTime.fromMillisecondsSinceEpoch(order.timestamp))),
                _buildDetailRow("Status Pengiriman", order.status),
                _buildDetailRow("Status Penerimaan", order.receiveStatus),
                if (order.paymentMethod != null)
                  _buildDetailRow("Metode Pembayaran", order.paymentMethod!),
                if (order.pickupAddress != null)
                  _buildDetailRow("Alamat Pickup", order.pickupAddress!),
              ]),

              const SizedBox(height: 16),

              // Items Section
              const Text(
                "Daftar Barang",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 20, color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${item.quantity}x ${_formatRupiah(item.price)}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatRupiah(item.quantity * item.price),
                      style: TextStyle(fontWeight: FontWeight.bold, color: ucOrange),
                    ),
                  ],
                ),
              )),

              const Divider(height: 24),

              // Total Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _formatRupiah(order.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ucOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Belum ada riwayat pesanan",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Pesanan Anda akan muncul di sini",
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}