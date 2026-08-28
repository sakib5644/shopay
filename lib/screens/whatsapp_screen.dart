import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappScreen extends StatelessWidget {
  const WhatsappScreen({super.key});

  // টেস্ট করার জন্য হোয়াটসঅ্যাপ গ্রুপের লিংকটি এখানে বসিয়ে দেওয়া হলো
  final String whatsappGroupUrl =
      'https://chat.whatsapp.com/H9lmlAJRA5G3B8cMWc2U70?s=cl&p=a&ilr=1';

  Future<void> _openWhatsAppGroup(BuildContext context) async {
    final Uri url = Uri.parse(whatsappGroupUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('হোয়াটসঅ্যাপ গ্রুপে যাওয়া যায়নি। লিংকটি চেক করুন।'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('হোয়াটসঅ্যাপ গ্রুপ'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // হোয়াটসঅ্যাপ আইকন
            const Icon(
              Icons.chat_bubble_rounded,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'আমাদের হোয়াটসঅ্যাপ গ্রুপে যুক্ত হোন',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'সরাসরি আমাদের সাথে কথা বলতে, আপডেট পেতে এবং যেকোনো সহায়তার জন্য আমাদের অফিসিয়াল হোয়াটসঅ্যাপ গ্রুপে যোগ দিন।',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // গ্রুপে জয়েন করার বাটন
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openWhatsAppGroup(context),
                icon: const Icon(Icons.group, color: Colors.white),
                label: const Text(
                  'গ্রুপে জয়েন করুন',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}