import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/product_model.dart'; // Pastikan file model sudah benar

class AddProductPage extends StatefulWidget {
  final ProductModel? productToEdit; // Parameter untuk mode Edit
  const AddProductPage({super.key, this.productToEdit});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  
  // Controllers untuk mengambil input
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  // Form State Variables
  String? _taxIncluded = 'Yes';
  bool _isUnlimitedStock = true;
  String _selectedCategory = 'Electronics';

  @override
  void initState() {
    super.initState();
    // Jika dalam mode Edit, isi field dengan data lama dari Firebase
    if (widget.productToEdit != null) {
      _nameController.text = widget.productToEdit!.name;
      _descController.text = widget.productToEdit!.description;
      _priceController.text = widget.productToEdit!.price;
      _stockController.text = widget.productToEdit!.stock == 999999 
          ? "" 
          : widget.productToEdit!.stock.toString();
      _selectedCategory = widget.productToEdit!.category;
      _isUnlimitedStock = widget.productToEdit!.stock == 999999;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // Fungsi Utama: Publish Baru atau Update Jualan
  Future<void> _publishProduct() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda harus login terlebih dahulu!")),
      );
      return;
    }

    // Validasi Input Sederhana
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama dan Harga wajib diisi!")),
      );
      return;
    }

    // Menyiapkan data produk berdasarkan model
    final productData = ProductModel(
      id: widget.productToEdit?.id, // Gunakan ID lama jika edit
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: _priceController.text.trim(),
      category: _selectedCategory,
      sellerId: user.uid, // MENGHUBUNGKAN DENGAN USER ID
      stock: _isUnlimitedStock ? 999999 : (int.tryParse(_stockController.text) ?? 0),
    );

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("products");

      if (widget.productToEdit == null) {
        // LOGIKA PUBLISH BARU: Gunakan push() untuk generate ID otomatis
        await ref.push().set(productData.toMap());
      } else {
        // LOGIKA UPDATE: Update data berdasarkan ID produk yang sudah ada
        await ref.child(widget.productToEdit!.id!).update(productData.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productToEdit == null 
                ? "Produk berhasil dipublikasikan!" 
                : "Produk berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.productToEdit == null ? "Add Product" : "Edit Product",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("Product Name"),
            _buildTextInput("Contoh: iPhone 15", _nameController),
            const SizedBox(height: 16),

            _buildSectionLabel("Product Description"),
            _buildTextArea("Jelaskan detail produk Anda...", _descController),
            const SizedBox(height: 24),

            const Text("Pricing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _buildSectionLabel("Product Price"),
            _buildCurrencyInput("Contoh: 999.000", _priceController),
            const SizedBox(height: 16),

            _buildSectionLabel("Tax Included"),
            Row(
              children: [
                Radio<String>(
                  value: 'Yes',
                  groupValue: _taxIncluded,
                  activeColor: ucOrange,
                  onChanged: (val) => setState(() => _taxIncluded = val),
                ),
                const Text("Yes"),
                Radio<String>(
                  value: 'No',
                  groupValue: _taxIncluded,
                  activeColor: ucOrange,
                  onChanged: (val) => setState(() => _taxIncluded = val),
                ),
                const Text("No"),
              ],
            ),
            const SizedBox(height: 24),

            const Text("Inventory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _buildSectionLabel("Stock Quantity"),
            _buildTextInput(
              _isUnlimitedStock ? "Unlimited" : "Masukkan jumlah stok", 
              _stockController, 
              enabled: !_isUnlimitedStock,
              isNumber: true,
            ),
            
            Row(
              children: [
                Switch(
                  value: _isUnlimitedStock,
                  activeThumbColor: ucOrange,
                  activeColor: ucOrange.withOpacity(0.3),
                  onChanged: (val) => setState(() => _isUnlimitedStock = val),
                ),
                const Text("Unlimited Stock", style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 24),

            const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDropdown(["Electronics", "Fashion", "Food"], "Pilih Kategori"),
            const SizedBox(height: 30),

            // Tombol Publish / Update
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ucOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _publishProduct,
                child: Text(
                  widget.productToEdit == null ? "Publish Product" : "Update Product",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildTextInput(String hint, TextEditingController controller, {bool enabled = true, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCurrencyInput(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text("Rp", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: hint, border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.all(12)),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String hint) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(_selectedCategory) ? _selectedCategory : items.first,
          items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
      ),
    );
  }
}