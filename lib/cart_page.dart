import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/cart_model.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String _formatCurrency(int amount) {
    if (amount == 0) return 'Rp 0';
    String str = amount.toString();
    return 'Rp ${str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  int _parsePrice(String price) => int.parse(price.replaceAll('.', ''));

  // Update Quantity dengan Pengecekan Stok Real-time
  Future<void> _updateQuantity(String productId, int newQuantity) async {
    if (currentUser == null) return;
    
    DatabaseReference productRef = FirebaseDatabase.instance.ref("products/$productId/stock");
    DatabaseReference cartRef = FirebaseDatabase.instance.ref("carts/${currentUser!.uid}/$productId");
    
    if (newQuantity <= 0) {
      await cartRef.remove();
      return;
    }

    // Ambil stok terbaru dari database produk
    final stockSnapshot = await productRef.get();
    int availableStock = (stockSnapshot.value as int?) ?? 0;

    if (newQuantity > availableStock) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Batas stok tercapai! Maksimal: $availableStock")),
        );
      }
      return;
    }

    await cartRef.update({'quantity': newQuantity});
  }

  Widget _buildCartItem(CartItemModel item) {
    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => FirebaseDatabase.instance.ref("carts/${currentUser!.uid}/${item.productId}").remove(),
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shopping_bag, color: Colors.grey)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(_parsePrice(item.price)), style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => _updateQuantity(item.productId, item.quantity - 1)),
                Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), color: ucOrange, onPressed: () => _updateQuantity(item.productId, item.quantity + 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Silakan login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(backgroundColor: ucOrange, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.white), title: const Text("My Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("carts/${currentUser!.uid}").onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return _buildEmptyState();

          final Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
          List<CartItemModel> cartList = [];
          int total = 0;

          data.forEach((key, value) {
            final item = CartItemModel.fromMap(value);
            cartList.add(item);
            total += _parsePrice(item.price) * item.quantity;
          });

          return Column(
            children: [
              Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: cartList.length, itemBuilder: (context, index) => _buildCartItem(cartList[index]))),
              _buildCheckoutBar(total, cartList.length),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shopping_cart_outlined, size: 100, color: Color(0xFF5A6B7C)), const SizedBox(height: 30), const Text("Your Cart Is Empty!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]));
  }

  Widget _buildCheckoutBar(int total, int itemCount) {
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, -3))]),
      child: SafeArea(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Total Belanja:", style: TextStyle(fontSize: 12, color: Colors.grey)), Text(_formatCurrency(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        SizedBox(height: 45, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: ucOrange), onPressed: () {}, child: Text("Checkout ($itemCount)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ])),
    );
  }
}