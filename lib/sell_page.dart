import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'models/product_model.dart';
import 'add_product_page.dart';
import 'chat.dart';
import 'order_management_page.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Helper: Format Revenue (e.g., 2.4jt)
  String _formatRevenue(int amount) {
    if (amount >= 1000000000) {
      double res = amount / 1000000000;
      return "${res.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M";
    } else if (amount >= 1000000) {
      double res = amount / 1000000;
      return "${res.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}jt";
    } else if (amount >= 1000) {
      double res = amount / 1000;
      return "${res.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}rb";
    }
    return amount.toString();
  }

  // Helper: Format Price
  String _formatRupiah(String price) {
      try {
        int val = int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));
        return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val);
      } catch (e) {
        return price;
      }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please login to view dashboard")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: SizedBox(
        width: 65,
        height: 65,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const AddProductPage()));
          },
          backgroundColor: ucOrange,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      body: StreamBuilder(
        // Stream Orders
        stream: FirebaseDatabase.instance.ref("orders").orderByChild("sellerId").equalTo(currentUser!.uid).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> orderSnapshot) {
            int orderCount = 0;
            int totalRevenue = 0;
            
            if (orderSnapshot.hasData && orderSnapshot.data!.snapshot.value != null) {
                final ordersData = orderSnapshot.data!.snapshot.value;
                if (ordersData is Map) {
                    orderCount = ordersData.length;
                    ordersData.forEach((k, v) {
                       // Only count revenue for completed/valid orders if you want
                       // strict logic. For demo, summing all non-cancelled.
                       if (v['status'] != 'Cancelled') {
                           // Parse 'totalHarga' usually string "Rp 200.000"
                           String priceStr = v['totalHarga'] ?? "0";
                           int p = int.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                           totalRevenue += p;
                       }
                    });
                }
            }

            return StreamBuilder(
                // Stream Products
                stream: FirebaseDatabase.instance.ref("products").orderByChild("sellerId").equalTo(currentUser!.uid).onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> productSnapshot) {
                    List<ProductModel> products = [];
                    int goalsHit = 0;
                    
                    if (productSnapshot.hasData && productSnapshot.data!.snapshot.value != null) {
                        final prodData = productSnapshot.data!.snapshot.value;
                        if (prodData is Map) {
                            prodData.forEach((k, v) {
                                final p = ProductModel.fromMap(v, k.toString());
                                products.add(p);
                                if (p.soldCount >= p.targetSales && p.targetSales > 0) {
                                    goalsHit++;
                                }
                            });
                        }
                    }

                    return Column(
                        children: [
                             // 1. Header
                            _buildHeader(context),

                            Expanded(
                                child: ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: [
                                        // 2. Stats Row
                                        Row(
                                            children: [
                                                _buildStatCard("Goals", "$goalsHit/${products.length}", const Color(0xFFD946EF), null),
                                                const SizedBox(width: 10),
                                                _buildStatCard("Orders", "$orderCount", const Color(0xFF06B6D4), () {
                                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderManagementPage()));
                                                }),
                                                const SizedBox(width: 10),
                                                _buildStatCard("Revenue", _formatRevenue(totalRevenue), const Color(0xFF22C55E), null),
                                            ],
                                        ),
                                        const SizedBox(height: 20),

                                        // 3. Product List
                                        if (products.isEmpty)
                                           const Center(child: Text("No products yet.", style: TextStyle(color: Colors.grey))),
                                        
                                        ...products.where((p) => 
                                            _searchQuery.isEmpty || 
                                            p.name.toLowerCase().contains(_searchQuery)
                                        ).map((p) => _buildProductCard(context, p)).toList(),
                                        
                                        const SizedBox(height: 80), // Space for FAB
                                    ],
                                )
                            )
                        ],
                    );
                },
            );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
      return Container(
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
                    onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()));
                    },
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28)
                )
              ],
            ),
      );
  }

  Widget _buildStatCard(String title, String value, Color color, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    double progress = product.targetSales > 0 ? (product.soldCount / product.targetSales) : 0.0;
    if (progress > 1.0) progress = 1.0;
    int percentage = (progress * 100).toInt();
    
    // Format target date if exists
    String targetDateText = "";
    if (product.targetDate != null) {
      DateTime targetDateTime = DateTime.fromMillisecondsSinceEpoch(product.targetDate!);
      targetDateText = DateFormat('dd MMM yyyy, HH:mm').format(targetDateTime);
    }

    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Image
                Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        image: product.imageUrl != null 
                            ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                            : null,
                    ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_formatRupiah(product.price), style: TextStyle(color: ucOrange, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text("${product.soldCount} Sold", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const SizedBox(height: 8),

                            // Target Goal
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    Text("Target: ${product.soldCount}/${product.targetSales}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text("$percentage%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: progress >= 1.0 ? Colors.green : ucOrange)),
                                ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    color: progress >= 1.0 ? Colors.green : ucOrange,
                                    minHeight: 8,
                                ),
                            ),
                            
                            // Target Date
                            if (targetDateText.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                    children: [
                                        Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text("Deadline: $targetDateText", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                    ],
                                ),
                            ],
                            const SizedBox(height: 12),
                            
                            // Edit Button
                            SizedBox(
                                width: double.infinity,
                                height: 35,
                                child: OutlinedButton(
                                    onPressed: () {
                                         Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductPage(productToEdit: product)));
                                    },
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.grey),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text("Edit Product", style: TextStyle(color: Colors.black)),
                                ),
                            )
                        ],
                    ),
                ),
            ],
        ),
    );
  }
}
