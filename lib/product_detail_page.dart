import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/product_model.dart';
import 'models/cart_model.dart';
import 'models/review_model.dart';
import 'add_product_page.dart';
import 'chat_room_page.dart'; // Import halaman chat
import 'write_review_page.dart';


class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  final Color ucOrange = const Color(0xFFF39C12);

  // FUNGSI HELPER FORMAT RUPIAH
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

  // Fungsi Navigasi ke Chat
  void _navigateToChat(BuildContext context, String sellerName) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login untuk memulai chat")),
      );
      return;
    }

    // Jangan biarkan user chat diri sendiri
    if (currentUser.uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ini adalah toko Anda sendiri.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          receiverId: product.sellerId,
          receiverName: sellerName,
        ),
      ),
    );
  }

  // Fungsi Tambah ke Keranjang
  Future<void> _addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login untuk menambah keranjang")),
      );
      return;
    }

    if (user.uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda tidak bisa membeli produk sendiri!"), backgroundColor: Colors.red),
      );
      return;
    }

    DatabaseReference cartRef = FirebaseDatabase.instance.ref("carts/${user.uid}/${product.id}");

    try {
      final snapshot = await cartRef.get();
      int currentQtyInCart = 0;
      
      if (snapshot.exists) {
        currentQtyInCart = (snapshot.value as Map)['quantity'] ?? 0;
      }

      if (currentQtyInCart >= product.stock && product.stock != 999999) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Stok tidak mencukupi!"), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      if (snapshot.exists) {
        await cartRef.update({'quantity': currentQtyInCart + 1});
      } else {
        CartItemModel newItem = CartItemModel(
          productId: product.id!,
          productName: product.name,
          price: product.price,
          quantity: 1,
          sellerId: product.sellerId,
        );
        await cartRef.set(newItem.toMap());
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil masuk keranjang"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error cart: $e");
    }
  }

  // Fungsi Hapus Produk (Seller Only)
  Future<void> _deleteProduct(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Hapus Produk"),
        content: const Text("Tindakan ini permanen. Hapus produk ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Hapus", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseDatabase.instance.ref("products/${product.id}").remove();
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Produk telah dihapus")),
          );
        }
      } catch (e) {
        debugPrint("Error delete: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isSeller = currentUser?.uid == product.sellerId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ucOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Detail Produk", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: isSeller ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductPage(productToEdit: product))),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteProduct(context),
          ),
        ] : [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            Container(
              height: 350,
              width: double.infinity,
              color: Colors.grey[200],
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.inventory_2, size: 100, color: Colors.grey),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatRupiah(product.price), 
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ucOrange)),
                  const SizedBox(height: 10),
                  Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: FirebaseDatabase.instance.ref("products/${product.id}").onValue,
                    builder: (context, snapshot) {
                        double rating = product.rating;
                        int reviewCount = product.reviewCount;
                        
                        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                            try {
                                final minMap = snapshot.data!.snapshot.value as Map;
                                rating = ((minMap['rating'] ?? 0) as num).toDouble();
                                reviewCount = (minMap['reviewCount'] ?? 0) as int;
                            } catch (e) { /* ignore */ }
                        }
                        
                        return Row(
                           children: [
                              Icon(Icons.star, color: ucOrange, size: 20),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 8),
                              Text("- $reviewCount Reviews", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                           ],
                        );
                    }
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  
                  // SELLER INFO DENGAN TOMBOL CHAT
                  const Text("Informasi Penjual", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder(
                    stream: FirebaseDatabase.instance.ref("users/${product.sellerId}").onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                        final userData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
                        final String sellerName = userData['username'] ?? "Penjual";

                        return Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: ucOrange,
                              backgroundImage: userData['profileImageUrl'] != null 
                                ? NetworkImage(userData['profileImageUrl']) 
                                : null,
                              child: userData['profileImageUrl'] == null 
                                ? const Icon(Icons.person, color: Colors.white) 
                                : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(sellerName, style: const TextStyle(fontSize: 15)),
                            ),
                            // TOMBOL CHAT DI SEBELAH KANAN
                            IconButton(
                              onPressed: () => _navigateToChat(context, sellerName),
                              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFF39C12)),
                              tooltip: "Chat Penjual",
                            ),
                          ],
                        );
                      }
                      return const Text("Memuat...");
                    },
                  ),
                  const Divider(height: 30),
                  
                  const Text("Deskripsi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(product.description, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)),
                  
                  const SizedBox(height: 20),
                  _buildInfoBox("Kategori", product.category),
                  _buildInfoBox("Stok", product.stock >= 999999 ? "Unlimited" : "${product.stock} pcs"),
                  
                  // REVIEW SECTION
                  _buildReviewsSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
        ),
        child: ElevatedButton(
          onPressed: (isSeller || (product.stock <= 0 && product.stock != 999999)) ? null : () => _addToCart(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSeller ? Colors.grey : ucOrange,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          child: Text(
            isSeller ? "Ini Jualan Anda" : (product.stock <= 0 ? "Stok Habis" : "Tambah ke Keranjang"),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Divider(),
        const Text("Customer reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        StreamBuilder(
          stream: FirebaseDatabase.instance.ref("reviews/${product.id}").onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }

            List<ReviewModel> reviews = [];
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
               final data = snapshot.data!.snapshot.value;
               if (data is Map) {
                 data.forEach((key, value) {
                   reviews.add(ReviewModel.fromMap(value, key.toString()));
                 });
               } else if (data is List) {
                  // Handle potential list structure if keys are integers
                  for(var i=0; i<data.length; i++) {
                     if (data[i] != null) reviews.add(ReviewModel.fromMap(data[i], i.toString()));
                  }
               }
               
               reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            }

            // Calculate Summary
            double avgRating = 0;
            if (reviews.isNotEmpty) {
               avgRating = reviews.map((e) => e.rating).reduce((a, b) => a + b) / reviews.length;
            }
            Map<int, int> ratingDist = {5:0, 4:0, 3:0, 2:0, 1:0};
            for(var r in reviews) {
               ratingDist[r.rating] = (ratingDist[r.rating] ?? 0) + 1;
            }

            return Column(
              children: [
                 // Summary Section
                 if (reviews.isNotEmpty)
                 Row(
                   crossAxisAlignment: CrossAxisAlignment.center,
                   children: [
                     Column(
                       children: [
                         Text("${avgRating.toStringAsFixed(1)}", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                         Row(children: List.generate(5, (i) => Icon(i < avgRating.round() ? Icons.star : Icons.star_border, color: ucOrange, size: 16))),
                         Text("${reviews.length} Reviews", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                       ],
                     ),
                     const SizedBox(width: 20),
                     // Bars
                     Expanded(
                       child: Column(
                         children: [5,4,3,2,1].map((star) {
                           int count = ratingDist[star] ?? 0;
                           double pct = reviews.isEmpty ? 0 : count / reviews.length;
                           return Row(
                             children: [
                               Text("$star", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                               const Icon(Icons.star, size: 10, color: Colors.grey),
                               const SizedBox(width: 5),
                               Expanded(
                                 child: LinearProgressIndicator(
                                   value: pct,
                                   backgroundColor: Colors.grey[200],
                                   color: ucOrange,
                                   minHeight: 5,
                                   borderRadius: BorderRadius.circular(5),
                                 )
                               ),
                               const SizedBox(width: 5),
                               Text("($count)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                             ],
                           );
                         }).toList(),
                       ),
                     )
                   ],
                 ),
                 
                 const SizedBox(height: 20),
                 _buildWriteReviewButton(context),
                 const SizedBox(height: 20),
                 
                 if (reviews.isEmpty)
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 20),
                     child: Text("No reviews yet. Be the first to review!", style: TextStyle(color: Colors.grey)),
                   ),

                 // Reviews List
                 ...reviews.map((review) => _buildReviewItem(review)).toList(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWriteReviewButton(BuildContext context) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return const SizedBox.shrink();

      return StreamBuilder(
        stream: FirebaseDatabase.instance.ref("orders")
            .orderByChild("buyerId")
            .equalTo(user.uid)
            .onValue,
        builder: (context, snapshot) {
            bool canReview = false;
            // Check if user already reviewed? Logic:
            // For now, allow multiple reviews or assume handled elsewhere.
            
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                final ordersValue = snapshot.data!.snapshot.value;
                Map<dynamic, dynamic> orders = {};
                if (ordersValue is Map) {
                   orders = ordersValue;
                } else if (ordersValue is List) {
                   // If list (rare for push IDs but possible if using sequential IDs)
                   for (int i=0; i<ordersValue.length; i++) {
                      if (ordersValue[i] != null) orders[i] = ordersValue[i];
                   }
                }

                for (var v in orders.values) {
                    final order = v is Map ? v : {};
                     // Relaxed check: 'Delivered' or 'Completed'
                     // Also checking 'Pending' just for easy testing if you haven't implemented full order flow
                     String status = order['status'] ?? '';
                     if (status == 'Delivered' || status == 'Completed' || status == 'Selesai' || status == 'Pending') { 
                        if (order['items'] != null && order['items'] is List) {
                            for(var item in order['items']) {
                                if (item is Map && item['productId'] == product.id) canReview = true;
                            }
                        }
                     }
                }
            }
            
            if (!canReview) return const SizedBox.shrink();

            return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => WriteReviewPage(product: product)));
                    }, 
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ucOrange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: Text("Write a Review", style: TextStyle(color: ucOrange))
                ),
            );
        },
      );
  }

  Widget _buildReviewItem(ReviewModel review) {
      return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade100),
              borderRadius: BorderRadius.circular(8)
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                      children: [
                          CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: review.userAvatarUrl != null ? NetworkImage(review.userAvatarUrl!) : null,
                              child: review.userAvatarUrl == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(review.isAnonymous ? "Anonymous" : review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: ucOrange, size: 12))),
                                ],
                            ),
                          ),
                          Text(DateFormat("dd MMM yyyy").format(DateTime.fromMillisecondsSinceEpoch(review.timestamp)), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                  ),
                  const SizedBox(height: 8),
                  if (review.title.isNotEmpty) Text(review.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(review.reviewText, style: const TextStyle(fontSize: 13)),
                  if (review.imageUrl != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(review.imageUrl!, height: 100, width: 100, fit: BoxFit.cover),
                      )
                  ]
              ],
          ),
      );
  }
}