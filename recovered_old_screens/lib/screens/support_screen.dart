import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'support',
      'text': 'আসসালামু আলাইকুম! শপ সেলার আইও সাপোর্ট টিমে আপনাকে স্বাগতম। আপনার কী সমস্যা হচ্ছে নিচে থেকে বাটন চাপুন অথবা বিস্তারিত লিখে পাঠান, আমরা দ্রুত সমাধান দিচ্ছি।'
    }
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
    });
    _messageController.clear();

    // অটো রিপ্লাই বা সিস্টেমের কনফার্মেশন মেসেজ
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'support',
            'text': 'আপনার বার্তাটি আমাদের সাপোর্ট টিমে সফলভাবে পৌঁছে গেছে। আমরা খুব শীঘ্রই আপনার সাথে পার্সোনালভাবে যোগাযোগ করব।'
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('লাইভ সাপোর্ট ও চ্যাট'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          // কুইক প্রবলেম বাটন (Quick Problem Buttons)
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('অ্যাপ ডাউনলোড সমস্যা'),
                    backgroundColor: Colors.deepOrange[50],
                    labelStyle: const TextStyle(color: Colors.deepOrange),
                    onPressed: () => _sendMessage('আমার অ্যাপ ডাউনলোড করতে সমস্যা হচ্ছে।'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('লেনদেন বা পেমেন্ট সমস্যা'),
                    backgroundColor: Colors.deepOrange[50],
                    labelStyle: const TextStyle(color: Colors.deepOrange),
                    onPressed: () => _sendMessage('আমার লেনদেন বা পেমেন্ট নিয়ে সমস্যা আছে।'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('অ্যাকাউন্ট সমস্যা'),
                    backgroundColor: Colors.deepOrange[50],
                    labelStyle: const TextStyle(color: Colors.deepOrange),
                    onPressed: () => _sendMessage('আমার অ্যাকাউন্ট সংক্রান্ত সাহায্য লাগবে।'),
                  ),
                ],
              ),
            ),
          ),

          // চ্যাট মেসেজ লিস্ট
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.deepOrange : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // মেসেজ লেখার ইনপুট বক্স
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "আপনার সমস্যা এখানে বিস্তারিত লিখুন...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}