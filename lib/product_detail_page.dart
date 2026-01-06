import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/product_model.dart';
import 'models/cart_model.dart';
import 'add_product_page.dart';
import 'chat_room_page.dart'; // Import halaman chat

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  final Color ucOrange = const Color(0xFFF39C12);

  // FUNGSI HELPER FORMAT RUPIAH
  String _formatRupiah(String price) {
    try {
      int value = int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(value);
    } catch (e) {
      return "Rp $price";
    }
  }

  // Fungsi Navigasi ke Chat
  void _navigateToChat(BuildContext context, String sellerName) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login untuk memulai chat")),
      );
      return;
    }

    // Jangan biarkan user chat diri sendiri
    if (currentUser.uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ini adalah toko Anda sendiri.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          receiverId: product.sellerId,
          receiverName: sellerName,
        ),
      ),
    );
  }

  // Fungsi Tambah ke Keranjang
  Future<void> _addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login untuk menambah keranjang")),
      );
      return;
    }

    if (user.uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda tidak bisa membeli produk sendiri!"), backgroundColor: Colors.red),
      );
      return;
    }

    DatabaseReference cartRef = FirebaseDatabase.instance.ref("carts/${user.uid}/${product.id}");

    try {
      final snapshot = await cartRef.get();
      int currentQtyInCart = 0;
      
      if (snapshot.exists) {
        currentQtyInCart = (snapshot.value as Map)['quantity'] ?? 0;
      }

      if (currentQtyInCart >= product.stock && product.stock != 999999) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Stok tidak mencukupi!"), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      if (snapshot.exists) {
        await cartRef.update({'quantity': currentQtyInCart + 1});
      } else {
        CartItemModel newItem = CartItemModel(
          productId: product.id!,
          productName: product.name,
          price: product.price,
          quantity: 1,
          sellerId: product.sellerId,
        );
        await cartRef.set(newItem.toMap());
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil masuk keranjang"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error cart: $e");
    }
  }

  // Fungsi Hapus Produk (Seller Only)
  Future<void> _deleteProduct(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk"),
        content: const Text("Tindakan ini permanen. Hapus produk ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Hapus", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseDatabase.instance.ref("products/${product.id}").remove();
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Produk telah dihapus")),
          );
        }
      } catch (e) {
        debugPrint("Error delete: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isSeller = currentUser?.uid == product.sellerId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ucOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Detail Produk", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: isSeller ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductPage(productToEdit: product))),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteProduct(context),
          ),
        ] : [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            Container(
              height: 350,
              width: double.infinity,
              color: Colors.grey[200],
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.inventory_2, size: 100, color: Colors.grey),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatRupiah(product.price), 
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ucOrange)),
                  const SizedBox(height: 10),
                  Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  const Divider(),
                  
                  // SELLER INFO DENGAN TOMBOL CHAT
                  const Text("Informasi Penjual", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder(
                    stream: FirebaseDatabase.instance.ref("users/${product.sellerId}").onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                        final userData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
                        final String sellerName = userData['username'] ?? "Penjual";

                        return Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: ucOrange,
                              backgroundImage: userData['profileImageUrl'] != null 
                                ? NetworkImage(userData['profileImageUrl']) 
                                : null,
                              child: userData['profileImageUrl'] == null 
                                ? const Icon(Icons.person, color: Colors.white) 
                                : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(sellerName, style: const TextStyle(fontSize: 15)),
                            ),
                            // TOMBOL CHAT DI SEBELAH KANAN
                            IconButton(
                              onPressed: () => _navigateToChat(context, sellerName),
                              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFF39C12)),
                              tooltip: "Chat Penjual",
                            ),
                          ],
                        );
                      }
                      return const Text("Memuat...");
                    },
                  ),
                  const Divider(height: 30),
                  
                  const Text("Deskripsi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(product.description, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)),
                  
                  const SizedBox(height: 20),
                  _buildInfoBox("Kategori", product.category),
                  _buildInfoBox("Stok", product.stock >= 999999 ? "Unlimited" : "${product.stock} pcs"),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
        ),
        child: ElevatedButton(
          onPressed: (isSeller || (product.stock <= 0 && product.stock != 999999)) ? null : () => _addToCart(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSeller ? Colors.grey : ucOrange,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          child: Text(
            isSeller ? "Ini Jualan Anda" : (product.stock <= 0 ? "Stok Habis" : "Tambah ke Keranjang"),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}