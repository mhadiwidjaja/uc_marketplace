import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  
  // Form State Variables
  String? _taxIncluded = 'Yes';
  bool _isUnlimitedStock = true;
  // ignore: unused_field
  String? _selectedCategory;
  // ignore: unused_field
  final String? _selectedStockStatus = 'In Stock';

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
        title: const Text(
          "Add Product",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Basic Info ---
            _buildSectionLabel("Product Name"),
            _buildTextInput("iPhone 15"),
            const SizedBox(height: 16),

            _buildSectionLabel("Product Description"),
            _buildTextArea(
              "The iPhone 15 delivers cutting-edge performance with the A16 Bionic chip...",
            ),
            const SizedBox(height: 24),

            // --- Pricing Section ---
            const Text("Pricing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _buildSectionLabel("Product Price"),
            _buildCurrencyInput("999.000"),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel("Target fundraising (Optional)"),
                      _buildCurrencyInput("500.000", prefix: "Rp"),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Expiration ---
            _buildSectionLabel("Expiration"),
            Row(
              children: [
                Expanded(child: _buildDatePicker("Start")),
                const SizedBox(width: 16),
                Expanded(child: _buildDatePicker("End")),
              ],
            ),
            const SizedBox(height: 24),

            // --- Inventory ---
            const Text("Inventory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel("Stock Quantity"),
                      _buildTextInput("Unlimited"),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel("Stock Status"),
                      _buildDropdown(["In Stock", "Out of Stock"], "In Stock"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Switch(
                  value: _isUnlimitedStock,
                  activeThumbColor: ucOrange,
                  onChanged: (val) => setState(() => _isUnlimitedStock = val),
                ),
                const Text("Unlimited", style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 24),

            // --- Image Upload ---
            const Text("Upload Product Image", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildSectionLabel("Product Image"),
            
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Placeholder for Main Image
                  const Icon(Icons.phone_iphone, size: 100, color: Colors.grey),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.image, size: 16, color: Colors.grey),
                      label: const Text("Browse", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.black),
                      label: const Text("Replace", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Thumbnails
            Row(
              children: [
                _buildThumbnail(),
                const SizedBox(width: 10),
                _buildThumbnail(),
                const SizedBox(width: 10),
                // Add Image Button
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    // FIXED: Changed to solid border because 'dashed' is not a valid constant in standard Flutter BorderStyle
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, color: ucOrange, size: 20),
                      Text("Add Image", style: TextStyle(fontSize: 8, color: ucOrange)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Categories ---
            const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _buildSectionLabel("Product Categories"),
            _buildDropdown(["Electronics", "Fashion", "Food"], "Select your product"),
            const SizedBox(height: 16),

            _buildSectionLabel("Product Tag"),
            _buildDropdown(["New Arrival", "Best Seller"], "Select your product"),
            const SizedBox(height: 30),

            // --- Publish Button ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ucOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Save logic
                  Navigator.pop(context);
                },
                child: const Text(
                  "Publish Product",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildTextInput(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCurrencyInput(String hint, {String prefix = "Rp"}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(prefix, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
          if (prefix == "Rp") const Icon(Icons.flag_circle, color: Colors.blue), // Dummy US flag icon
        ],
      ),
    );
  }

  Widget _buildTextArea(String hint) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        maxLines: 5,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onTap: () async {
          await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
        },
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (val) {},
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.phone_iphone, size: 30, color: Colors.grey),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 12, color: Colors.red),
          ),
        ),
      ],
    );
  }
}