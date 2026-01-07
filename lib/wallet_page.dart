import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final Color ucOrange = const Color(0xFFF39C12);
  String _selectedFilter = "All"; // Opsi: All, 1 Week, 1 Month, Custom
  DateTime? _customDate;

  String _formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // --- LOGIKA FILTER WAKTU ---
  bool _shouldShowItem(int timestamp) {
    DateTime itemDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();

    if (_selectedFilter == "1 Week") {
      return itemDate.isAfter(now.subtract(const Duration(days: 7)));
    } else if (_selectedFilter == "1 Month") {
      return itemDate.isAfter(DateTime(now.year, now.month - 1, now.day));
    } else if (_selectedFilter == "Custom" && _customDate != null) {
      return itemDate.day == _customDate!.day &&
             itemDate.month == _customDate!.month &&
             itemDate.year == _customDate!.year;
    }
    return true; // "All"
  }

  // --- FUNGSI TOP UP ---
  Future<void> _handleTopUp(String uid) async {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Top Up Saldo"),
        content: TextField(
          controller: amountController, 
          keyboardType: TextInputType.number, 
          decoration: const InputDecoration(hintText: "Masukkan nominal", prefixText: "Rp ")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ucOrange),
            onPressed: () async {
              int? amount = int.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;

              // Update Saldo
              await FirebaseDatabase.instance.ref("users/$uid/walletBalance").runTransaction((Object? curr) {
                return Transaction.success(((curr as int?) ?? 0) + amount);
              });

              // Catat Riwayat
              await FirebaseDatabase.instance.ref("wallet_history/$uid").push().set({
                'type': 'income',
                'title': 'Top Up Saldo',
                'amount': amount,
                'timestamp': DateTime.now().millisecondsSinceEpoch
              });

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Isi Saldo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI WITHDRAW ---
  Future<void> _handleWithdraw(String uid, int balance) async {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tarik Saldo"),
        content: TextField(
          controller: amountController, 
          keyboardType: TextInputType.number, 
          decoration: const InputDecoration(hintText: "Masukkan nominal", prefixText: "Rp ")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              int? amount = int.tryParse(amountController.text);
              if (amount == null || amount <= 0 || amount > balance) return;

              // Potong Saldo
              await FirebaseDatabase.instance.ref("users/$uid/walletBalance").runTransaction((Object? curr) {
                return Transaction.success(((curr as int?) ?? 0) - amount);
              });

              // Catat Riwayat
              await FirebaseDatabase.instance.ref("wallet_history/$uid").push().set({
                'type': 'withdraw',
                'title': 'Penarikan Saldo',
                'amount': amount,
                'timestamp': DateTime.now().millisecondsSinceEpoch
              });

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Tarik Uang", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("UC Wallet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: ucOrange, centerTitle: true, elevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("users/$uid").onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          int balance = 0;
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = snapshot.data!.snapshot.value as Map;
            balance = data['walletBalance'] ?? 0;
          }

          return Column(
            children: [
              // 1. Saldo Card Premium
              _buildBalanceCard(balance),

              // 2. Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(onTap: () => _handleTopUp(uid!), child: _walletAction(Icons.add_circle_outline, "Top Up", Colors.green)),
                    GestureDetector(onTap: () => _handleWithdraw(uid!, balance), child: _walletAction(Icons.account_balance_wallet_outlined, "Withdraw", Colors.red)),
                    _walletAction(Icons.history, "History", Colors.blue),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 3. RIWAYAT TRANSAKSI (MENGISI RUANG KOSONG)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          _buildFilterDropdown(), // Tombol Filter
                        ],
                      ),
                      // Tampilkan pemilih tanggal jika filter Custom dipilih
                      if (_selectedFilter == "Custom") 
                        _buildCustomDatePicker(),
                      const SizedBox(height: 15),
                      Expanded(
                        child: _buildHistoryList(uid!),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- KOMPONEN UI ---

  Widget _buildBalanceCard(int balance) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(25), margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [ucOrange, const Color(0xFFE67E22)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: ucOrange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Saldo", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Text(_formatRupiah(balance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("UC Marketplace Digital Wallet", style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButton<String>(
      value: _selectedFilter,
      underline: const SizedBox(),
      icon: Icon(Icons.filter_list, color: ucOrange, size: 20),
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
      items: ["All", "1 Week", "1 Month", "Custom"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) => setState(() {
        _selectedFilter = val!;
        if (val != "Custom") _customDate = null;
      }),
    );
  }

  Widget _buildCustomDatePicker() {
    return TextButton.icon(
      onPressed: () async {
        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
        if (date != null) setState(() => _customDate = date);
      },
      icon: const Icon(Icons.calendar_month, size: 16),
      label: Text(_customDate == null ? "Pilih Tanggal" : DateFormat('dd MMM yyyy').format(_customDate!)),
    );
  }

  Widget _buildHistoryList(String uid) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref("wallet_history/$uid").onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> historySnapshot) {
        if (!historySnapshot.hasData || historySnapshot.data!.snapshot.value == null) return _buildEmptyHistory();

        Map<dynamic, dynamic> data = historySnapshot.data!.snapshot.value as Map;
        // Filter data berdasarkan pilihan
        List<dynamic> historyList = data.values.where((item) => _shouldShowItem(item['timestamp'])).toList();
        
        // Urutkan dari terbaru
        historyList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        if (historyList.isEmpty) return _buildEmptyHistory();

        return ListView.builder(
          itemCount: historyList.length,
          itemBuilder: (context, index) => _buildTransactionItem(historyList[index]),
        );
      },
    );
  }

  Widget _buildTransactionItem(dynamic item) {
    bool isIncome = item['type'] == 'income';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.grey.shade100)
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.green : Colors.red, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(item['timestamp'])), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text("${isIncome ? '+' : '-'} ${_formatRupiah(item['amount'])}", 
            style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red, fontSize: 14)
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("Belum ada transaksi", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _walletAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15), 
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), 
          child: Icon(icon, color: color, size: 28)
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}