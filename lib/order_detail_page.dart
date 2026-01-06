import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'models/order_model.dart';
import 'update_status_page.dart';
import 'chat_room_page.dart';

class OrderDetailPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  final Color ucOrange = const Color(0xFFF39C12);
  final Color greenColor = const Color(0xFF2ECC71);

  String _formatDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat("dd/MM/yyyy, HH:mm:ss").format(dt);
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  int _parsePrice(String price) {
    try {
      return int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    String orderId = "#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}";
    
    // Calculate totals
    int itemsTotal = 0;
    for (var item in order.items) {
      itemsTotal += item.price * item.quantity;
    }
    if (itemsTotal == 0) {
      itemsTotal = _parsePrice(order.price);
    }
    
    // Seller receives full product price (tax is paid by buyer, not deducted from seller)
    int youEarn = itemsTotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Manage Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Create Time: ${_formatDate(order.timestamp)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Order No $orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 16, color: greenColor),
                      const SizedBox(width: 4),
                      Text(order.status, style: TextStyle(color: greenColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 30),

              // Pickup Address
              const Text("Alamat Pengambilan", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: ucOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(order.pickupAddress ?? "Uc Walk", style: const TextStyle(fontSize: 14))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: ucOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(DateFormat("d MMMM yyyy").format(DateTime.fromMillisecondsSinceEpoch(order.timestamp)), style: const TextStyle(fontSize: 14)),
                ],
              ),
              const Divider(height: 30),

              // Customer Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Customer", style: TextStyle(fontWeight: FontWeight.bold)),
                  StreamBuilder(
                    stream: FirebaseDatabase.instance.ref("users/${order.buyerId}").onValue,
                    builder: (context, userSnapshot) {
                      String actualBuyerName = order.buyerName ?? "Customer";
                      if (userSnapshot.hasData && userSnapshot.data!.snapshot.value != null) {
                        final userData = userSnapshot.data!.snapshot.value as Map;
                        actualBuyerName = userData['username'] ?? actualBuyerName;
                      }
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              receiverId: order.buyerId,
                              receiverName: actualBuyerName,
                            ),
                          ));
                        },
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 16, color: greenColor),
                            const SizedBox(width: 4),
                            Text("Contact", style: TextStyle(color: greenColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StreamBuilder(
                stream: FirebaseDatabase.instance.ref("users/${order.buyerId}").onValue,
                builder: (context, snapshot) {
                  String buyerName = order.buyerName ?? "Customer";
                  String buyerPhone = order.buyerPhone ?? "-";
                  
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    final userData = snapshot.data!.snapshot.value as Map;
                    buyerName = userData['username'] ?? buyerName;
                    buyerPhone = userData['phone'] ?? buyerPhone;
                  }

                  return Row(
                    children: [
                      Icon(Icons.person_outline, size: 40, color: Colors.teal),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(buyerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(buyerPhone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 30),

              // Order Details
              const Text("Order Details", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${order.items.length} items", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              
              if (order.items.isEmpty)
                _buildItemRow(order.productName, _parsePrice(order.price), 1, null)
              else
                ...order.items.map((item) => _buildItemRow(item.productName, item.price, item.quantity, item.imageUrl)).toList(),

              const Divider(height: 30),

              // Order Information
              const Text("Order information", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildInfoRow("Payment method:", order.paymentMethod ?? "QRIS"),
              const SizedBox(height: 8),
              _buildInfoRow("Delivery method:", "Pickup"),
              const SizedBox(height: 8),
              _buildInfoRow("Pickup Location:", order.pickupAddress ?? "Uc Walk"),

              const Divider(height: 30),

              // Financial Summary - Seller receives product price (no tax deducted from seller)
              _buildFinancialRow("Total Produk:", _formatRupiah(itemsTotal)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Pendapatan Anda:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_formatRupiah(youEarn), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ucOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateStatusPage(order: order)));
            },
            child: const Text("Update Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(String name, int price, int quantity, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
            ),
            child: imageUrl == null ? const Icon(Icons.inventory_2, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Units : $quantity", style: const TextStyle(fontSize: 12)),
                    Text(_formatRupiah(price), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _buildFinancialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
