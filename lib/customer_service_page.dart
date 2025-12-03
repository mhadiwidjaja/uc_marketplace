import 'package:flutter/material.dart';

class CustomerServicePage extends StatelessWidget {
  const CustomerServicePage({super.key});

  final Color ucOrange = const Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        backgroundColor: ucOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Customer Service",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Date Label
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("Today", style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Messages
                _buildReceivedMessage("Hello, good morning."),
                _buildReceivedMessage("I am a Customer Service, is there anything I can help you with?"),
                _buildTimeLabel("10:41 pm", isLeft: true),
                
                const SizedBox(height: 15),

                _buildSentMessage("Hi, I'm having problems with my order & payment."),
                _buildSentMessage("Can you help me?"),
                _buildTimeLabel("10:50 pm", isLeft: false),

                const SizedBox(height: 15),

                _buildReceivedMessage("Of course..."),
                _buildReceivedMessage("Can you tell me the problem you are having? so I can help solve it"),
                _buildTimeLabel("10:51 pm", isLeft: true),
              ],
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Write your message...",
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Icon(Icons.image_outlined, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: ucOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Received Messages (Grey, Left aligned)
  Widget _buildReceivedMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5, right: 60), // Space on right to show it's left-aligned
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0), // Light grey
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }

  // Helper for Sent Messages (Black, Right aligned)
  Widget _buildSentMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5, left: 60),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F), // Dark grey/black
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // Helper for Time Labels
  Widget _buildTimeLabel(String time, {required bool isLeft}) {
    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          time,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }
}