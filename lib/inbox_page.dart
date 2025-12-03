import 'package:flutter/material.dart';

class InboxPage extends StatelessWidget {
  final bool showBackButton;

  const InboxPage({super.key, this.showBackButton = true});

  final Color ucOrange = const Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Inbox",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // Only show the back arrow if showBackButton is true
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null, // Hides the back button
        automaticallyImplyLeading: false, // Prevents default back button
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey[400], // Darker grey for the icon background
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.inbox, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 30),
            
            // Main Text
            const Text(
              "You haven't gotten any\nnotifications yet!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            
            // Subtitle Text
            Text(
              "We'll alert you when something\ncool happens.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}