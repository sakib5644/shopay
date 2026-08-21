import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDownloadScreen extends StatelessWidget {
  const AppDownloadScreen({super.key});

  // অ্যাপ ডাউনলোড বা ওয়েবসাইটে রিডাইরেক্ট করার লিংক
  // এখানে আপনার হোস্টিংয়ে থাকা APK ফাইল বা ওয়েব অ্যাপের লিংক বসিয়ে দেবেন
  final String apkDownloadUrl = "https://bit.ly/46cJnsp";

  Future<void> _downloadApp(BuildContext context) async {
    final Uri url = Uri.parse(apkDownloadUrl);
    // সরাসরি লঞ্চ করার চেষ্টা করবে, কোনো শর্ত ছাড়াই
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('দুঃখিত, ডাউনলোড শুরু করা যায়নি। লিংকটি চেক করুন।'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('অ্যাপ ডাউনলোড - Shopay', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // অ্যাপের লোগো বা ব্যানার আইকন
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
                ],
                border: Border.all(color: Colors.orange.shade300, width: 3),
              ),
              child: Icon(
                Icons.phone_android,
                size: 60,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'আমাদের অফিশিয়াল অ্যাপ ডাউনলোড করুন',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            const Text(
              'মোবাইলে আরও দ্রুত ও সহজে শপ টু শপ লেনদেন এবং লাকি স্পিন খেলতে আমাদের অ্যান্ড্রয়েড অ্যাপটি ইনস্টল করুন।',
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // ডাউনলোড বাটন
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                onPressed: () => _downloadApp(context),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  'APK ডাউনলোড করুন',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ওয়েব অ্যাপ ব্যবহারের সুবিধা বা গাইডলাইন কার্ড
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      const Text(
                        'ব্যবহারের নিয়মাবলী:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('১. ডাউনলোড বাটনে ক্লিক করলে আপনার ব্রাউজার দিয়ে অ্যাপ ফাইল ডাউনলোড শুরু হবে।\n২. ফাইলটি ইনস্টল করার সময় ফোনে কোনো ওয়ার্নিং আসলে "Install Anyway" দিয়ে ইনস্টল সম্পন্ন করুন।\n৩. আপনি চাইলে সরাসরি ক্রোম ব্রাউজার থেকে ওয়েবসাইটটিকে হোম স্ক্রিনে যুক্ত (Add to Home Screen) করেও ওয়েব অ্যাপ হিসেবে ব্যবহার করতে পারেন।'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}