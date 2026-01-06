import 'package:flutter/material.dart';

// This file is deprecated. Use order_management_page.dart and order_detail_page.dart instead.
// Keeping for backward compatibility with any existing navigation.

class ManageOrderPage extends StatelessWidget {
  const ManageOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new OrderManagementPage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const _DeprecatedPlaceholder()),
      );
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _DeprecatedPlaceholder extends StatelessWidget {
  const _DeprecatedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Orders"),
        backgroundColor: const Color(0xFFF39C12),
      ),
    body: const Center(
      child: Text("Please use the Orders button on Sell Page to access Order Management."),
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