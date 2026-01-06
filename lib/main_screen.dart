import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_page.dart';
import 'account_page.dart';
import 'inbox_page.dart';
import 'sell_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final Color ucOrange = const Color(0xFFF39C12);
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  final List<Widget> _pages = [
    const HomePage(),
    const SellPage(),
    const InboxPage(showBackButton: false), 
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: ucOrange,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Sell'),
          
          // TAB INBOX DENGAN BADGE NOTIFIKASI
          BottomNavigationBarItem(
            icon: StreamBuilder(
              stream: FirebaseDatabase.instance.ref("orders").orderByChild("buyerId").equalTo(uid).onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                int notificationCount = 0;
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> orders = snapshot.data!.snapshot.value as Map;
                  // Menghitung order yang isRead == false (Pesan baru/status baru)
                  orders.forEach((key, value) {
                    if (value['isRead'] == false) notificationCount++;
                  });
                }
                return Stack(
                  children: [
                    const Icon(Icons.mail_outline),
                    if (notificationCount > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                          constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                          child: Text('$notificationCount', style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                );
              },
            ),
            activeIcon: const Icon(Icons.mail),
            label: 'Order',
          ),
          
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}