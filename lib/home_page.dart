import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahkan import Auth
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'chat.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'models/product_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color ucOrange = const Color(0xFFF39C12);
  final TextEditingController _searchController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser; // Ambil user aktif
  String _searchQuery = "";
  String? _selectedCategory; // null means "All" 

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 1. Header with Search Bar & Notification Badges
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search Products",
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: ucOrange),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() { _searchQuery = ""; });
                              },
                            ) 
                          : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 15),
                
                // ICON CHAT DENGAN NOTIFIKASI BADGE
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage())),
                  child: StreamBuilder(
                    stream: FirebaseDatabase.instance.ref("chats").onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      int unreadCount = 0;
                      
                      if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                        Map<dynamic, dynamic> rooms = snapshot.data!.snapshot.value as Map;
                        rooms.forEach((key, value) {
                          var info = value['last_info'];
                          // Hitung jika user adalah penerima dan status isRead masih false
                          if (info != null && 
                              info['receiverId'] == currentUser?.uid && 
                              info['isRead'] == false) {
                            unreadCount++;
                          }
                        });
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                          if (unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red, // Badge Merah
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
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
                _buildCategoryItem(context, "All", Icons.apps, Colors.blueGrey, null),
                _buildCategoryItem(context, "Goods", Icons.inventory_2, Colors.purple, "Goods"),
                _buildCategoryItem(context, "Arts", Icons.brush, Colors.amber, "Arts"),
                _buildCategoryItem(context, "Fundraising", Icons.volunteer_activism, Colors.cyan, "Fundraising"),
                _buildCategoryItem(context, "F&B", Icons.fastfood, Colors.redAccent, "Food"),
                _buildCategoryItem(context, "Fashion", Icons.checkroom, Colors.green, "Fashion"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Grid of Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: StreamBuilder(
                stream: FirebaseDatabase.instance.ref("products").onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("Belum ada produk yang dijual"));
                  }

                  final Map<dynamic, dynamic> productsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<ProductModel> productList = [];
                  
                  productsMap.forEach((key, value) {
                    final product = ProductModel.fromMap(value, key);
                    // Filter by search query
                    bool matchesSearch = _searchQuery.isEmpty || product.name.toLowerCase().contains(_searchQuery);
                    // Filter by category
                    bool matchesCategory = _selectedCategory == null || 
                        product.category?.toLowerCase() == _selectedCategory?.toLowerCase();
                    
                    if (matchesSearch && matchesCategory) {
                      productList.add(product);
                    }
                  });

                  if (productList.isEmpty) {
                    return const Center(child: Text("Produk tidak ditemukan"));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8, 
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

  // Widget Helpers (Category & Product Card) tetap sama seperti sebelumnya...
  Widget _buildCategoryItem(BuildContext context, String label, IconData icon, Color color, String? categoryQuery) {
    final bool isSelected = _selectedCategory == categoryQuery;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryQuery;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? ucOrange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailPage(product: product)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          product.imageUrl!, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRupiah(product.price), 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)
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