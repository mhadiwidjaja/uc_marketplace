import 'package:flutter/material.dart';
import 'home_page.dart'; // Import HomePage untuk menggunakan _buildProductCard

class CategoryProductsPage extends StatelessWidget {
  final String categoryName;
  const CategoryProductsPage({super.key, required this.categoryName});

  final Color ucOrange = const Color(0xFFF39C12);

  // Menggunakan helper widget dari HomePage untuk konsistensi tampilan produk
  Widget _buildProductCard() {
    // Mengambil implementasi dari HomePage, disederhanakan di sini untuk menghindari duplikasi kode
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dummy Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: const Center(child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey)),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${categoryName} Item X", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(" 5.0 (23) - 67 sold", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Rp 200.000", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryName, // Menampilkan nama kategori di AppBar
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 8, // Dummy item count
          itemBuilder: (context, index) {
            return _buildProductCard();
          },
        ),
      ),
    );
  }
}