import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'models/order_model.dart';
import 'order_detail_page.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Order Management", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("orders").orderByChild("sellerId").equalTo(currentUser!.uid).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<OrderModel> orders = [];
          int newOrdersCount = 0;
          
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = snapshot.data!.snapshot.value;
            if (data is Map) {
              data.forEach((k, v) {
                orders.add(OrderModel.fromMap(v, k.toString()));
              });
            }
          }

          // Sort by timestamp descending (newest first)
          orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Count new orders (last 7 days)
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
          newOrdersCount = orders.where((o) => o.timestamp > sevenDaysAgo).length;

          // Pagination
          int totalPages = (orders.length / _itemsPerPage).ceil();
          if (totalPages == 0) totalPages = 1;
          int startIndex = (_currentPage - 1) * _itemsPerPage;
          int endIndex = startIndex + _itemsPerPage;
          if (endIndex > orders.length) endIndex = orders.length;
          List<OrderModel> paginatedOrders = orders.isNotEmpty ? orders.sublist(startIndex, endIndex) : [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Total Orders Card
                _buildStatCard(
                  title: "Total Orders",
                  value: orders.length.toString(),
                  subtitle: "Last 7 days",
                  changePercent: 40.0,
                  isPositive: true,
                ),
                const SizedBox(height: 12),
                
                // New Orders Card
                _buildStatCard(
                  title: "New Orders",
                  value: newOrdersCount.toString(),
                  subtitle: "Last 7 days",
                  changePercent: 20.0,
                  isPositive: true,
                ),
                const SizedBox(height: 20),

                // Orders Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: ucOrange.withOpacity(0.2),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text("Order Id", style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text("See Detail", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),

                      // Order Rows
                      if (paginatedOrders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("No orders yet", style: TextStyle(color: Colors.grey)),
                        ),
                      ...paginatedOrders.map((order) => _buildOrderRow(order)).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Pagination
                if (orders.isNotEmpty) _buildPagination(totalPages),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required double changePercent,
    required bool isPositive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with title and more button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row with value/subtitle and percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${changePercent.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(OrderModel order) {
    // Determine display status - show Completed if receiveStatus is Complete
    String displayStatus = order.status;
    if (order.receiveStatus == 'Complete' || order.status.toLowerCase() == 'completed') {
      displayStatus = 'Completed';
    }
    
    Color statusColor;
    switch (displayStatus.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'delivered':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
      case 'canceled':
      case 'reject':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    String orderId = "#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(orderId, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(displayStatus.toLowerCase(), style: TextStyle(color: statusColor, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)));
              },
              child: Text("See detail", style: TextStyle(color: ucOrange, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    List<Widget> pageButtons = [];
    
    for (int i = 1; i <= (totalPages > 5 ? 5 : totalPages); i++) {
      pageButtons.add(_buildPageButton(i, i == _currentPage));
    }
    
    if (totalPages > 5) {
      pageButtons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(".....", style: TextStyle(fontWeight: FontWeight.bold)),
      ));
      pageButtons.add(_buildPageButton(totalPages, totalPages == _currentPage));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: pageButtons,
    );
  }

  Widget _buildPageButton(int page, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentPage = page;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? ucOrange : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? ucOrange : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            "$page",
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
