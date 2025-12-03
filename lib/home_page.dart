import 'package:flutter/material.dart';
import 'customer_service_page.dart'; // UPDATED Import

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
                const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 15),
                
                // Chat Icon -> Navigate to Customer Service
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

          // ... (Rest of the file remains exactly the same) ...
          
          // 2. Categories Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryItem("Goods", Icons.inventory_2_outlined, Colors.purple),
                _buildCategoryItem("Arts", Icons.brush, Colors.amber),
                _buildCategoryItem("Fund-\nraising", Icons.volunteer_activism, Colors.cyan),
                _buildCategoryItem("Fashion", Icons.checkroom, Colors.green),
                _buildCategoryItem("F&B", Icons.fastfood, Colors.redAccent),
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
                itemCount: 6, 
                itemBuilder: (context, index) {
                  return _buildProductCard();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, Color color) {
    return Column(
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
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        )
      ],
    );
  }

  Widget _buildProductCard() {
    return Container(
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Item Name", style: TextStyle(fontWeight: FontWeight.bold)),
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
}