import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uc_marketplace/checkout_page.dart';
import 'models/cart_model.dart';
// Import file checkout kamu nanti di sini:
// import 'checkout_page.dart'; 

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

  int _parsePrice(String price) {
    return int.parse(price.replaceAll('.', '').replaceAll('Rp ', ''));
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    if (currentUser == null) return;
    
    DatabaseReference productRef = FirebaseDatabase.instance.ref("products/$productId/stock");
    DatabaseReference cartRef = FirebaseDatabase.instance.ref("carts/${currentUser!.uid}/$productId");
    
    if (newQuantity <= 0) {
      await cartRef.remove();
      return;
    }

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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gambar Produk (Placeholder sesuai desain)
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.smartphone, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 15),
          // Info Produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Type: ProMax\nColor: Gray", // Hardcoded sesuai desain gambar
                  style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(_parsePrice(item.price)),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
          // Plus Minus Quantity
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                onPressed: () => _updateQuantity(item.productId, item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.add_circle_outline, color: ucOrange),
                onPressed: () => _updateQuantity(item.productId, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Silakan login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Cart",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: cartList.length,
                  itemBuilder: (context, index) => _buildCartItem(cartList[index]),
                ),
              ),
              _buildCheckoutBar(total),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Your Cart Is Empty!", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total amount:", style: TextStyle(color: Colors.grey)),
                Text(_formatCurrency(total), 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ucOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
               onPressed: () {
  Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutPage()));
},
                child: const Text(
                  "Check Out",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}