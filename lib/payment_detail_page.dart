import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main_screen.dart'; 
import 'models/cart_model.dart'; 

class PaymentDetailPage extends StatelessWidget {
  final String method;
  final int totalAmount;
  final Map<String, List<CartItemModel>> groupedItems;
  final String? pickupAddress;

  const PaymentDetailPage({
    super.key,
    required this.method,
    required this.totalAmount,
    required this.groupedItems,
    this.pickupAddress,
  });

  // Fungsi helper format mata uang
  String _formatCurrency(int amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  // Fungsi utama saat tombol "SAYA SUDAH BAYAR" ditekan
  Future<void> _handlePaymentSuccess(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Iterasi setiap seller (Split Order)
        for (var entry in groupedItems.entries) {
          String sellerId = entry.key;
          List<CartItemModel> items = entry.value;

          int totalPerSeller = 0;
          for (var item in items) {
            int priceInt = int.parse(item.price.replaceAll(RegExp(r'[^0-9]'), ''));
            totalPerSeller += priceInt * item.quantity;

            // 1. UPDATE STOK DAN PROGRESS BAR (soldCount) DI POV SELLER
            final productRef = FirebaseDatabase.instance.ref("products/${item.productId}");
            await productRef.runTransaction((Object? productData) {
              if (productData == null) return Transaction.abort();

              Map<String, dynamic> product = Map<String, dynamic>.from(productData as Map);
              int currentStock = product['stock'] ?? 0;
              int currentSold = product['soldCount'] ?? 0;

              // Kurangi stok jika bukan unlimited (999999)
              if (currentStock < 999999) {
                product['stock'] = (currentStock >= item.quantity) ? currentStock - item.quantity : 0;
              }
              
              // Naikkan soldCount agar Progress Bar di POV Seller naik
              product['soldCount'] = currentSold + item.quantity;

              return Transaction.success(product);
            });
          }

          // 2. SIMPAN DATA KE NODE 'orders'
          DatabaseReference orderRef = FirebaseDatabase.instance.ref("orders").push();
          String orderId = orderRef.key!;
          
          List<Map<String, dynamic>> itemsData = items.map((item) {
             int priceInt = int.parse(item.price.replaceAll(RegExp(r'[^0-9]'), ''));
             return {
               'productId': item.productId,
               'productName': item.productName,
               'quantity': item.quantity,
               'price': priceInt,
             };
          }).toList();

          await orderRef.set({
            'orderId': orderId,
            'buyerId': user.uid,
            'sellerId': sellerId,
            'status': 'Pending',
            'receiveStatus': 'Pending',
            'totalHarga': _formatCurrency(totalPerSeller),
            'paymentMethod': method,
            'productSummary': items.first.productName +
                (items.length > 1 ? " (+${items.length - 1} lainnya)" : ""),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'isRead': false, // Memicu badge merah di navbar seller
            'items': itemsData,
            'pickupAddress': pickupAddress ?? 'Uc Walk',
          });

          // 3. KIRIM NOTIFIKASI KE TAB INBOX SELLER
          await _sendNotificationToSeller(sellerId, orderId, items.first.productName, items.length);
        }

        // 4. HAPUS KERANJANG
        await FirebaseDatabase.instance.ref("carts/${user.uid}").remove();

        if (context.mounted) {
          _showSuccessDialog(context);
        }
      } catch (e) {
        debugPrint("Error handling payment: $e");
      }
    }
  }

  // Fungsi membuat data notifikasi untuk POV Seller
  Future<void> _sendNotificationToSeller(String sellerId, String orderId, String firstItemName, int totalItems) async {
    final notificationRef = FirebaseDatabase.instance.ref("notifications").push();
    
    String itemSummary = firstItemName;
    if (totalItems > 1) {
      itemSummary += " dan ${totalItems - 1} barang lainnya";
    }

    await notificationRef.set({
      'userId': sellerId, 
      'orderId': orderId,
      'type': 'new_order',
      'title': 'Pesanan Baru Masuk!',
      'message': 'Seseorang baru saja membeli $itemSummary. Segera siapkan barangnya!',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
      'isConfirmed': false,
    });
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Pembayaran Berhasil!.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF39C12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (route) => false,
                );
              },
              child: const Text("Kembali ke Beranda",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF39C12),
        title: const Text("Instruksi Pembayaran",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Total yang harus dibayar:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(_formatCurrency(totalAmount),
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF39C12))),
            const Divider(height: 60),
            if (method == "QRIS") ...[
              const Text("SCAN QRIS UNTUK MEMBAYAR",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.network(
                  "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=UC_MARKETPLACE_PAYMENT",
                  width: 250,
                  height: 250,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.qr_code_2, size: 200, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                  "Bisa scan menggunakan GoPay, OVO, ShopeePay, atau M-Banking",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            ] else ...[
              const Text("TRANSFER KE VIRTUAL ACCOUNT",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 30),
              const Text("Nomor Virtual Account (BCA):",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10)),
                child: const Text("1234 0812 3456 7890",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
              ),
              const SizedBox(height: 10),
              const Text("Atas Nama: Uc_Market",
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF39C12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _handlePaymentSuccess(context),
                child: const Text("SAYA SUDAH BAYAR",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}