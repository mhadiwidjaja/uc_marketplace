import 'package:flutter/material.dart';
// Import model dan fungsi global cart dari file yang sama
import 'cart_page.dart'; 

class ProductDetailPage extends StatelessWidget {
  // Sekarang menerima objek Product lengkap
  final Product product; 

  const ProductDetailPage({super.key, required this.product});

  final Color ucOrange = const Color(0xFFF39C12);
  final Color darkGrey = const Color(0xFF333333);
  
  // Helper untuk format harga
  String _formatCurrency(String price) {
    int amount = int.parse(price.replaceAll('.', ''));
    if (amount == 0) return 'Rp 0';
    String str = amount.toString();
    return 'Rp ${str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          product.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Product Image Gallery (Placeholder)
                  Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_search, size: 80, color: Colors.grey),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Price and Name
                        Text(
                          _formatCurrency(product.price),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 3. Rating and Sold Info
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text("5.0 (23 Ratings)"),
                            SizedBox(width: 15),
                            Text("•"),
                            SizedBox(width: 15),
                            Text("67 Sold"),
                          ],
                        ),
                        const Divider(height: 30),

                        // 4. Description
                        const Text(
                          "Description",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Ini adalah deskripsi rinci untuk produk ${product.name}. Produk ini menawarkan kualitas terbaik dan dirancang untuk memenuhi kebutuhan Anda. Stok terbatas, jadi segera pesan!",
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        
                        const Divider(height: 30),

                        // 5. Seller Info (Placeholder)
                        const Row(
                          children: [
                            CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=1")),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Official Store", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text("Online 5 menit lalu", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(
              children: [
                // Chat Button
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, color: darkGrey, size: 28),
                  onPressed: () {
                    // Navigate to chat/customer service
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Membuka chat dengan penjual...")),
                    );
                  },
                ),
                const SizedBox(width: 10),
                
                // Add to Cart Button - PENTING: Memanggil fungsi global addToCart
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Memanggil fungsi global untuk menambahkan produk ke cart
                        addToCart(product, context);
                      },
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      label: const Text(
                        "Add to Cart",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ucOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}