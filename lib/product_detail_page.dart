import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/product_model.dart';
import 'models/cart_model.dart';
import 'add_product_page.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  final Color ucOrange = const Color(0xFFF39C12);

  // Fungsi Tambah ke Keranjang dengan Cek Stok
  Future<void> _addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login untuk menambah keranjang")),
      );
      return;
    }

    // PROTEKSI 1: Tidak bisa beli barang sendiri
    if (user.uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda tidak bisa membeli produk Anda sendiri!"),
          backgroundColor: Colors.red,
        ),
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

      // PROTEKSI 2: Cek Stok (Error Handling Quantity)
      if (currentQtyInCart >= product.stock) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal! Stok tersisa hanya ${product.stock}"),
              backgroundColor: Colors.orange,
            ),
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
        );
        await cartRef.set(newItem.toMap());
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil ditambah ke keranjang"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Error cart: $e");
    }
  }

  // Fungsi Hapus Produk (Hanya untuk Seller)
  Future<void> _deleteProduct(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk"),
        content: const Text("Apakah Anda yakin ingin menghapus produk ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseDatabase.instance.ref("products/${product.id}").remove();
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isSeller = currentUser?.uid == product.sellerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Detail Produk", style: TextStyle(color: Colors.white)),
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
            Container(height: 300, width: double.infinity, color: Colors.grey[300], child: const Icon(Icons.image, size: 100, color: Colors.grey)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rp ${product.price}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ucOrange)),
                  const SizedBox(height: 8),
                  Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text("Penjual", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  StreamBuilder(
                    stream: FirebaseDatabase.instance.ref("users/${product.sellerId}").onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                        final userData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3")),
                          title: Text(userData['username'] ?? "Penjual Anonim"),
                        );
                      }
                      return const Text("Memuat info penjual...");
                    },
                  ),
                  const Divider(),
                  const Text("Deskripsi Produk", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product.description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 20),
                  _buildInfoRow("Kategori", product.category),
                  _buildInfoRow("Stok Tersedia", product.stock == 999999 ? "Unlimited" : product.stock.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: (isSeller || product.stock <= 0) ? null : () => _addToCart(context),
          style: ElevatedButton.styleFrom(backgroundColor: isSeller ? Colors.grey : ucOrange),
          child: Text(
            isSeller ? "Ini Produk Anda" : (product.stock <= 0 ? "Stok Habis" : "Tambah ke Keranjang"),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(children: [Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)), Text(value)]),
    );
  }
}