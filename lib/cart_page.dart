import 'package:flutter/material.dart';

// --- NEW: Product Model (Struktur data produk) ---
class Product {
  final String id;
  final String name;
  final String price; // Use String for display currency, e.g., '200.000'
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl = "https://via.placeholder.com/60",
  });
}

// --- Cart Item Model (Mengandung objek Product dan kuantitas) ---
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });
}

// --- GLOBAL CART STORAGE (Mengganti state lokal) ---
List<CartItem> _globalCartItems = [
  // Dummy data awal
  CartItem(product: Product(id: '1', name: 'Headphone Gaming PRO X', price: '200.000')),
  CartItem(product: Product(id: '2', name: 'Wireless Earbuds Sport', price: '150.000'), quantity: 2),
];

// --- Global function to add product to cart (Dipanggil dari Detail Page) ---
void addToCart(Product product, BuildContext context) {
  // Cek apakah item sudah ada
  int existingIndex = _globalCartItems.indexWhere((item) => item.product.id == product.id);

  if (existingIndex != -1) {
    // Jika ada, tambahkan kuantitas
    _globalCartItems[existingIndex].quantity++;
  } else {
    // Jika tidak ada, tambahkan item baru
    _globalCartItems.add(CartItem(product: product, quantity: 1));
  }

  // Tampilkan notifikasi Snack Bar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("${product.name} ditambahkan ke keranjang!"),
      backgroundColor: Colors.green,
    ),
  );
}
// -----------------------------------------------------------------


class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Color ucOrange = const Color(0xFFF39C12);

  // --- Helper to calculate total (Simplified) ---
  int _calculateTotal() {
    int total = 0;
    // Menggunakan global list
    for (var item in _globalCartItems) { 
      int priceValue = int.parse(item.product.price.replaceAll('.', ''));
      total += priceValue * item.quantity;
    }
    return total;
  }
  
  // --- Helper to format price using regex for consistency and readability ---
  String _formatCurrency(int amount) {
    if (amount == 0) return 'Rp 0';
    String str = amount.toString();
    return 'Rp ${str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // --- PENTING: Memperbarui UI saat kembali ke halaman ini ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Memaksa UI untuk diperbarui dengan data global terbaru saat halaman difokuskan kembali
    if(ModalRoute.of(context)?.isCurrent ?? false) {
      setState(() {});
    }
  }

  // --- Helper to build a single cart item row ---
  Widget _buildCartItem(CartItem item) {
    int itemBasePrice = int.parse(item.product.price.replaceAll('.', ''));

    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          // Menghapus dari list global
          _globalCartItems.removeWhere((i) => i.product.id == item.product.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${item.product.name} dihapus dari keranjang")),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag, color: Colors.grey),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  // Menggunakan helper _formatCurrency
                  Text(
                    _formatCurrency(itemBasePrice),
                    style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  color: Colors.grey,
                  onPressed: () {
                    setState(() {
                      if (item.quantity > 1) item.quantity--;
                    });
                  },
                ),
                Text(
                  item.quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: ucOrange,
                  onPressed: () {
                    setState(() {
                      item.quantity++;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int total = _calculateTotal();
    String formattedTotal = _formatCurrency(total); 

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Cart",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _globalCartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined, 
                    size: 100, 
                    color: Color(0xFF5A6B7C),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Your Cart Is Empty!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Ketika Anda menambahkan produk, mereka akan\nmuncul di sini.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              // Menggunakan global list
              children: _globalCartItems.map((item) => _buildCartItem(item)).toList(),
            ),
      
      // Bottom Checkout Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Belanja:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    formattedTotal,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    // Placeholder for Checkout Logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Proceeding to Checkout...")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ucOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Checkout (${_globalCartItems.length})", // Menggunakan jumlah item dinamis
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}