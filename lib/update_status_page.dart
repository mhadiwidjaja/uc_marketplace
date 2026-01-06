import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models/order_model.dart';
import 'models/notification_model.dart';

class UpdateStatusPage extends StatefulWidget {
  final OrderModel order;

  const UpdateStatusPage({super.key, required this.order});

  @override
  State<UpdateStatusPage> createState() => _UpdateStatusPageState();
}

class _UpdateStatusPageState extends State<UpdateStatusPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  
  late String _deliveryStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _deliveryStatus = widget.order.status;
  }

  Future<void> _saveStatus() async {
    setState(() => _isLoading = true);

    try {
      final String previousDeliveryStatus = widget.order.status;

      await FirebaseDatabase.instance.ref("orders/${widget.order.id}").update({
        'status': _deliveryStatus,
      });

      // Send receive confirmation notification when status changes to Delivered
      if (_deliveryStatus == 'Delivered' && previousDeliveryStatus != 'Delivered') {
        await _sendReceiveConfirmationNotification();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Status updated successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
        Navigator.pop(context); // Go back to order list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReceiveConfirmationNotification() async {
    final order = widget.order;
    
    // Create notification items from order items
    List<NotificationItem> notifItems = order.items.map((item) => NotificationItem(
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
    )).toList();

    // Create notification model
    final notificationRef = FirebaseDatabase.instance.ref("notifications").push();
    final notification = NotificationModel(
      id: notificationRef.key!,
      userId: order.buyerId,
      type: 'receive_confirmation',
      orderId: order.id,
      title: 'Konfirmasi Penerimaan Barang',
      message: 'Pesanan ${order.productName} telah dikirim. Silakan konfirmasi jika barang sudah diterima.',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isRead: false,
      isConfirmed: false,
      items: notifItems,
    );

    await notificationRef.set(notification.toMap());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ucOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Update Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Status Section
            const Text("Stattus Pengiriman", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildStatusOption(
              icon: Icons.local_shipping_outlined,
              label: "Delivered",
              value: "Delivered",
              groupValue: _deliveryStatus,
              onChanged: (v) => setState(() => _deliveryStatus = v!),
              color: Colors.green,
            ),
            _buildStatusOption(
              icon: Icons.local_shipping_outlined,
              label: "Pending",
              value: "Pending",
              groupValue: _deliveryStatus,
              onChanged: (v) => setState(() => _deliveryStatus = v!),
              color: Colors.orange,
            ),
            _buildStatusOption(
              icon: Icons.local_shipping_outlined,
              label: "Cancelled",
              value: "Cancelled",
              groupValue: _deliveryStatus,
              onChanged: (v) => setState(() => _deliveryStatus = v!),
              color: Colors.red,
            ),

            const SizedBox(height: 20),
            
            // Info about receive status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Status penerimaan akan berubah otomatis saat pelanggan mengkonfirmasi penerimaan barang.",
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ucOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _isLoading ? null : _saveStatus,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required IconData icon,
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required Color color,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: ucOrange,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
