import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'models/product_model.dart';
import 'dart:html' as html; // Hanya untuk Web

class AddProductPage extends StatefulWidget {
  final ProductModel? productToEdit;
  const AddProductPage({super.key, this.productToEdit});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  String? _taxIncluded = 'Yes';
  bool _isUnlimitedStock = false;
  bool _isLoading = false;

  // --- KATEGORI SESUAI HOME PAGE ---
  String _selectedCategory = 'Goods';
  final List<String> _categories = ["Goods", "Arts", "Fundraising", "Fashion", "F&B"];

  // --- IMAGE UPLOAD VARIABLES ---
  XFile? _pickedFile;
  Uint8List? _webImageBytes;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      _nameController.text = widget.productToEdit!.name;
      _descController.text = widget.productToEdit!.description;
      _priceController.text = widget.productToEdit!.price;
      _stockController.text = widget.productToEdit!.stock.toString();
      _selectedCategory = widget.productToEdit!.category;
      _currentImageUrl = widget.productToEdit!.imageUrl;
      _isUnlimitedStock = widget.productToEdit!.stock >= 999999;
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
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
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
      if (image != null) setState(() => _pickedFile = image);
    }
  }

  Future<void> _handlePublish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama dan Harga wajib diisi!")));
      return;
    }

    setState(() => _isLoading = true);
    String? finalImageUrl = _currentImageUrl;

    try {
      // 1. Upload Foto jika ada yang baru dipilih
      if (_webImageBytes != null || _pickedFile != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = FirebaseStorage.instance.ref("products/$fileName.jpg");
        
        if (kIsWeb && _webImageBytes != null) {
          await ref.putData(_webImageBytes!);
        } else if (_pickedFile != null) {
          await ref.putFile(File(_pickedFile!.path));
        }
        finalImageUrl = await ref.getDownloadURL();
      }

      // 2. Siapkan Model
      final productData = ProductModel(
        id: widget.productToEdit?.id,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: _priceController.text.trim(),
        category: _selectedCategory,
        sellerId: user.uid,
        stock: _isUnlimitedStock ? 999999 : (int.tryParse(_stockController.text) ?? 0),
        imageUrl: finalImageUrl,
      );

      // 3. Simpan ke Firebase
      DatabaseReference dbRef = FirebaseDatabase.instance.ref("products");
      if (widget.productToEdit == null) {
        await dbRef.push().set(productData.toMap());
      } else {
        await dbRef.child(widget.productToEdit!.id!).update(productData.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        title: Text(widget.productToEdit == null ? "Add Product" : "Edit Product", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
      ? Center(child: CircularProgressIndicator(color: ucOrange))
      : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- UPLOAD PHOTO SECTION ---
            _buildSectionLabel("Product Photo"),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionLabel("Product Name"),
            _buildTextInput("iPhone 15", _nameController),
            const SizedBox(height: 16),

            _buildSectionLabel("Product Description"),
            _buildTextArea("Jelaskan detail produk...", _descController),
            const SizedBox(height: 24),

            const Text("Pricing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildCurrencyInput("999.000", _priceController),
            
            const SizedBox(height: 24),
            const Text("Inventory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTextInput("Stock Quantity", _stockController, enabled: !_isUnlimitedStock, isNumber: true),
            Row(
              children: [
                Switch(value: _isUnlimitedStock, activeColor: ucOrange, onChanged: (v) => setState(() => _isUnlimitedStock = v)),
                const Text("Unlimited Stock"),
              ],
            ),

            const SizedBox(height: 24),
            const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDropdown(),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: ucOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _handlePublish,
                child: Text(widget.productToEdit == null ? "Publish Product" : "Update Product", 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildImagePreview() {
    if (_webImageBytes != null) return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_webImageBytes!, fit: BoxFit.cover));
    if (_pickedFile != null && !kIsWeb) return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_pickedFile!.path), fit: BoxFit.cover));
    if (_currentImageUrl != null) return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_currentImageUrl!, fit: BoxFit.cover));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 40, color: ucOrange),
        const SizedBox(height: 8),
        const Text("Tap to add photo", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));

  Widget _buildTextInput(String hint, TextEditingController controller, {bool enabled = true, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
    );
  }

  Widget _buildCurrencyInput(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text("Rp", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: hint, border: InputBorder.none))),
        ],
      ),
    );
  }

  Widget _buildTextArea(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(controller: controller, maxLines: 3, decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.all(12))),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory,
          items: _categories.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
      ),
    );
  }
}