import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'models/cart_model.dart';
import 'payment_detail_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  String? selectedAlamat = "Uc_Walk"; 
  String selectedPayment = "QRIS"; 
  final TextEditingController _customAddressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  int _parsePrice(String price) {
    try {
      return int.parse(price.replaceAll('.', '').replaceAll('Rp ', ''));
    } catch (e) { return 0; }
  }

  // MENGAMBIL NAMA PENJUAL BERDASARKAN ID
  Widget _getSellerName(String sellerId) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("users/$sellerId/username").onValue,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          return Text(
            "Toko: ${snapshot.data!.snapshot.value}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
          );
        }
        return const Text("Memuat nama toko...", style: TextStyle(fontSize: 12, color: Colors.grey));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Silakan login")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ucOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("CheckOut", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("carts/${currentUser!.uid}").onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("Keranjang kosong"));

          final Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
          Map<String, List<CartItemModel>> groupedItems = {};
          int subtotalProduk = 0;

          data.forEach((key, value) {
            final item = CartItemModel.fromMap(value);
            subtotalProduk += _parsePrice(item.price) * item.quantity;
            if (groupedItems.containsKey(item.sellerId)) {
              groupedItems[item.sellerId]!.add(item);
            } else {
              groupedItems[item.sellerId] = [item];
            }
          });

          int pajak = (subtotalProduk * 0.1).round(); 
          int biayaLayanan = 5000;
          int totalKeseluruhan = subtotalProduk + pajak + biayaLayanan;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Alamat Pengambilan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _buildAddressDropdown(),
                const Divider(height: 30),

                // DETAIL PESANAN PER TOKO
                const Text("Detail Pesanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...groupedItems.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: double.infinity,
                        color: Colors.blue.withOpacity(0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            _getSellerName(entry.key),
                          ],
                        ),
                      ),
                      ...entry.value.map((item) => ListTile(
                        leading: const Icon(Icons.inventory_2_outlined, size: 20),
                        title: Text(item.productName),
                        subtitle: Text("Qty: ${item.quantity}"),
                        trailing: Text(_formatCurrency(_parsePrice(item.price) * item.quantity)),
                      )),
                      const SizedBox(height: 10),
                    ],
                  );
                }).toList(),

                const Divider(height: 30),

                // INFORMASI PEMBELI
                const Text("Informasi Pembeli", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _buildBuyerInfoSection(),

                const Divider(height: 30),

                const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _buildPaymentDropdown(),

                const Divider(height: 30),

                // RINCIAN PEMBAYARAN
                const Text("Rincian Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _buildPriceRow("Subtotal Produk", _formatCurrency(subtotalProduk)),
                _buildPriceRow("Pajak Aplikasi (10%)", _formatCurrency(pajak)),
                _buildPriceRow("Biaya Layanan", _formatCurrency(biayaLayanan)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Pembayaran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(_formatCurrency(totalKeseluruhan), 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ucOrange)),
                  ],
                ),

                const SizedBox(height: 30),
                // MENGIRIM DATA GROUPED ITEMS KE TOMBOL
                _buildConfirmButton(totalKeseluruhan, groupedItems),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildBuyerInfoSection() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("users/${currentUser!.uid}").onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> userSnapshot) {
        String namaUser = "-";
        String nomorUser = "-";

        if (userSnapshot.hasData && userSnapshot.data!.snapshot.value != null) {
          final userData = Map<dynamic, dynamic>.from(userSnapshot.data!.snapshot.value as Map);
          namaUser = userData['username'] ?? "-";
          nomorUser = userData['phoneNumber'] ?? "-";
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.person_outline, "Nama", namaUser),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.email_outlined, "Email", currentUser?.email ?? "-"),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone_android_outlined, "Nomor", nomorUser),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedAlamat,
          items: ["Uc_Walk", "Uc_Plaza", "Apartement_Benson", "Lantai_2", "Other"]
              .map((val) => DropdownMenuItem(value: val, child: Text(val.replaceAll('_', ' ')))).toList(),
          onChanged: (val) => setState(() => selectedAlamat = val),
        ),
      ),
    );
  }

  Widget _buildPaymentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedPayment,
          items: ["QRIS", "Virtual Account"].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: (val) => setState(() => selectedPayment = val!),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(width: 50, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(child: Text(": $value", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // MENERIMA PARAMETER GROUPEDITEMS AGAR BISA DIKIRIM KE PAYMENT PAGE
  Widget _buildConfirmButton(int total, Map<String, List<CartItemModel>> groupedItems) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ucOrange, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentDetailPage(
                method: selectedPayment, 
                totalAmount: total,
                groupedItems: groupedItems, // Data dikirim ke sini agar split order berhasil
              ),
            ),
          );
        },
        child: const Text("KONFIRMASI PESANAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}