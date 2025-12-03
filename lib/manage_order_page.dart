import 'package:flutter/material.dart';

class ManageOrderPage extends StatelessWidget {
  const ManageOrderPage({super.key});

  final Color ucOrange = const Color(0xFFF39C12);
  final Color greenColor = const Color(0xFF2ECC71); // Green for status/contact

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
          "Manage Order",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Order Header Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Create Time: 25/12/2027, 15:59:00",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order No #ORD0001",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tracking number: IW3475453455",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "Delivered",
                    style: TextStyle(
                      color: greenColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),

              // 2. Customer Info
              const Text("Customer", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 40, color: Colors.teal),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mathew Fernando", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("(+62)7642873462", style: TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.chat_bubble_outline, size: 16, color: greenColor),
                    label: Text("Contact", style: TextStyle(color: greenColor)),
                  )
                ],
              ),
              const Divider(height: 30),

              // 3. Order Details (Items)
              const Text("Order Details", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text("3 items", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              
              _buildItemRow("Item name", "ProMax", "Gray"),
              _buildItemRow("Item name", "ProMax", "Gray"),
              _buildItemRow("Item name", "ProMax", "Gray"),

              const Divider(height: 30),

              // 4. Order Information (Shipping, Payment)
              const Text("Order information", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildInfoRow("Shipping Address:", "3 Newbridge Court, Chino Hills,\nCA 91709, United States"),
              const SizedBox(height: 10),
              _buildPaymentRow(),
              const SizedBox(height: 10),
              _buildInfoRow("Delivery method:", "FedEx, 3 days, Reguler"),

              const Divider(height: 30),

              // 5. Financial Breakdown
              _buildFinancialRow("Total Amount:", "Rp 300.000"),
              _buildFinancialRow("Shipping Fee:", "Rp 20.000"),
              _buildFinancialRow("Taxes:", "Rp 3.000"),
              _buildFinancialRow("Application service fee:", "Rp 3.000"),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("You Earn:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Rp 250.000", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildItemRow(String name, String type, String color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image Placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              // In real app, use: image: DecorationImage(image: NetworkImage(...))
            ),
            child: const Icon(Icons.phone_iphone, color: Colors.grey), 
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  ],
                ),
                Text("Type: $type", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text("Color: $color", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Units : 1", style: TextStyle(fontWeight: FontWeight.w500)),
                    Text("Rp 25.000", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildPaymentRow() {
    return Row(
      children: [
        const SizedBox(
          width: 120,
          child: Text("Payment method:", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        // Mastercard Icon Simulation
        Container(
          height: 20,
          width: 30,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.orangeAccent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(child: Icon(Icons.circle, color: Colors.red, size: 12)), 
        ),
        const Text("**** **** **** 3947", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
      ],
    );
  }

  Widget _buildFinancialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }
}