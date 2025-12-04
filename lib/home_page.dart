import 'package:flutter/material.dart';
import 'customer_service_page.dart';
// Import CartPage untuk CartItem, Product, dan fungsi global addToCart
import 'cart_page.dart'; 
import 'category_products_page.dart';
import 'product_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final Color ucOrange = const Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
    // Dummy list yang sekarang menggunakan Model Product
    final List<Product> dummyProducts = [
      Product(id: "1", name: "Headphone Gaming PRO X", price: "200.000"),
      Product(id: "2", name: "Wireless Earbuds Sport", price: "150.000"),
      Product(id: "3", name: "Smartwatch Seri 5", price: "450.000"),
      Product(id: "4", name: "Keyboard Mekanik RGB", price: "320.000"),
      Product(id: "5", name: "Mouse Nirkabel Vertikal", price: "95.000"),
      Product(id: "6", name: "Monitor UltraWide 4K", price: "1.200.000"),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 1. Header with Search Bar
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(color: ucOrange),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "Search Products",
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                
                // --- Shopping Cart Icon (Linked to CartPage) ---
                GestureDetector(
                  onTap: () {
                    // Refresh CartPage saat kembali, jadi hanya perlu push
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                ),
                
                const SizedBox(width: 15),
                
                // --- Chat Icon (Linked to CustomerServicePage) ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerServicePage()),
                    );
                  },
                  child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          // 2. Categories Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryItem(
                  context,
                  "Goods",
                  Icons.inventory_2_outlined,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryProductsPage(categoryName: "Goods"),
                      ),
                    );
                  },
                ),
                _buildCategoryItem(
                  context,
                  "Arts",
                  Icons.brush,
                  Colors.amber,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryProductsPage(categoryName: "Arts"),
                      ),
                    );
                  },
                ),
                _buildCategoryItem(
                  context,
                  "Fundraising",
                  Icons.volunteer_activism,
                  Colors.cyan,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryProductsPage(categoryName: "Fundraising"),
                      ),
                    );
                  },
                ),
                _buildCategoryItem(
                  context,
                  "Fashion",
                  Icons.checkroom,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryProductsPage(categoryName: "Fashion"),
                      ),
                    );
                  },
                ),
                _buildCategoryItem(
                  context,
                  "F&B",
                  Icons.fastfood,
                  Colors.redAccent,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryProductsPage(categoryName: "Food & Beverage"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Grid of Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: dummyProducts.length, 
                itemBuilder: (context, index) {
                  // Meneruskan objek Product ke _buildProductCard
                  return _buildProductCard(context, dummyProducts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Categories
  Widget _buildCategoryItem(
    BuildContext context, 
    String label, 
    IconData icon, 
    Color color, 
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 28, 
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          )
        ],
      ),
    );
  }

  // Helper for Product Cards - Menerima objek Product
  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman detail dengan membawa objek Product
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
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
                child: const Center(child: Icon(Icons.inventory_2, color: Colors.grey, size: 40)),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(" 5.0 (23) - 67 sold", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Rp ${product.price}", style: const TextStyle(fontWeight: FontWeight.bold)), // Menggunakan harga dari model
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}