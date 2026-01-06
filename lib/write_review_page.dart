import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/product_model.dart';
import 'models/review_model.dart';
import 'dart:html' as html; // For web image upload

class WriteReviewPage extends StatefulWidget {
  final ProductModel product;

  const WriteReviewPage({super.key, required this.product});

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 0;
  bool _isAnonymous = false;
  File? _selectedImage;
  XFile? _pickedFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Web: Use dart:html for stable image upload
      final html.FileUploadInputElement input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      input.onChange.listen((event) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            _webImageBytes = reader.result as Uint8List;
            _pickedFile = XFile(file.name);
          });
        });
      });
    } else {
      // Mobile: Standard image picker with compression
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _pickedFile = image;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a score (stars)")),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title")),
      );
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a review")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // 1. Upload Image if exists - Store as base64 for web to avoid CORS
      String? imageUrl;
      if (_webImageBytes != null || _selectedImage != null) {
        if (kIsWeb && _webImageBytes != null) {
          // For web: Store image as base64 data URL to avoid CORS issues
          String base64Image = base64Encode(_webImageBytes!);
          imageUrl = 'data:image/jpeg;base64,$base64Image';
        } else if (_selectedImage != null) {
          // For mobile: Use Firebase Storage
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('review_images/${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          imageUrl = await storageRef.getDownloadURL();
        }
      }

      // 2. Fetch User Info (if not anonymous)
      String userName = "Anonymous";
      String? userAvatar;

      if (!_isAnonymous) {
        final userSnapshot =
            await FirebaseDatabase.instance.ref("users/${user.uid}").get();
        if (userSnapshot.exists && userSnapshot.value != null) {
            final userData = userSnapshot.value as Map;
            userName = userData['username'] ?? "User";
            userAvatar = userData['profileImageUrl'];
        }
      }

      // 3. Create Review Object
      DatabaseReference reviewRef = FirebaseDatabase.instance.ref("reviews/${widget.product.id}").push();
      
      ReviewModel newReview = ReviewModel(
        id: reviewRef.key!,
        productId: widget.product.id!,
        userId: user.uid,
        userName: userName,
        userAvatarUrl: userAvatar,
        rating: _selectedRating,
        title: _titleController.text.trim(),
        reviewText: _reviewController.text.trim(),
        imageUrl: imageUrl,
        isAnonymous: _isAnonymous,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await reviewRef.set(newReview.toMap());

      // 4. Update Product Average Rating
      final productRef = FirebaseDatabase.instance.ref("products/${widget.product.id}");
      
      await productRef.runTransaction((Object? post) {
        if (post == null) {
          return Transaction.success(post);
        }
        
        Map<String, dynamic> p = Map<String, dynamic>.from(post as Map);
        
        int currentCount = (p['reviewCount'] ?? 0) as int;
        double currentRating = ((p['rating'] ?? 0) as num).toDouble();
        
        double newRating = ((currentRating * currentCount) + _selectedRating) / (currentCount + 1);
        
        p['reviewCount'] = currentCount + 1;
        p['rating'] = newRating;
        
        return Transaction.success(p);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review posted successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Write Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: ucOrange,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: ucOrange),
                const SizedBox(height: 15),
                const Text("Posting review...", style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.product.imageUrl != null
                            ? Image.network(widget.product.imageUrl!, width: 60, height: 60, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image)))
                            : Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(widget.product.price, style: TextStyle(color: ucOrange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Rating Section
                const Text("Your Rating", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: ucOrange,
                            size: 44,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title Input
                const Text("Review Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: "Summarize your review",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ucOrange)),
                    fillColor: Colors.grey[50],
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Review Input
                const Text("Your Review", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Share your experience with this product...",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ucOrange)),
                    fillColor: Colors.grey[50],
                    filled: true,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),

                // Add Photo
                const Text("Add Photo (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _webImageBytes != null 
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_webImageBytes!, fit: BoxFit.cover, width: double.infinity, height: 120),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() { _webImageBytes = null; _pickedFile = null; }),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _selectedImage != null 
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity, height: 120),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() { _selectedImage = null; _pickedFile = null; }),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Icon(Icons.add_photo_alternate_outlined, color: ucOrange, size: 36),
                                    const SizedBox(height: 8),
                                    Text("Tap to add photo", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 20),

                // Anonymous Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Post anonymously", style: TextStyle(fontSize: 15)),
                      Switch(
                        value: _isAnonymous,
                        onChanged: (val) => setState(() => _isAnonymous = val),
                        activeColor: ucOrange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ucOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Post Review", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
