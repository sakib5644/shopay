import 'package:flutter/material.dart';
import 'analytics_screen.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart'; // ১. উত্তোলন স্ক্রিনটি এখানে ইমপোর্ট করা হলো

class WalletScreen extends StatelessWidget {
  final double balance;
  final double depositBalance;

  const WalletScreen({
    super.key,
    required this.balance,
    required this.depositBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('মানিব্যাগ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. মোট ব্যালেন্স ও জামানত
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepOrange, Colors.orangeAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('মোট ব্যালেন্স', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('৳ ${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white30, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('দোকানের জামানত', style: TextStyle(color: Colors.white, fontSize: 14)),
                      Text('৳ ${depositBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ২. ডিপোজিট ও উত্তোলন বাটন (কার্যকর করা হয়েছে)
            Row(
              children: [
                // ডিপোজিট বাটন
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DepositScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: const Text('ডিপোজিট', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),

                // উত্তোলন বাটন (WithdrawScreen এ ব্যালেন্স পাস করা হয়েছে)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WithdrawScreen(
                            userBalance: balance, // ওয়ালেটের ব্যালেন্স এখানে সফলভাবে পাস করা হলো
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                    label: const Text('উত্তোলন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ৩. আয় ব্যয়ের বিবরণ ও তথ্যপরিসংখ্যান (ট্যাব নেভিগেশন বাটন)
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepOrange.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFFFF0EC),
                      child: Icon(Icons.analytics_outlined, color: Colors.deepOrange, size: 24),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('আয় ব্যয়ের বিবরণ ও তথ্যপরিসংখ্যান', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                          SizedBox(height: 2),
                          Text('ট্যাব আকারে আয়ের হিসাব ও চার্ট দেখুন', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ৪. আপনার তৈরি করা রেডিমেড পিকচার ব্যানার সেকশন
            const Text(
              'কাজ, কমিশন ও টিম বোনাস চার্ট',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/chart_banner.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.amber.shade50,
                      child: const Center(
                        child: Text(
                          'assets/images/chart_banner.png ছবিটি পাওয়া যায়নি!',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}