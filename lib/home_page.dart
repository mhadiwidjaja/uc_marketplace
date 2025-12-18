import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'customer_service_page.dart';
import 'cart_page.dart'; 
import 'category_products_page.dart';
import 'product_detail_page.dart';
import 'models/product_model.dart'; // Import ProductModel Anda

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final Color ucOrange = const Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 15),
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
                _buildCategoryItem(context, "Goods", Icons.inventory_2_outlined, Colors.purple, "Goods"),
                _buildCategoryItem(context, "Arts", Icons.brush, Colors.amber, "Arts"),
                _buildCategoryItem(context, "Fundraising", Icons.volunteer_activism, Colors.cyan, "Fundraising"),
                _buildCategoryItem(context, "Fashion", Icons.checkroom, Colors.green, "Fashion"),
                _buildCategoryItem(context, "F&B", Icons.fastfood, Colors.redAccent, "Food & Beverage"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Grid of Items (Real-time dari Firebase)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: StreamBuilder(
                // Mengambil data dari path 'products' di Realtime Database
                stream: FirebaseDatabase.instance.ref("products").onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("Belum ada produk yang dijual"));
                  }

                  // Mengonversi data Firebase ke List<ProductModel>
                  final Map<dynamic, dynamic> productsMap = 
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  
                  List<ProductModel> productList = [];
                  productsMap.forEach((key, value) {
                    productList.add(ProductModel.fromMap(value, key));
                  });

                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: productList.length, 
                    itemBuilder: (context, index) {
                      return _buildProductCard(context, productList[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String label, IconData icon, Color color, String categoryQuery) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsPage(categoryName: categoryQuery),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () {
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: const Center(child: Icon(Icons.inventory_2, color: Colors.grey, size: 40)),
              ),
            ),
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
                  Text(
                    "Rp ${product.price}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}