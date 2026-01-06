import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main_screen.dart'; // WAJIB IMPORT INI AGAR NAVBAR MUNCUL
import 'models/cart_model.dart'; // Pastikan import model cart Anda

class PaymentDetailPage extends StatelessWidget {
  final String method;
  final int totalAmount;
  final Map<String, List<CartItemModel>> groupedItems; // Menerima data yang sudah dikelompokkan per Seller

  const PaymentDetailPage({
    super.key,
    required this.method,
    required this.totalAmount,
    required this.groupedItems,
  });

  // Fungsi helper format mata uang agar konsisten
  String _formatCurrency(int amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  // Fungsi untuk menyimpan pesanan per penjual, membersihkan keranjang, dan kembali ke Beranda
  Future<void> _handlePaymentSuccess(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // PERBAIKAN: Iterasi setiap seller untuk memisahkan pesanan (Split Order)
        for (var entry in groupedItems.entries) {
          String sellerId = entry.key;
          List<CartItemModel> items = entry.value;

          // Hitung total harga khusus untuk seller ini (Subtotal per Seller)
          int totalPerSeller = 0;
          for (var item in items) {
            // Membersihkan string harga (Rp 1.000 -> 1000) dan mengubah ke int
            int priceInt = int.parse(item.price.replaceAll(RegExp(r'[^0-9]'), ''));
            totalPerSeller += priceInt * item.quantity;
          }

          // Tambahkan biaya layanan/pajak proporsional jika diperlukan, 
          // namun untuk kesederhanaan kita gunakan harga barang saja di sini.

          // 1. SIMPAN DATA KE NODE 'orders' SECARA TERPISAH PER SELLER
          DatabaseReference orderRef = FirebaseDatabase.instance.ref("orders").push();
          await orderRef.set({
            'orderId': orderRef.key,
            'buyerId': user.uid,
            'sellerId': sellerId, // ID Penjual dipisahkan agar muncul berbeda di Inbox
            'status': 'Pending', // Status default warna kuning
            'totalHarga': _formatCurrency(totalPerSeller),
            'paymentMethod': method,
            // Ringkasan nama barang untuk seller ini (Contoh: "Barang A (+2 lainnya)")
            'productSummary': items.first.productName +
                (items.length > 1 ? " (+${items.length - 1} lainnya)" : ""),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'isRead': false, // Memicu notifikasi badge merah di navbar
          });
        }

        // 2. HAPUS ISI KERANJANG DI FIREBASE SETELAH SEMUA ORDER TERCATAT
        await FirebaseDatabase.instance.ref("carts/${user.uid}").remove();

        if (context.mounted) {
          // 3. TAMPILKAN DIALOG SUKSES
          _showSuccessDialog(context);
        }
      } catch (e) {
        debugPrint("Error saving split orders: $e");
      }
    }
  }

  // Widget Helper untuk Dialog Sukses
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Konfirmasi Pembayaran Terkirim!\n\nTerima kasih, pesanan Anda akan segera diproses oleh penjual.",
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
                // Navigasi ke MainScreen (Beranda dengan Navbar)
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