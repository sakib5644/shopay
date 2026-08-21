import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedFilter = 'মাস';

  // নতুন ইউজারের জন্য ইনিশিয়ালি সব ডেটা ০ বা ফাকা রাখা হলো, যা পরবর্তীতে ফায়ারস্টোর থেকে ডাইনামিক হবে
  double totalIncome = 0.0;
  double todayIncome = 0.0;
  double yesterdayIncome = 0.0;
  double pendingBalance = 0.0;
  double percentageChange = 0.0;

  // ডাইনামিক ট্রানজেকশন লিস্ট (শুরুতে ফাকা থাকবে)
  List<Map<String, dynamic>> transactionList = [];

  // ডাইনামিক বার চার্ট ডেটা (শুরুতে শূন্য বা ফাকা)
  List<double> chartValues = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  List<String> chartLabels = ['০৫', '০৬', '০৭', '০৮', '০৯', '১০'];

  @override
  void initState() {
    super.initState();
    // এখানে আপনার ফায়ারস্টোর থেকে বর্তমান ইউজারের রিয়েল ডেটা ফেচ করার ফাংশন কল করতে হবে
    // e.g., _fetchUserAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'তথ্যপরিসংখ্যান ও বিবরণ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
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
            // ১. নীল রঙের "মোট আয়" কার্ড
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4C8CFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('মোটআয়', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '৳ ${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('গতমাসেরতুলনায় ${percentageChange.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ২. ৩টি ছোট সমপরিমাণ কার্ড
            Row(
              children: [
                Expanded(child: _buildSmallStatCard('আজকেরআয়', '৳ ${todayIncome.toStringAsFixed(2)}')),
                const SizedBox(width: 10),
                Expanded(child: _buildSmallStatCard('গতকালকেরআয়', '৳ ${yesterdayIncome.toStringAsFixed(2)}')),
                const SizedBox(width: 10),
                Expanded(child: _buildSmallStatCard('হিসাব হবে', '৳ ${pendingBalance.toStringAsFixed(2)}')),
              ],
            ),
            const SizedBox(height: 20),

            // ৩. লাভ বিশ্লেষণ ও চার্ট সেকশন
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'লাভবিশ্লেষণ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: ['দিন', 'মাস', 'বছর'].map((filter) {
                            final isSelected = selectedFilter == filter;
                            return GestureDetector(
                              onTap: () => setState(() => selectedFilter = filter),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF4C8CFF) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ডাইনামিক বার চার্ট (ডেটা না থাকলে শূন্য উচ্চতা দেখাবে)
                  SizedBox(
                    height: 160,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(chartValues.length, (index) {
                        return _buildBarItem(chartLabels[index], chartValues[index]);
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ৪. আয় ব্যয়ের বিবরণ
            const Text(
              'আয় ব্যয়ের বিবরণ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // যদি ট্রানজেকশন না থাকে তবে মেসেজ বা ফাকা লিস্ট দেখাবে
            transactionList.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'এখনো কোনো লেনদেন বা আয় শুরু হয়নি',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactionList.length,
              itemBuilder: (context, index) {
                final tx = transactionList[index];
                return _buildTransactionMessage(
                  title: tx['title'],
                  date: tx['date'],
                  amount: tx['amount'],
                  isIncome: tx['isIncome'],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ছোট কার্ডের উইজেট
  Widget _buildSmallStatCard(String title, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  // কাস্টম বার চার্টের উইজেট
  Widget _buildBarItem(String label, double heightRatio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: 120 * heightRatio,
          decoration: BoxDecoration(
            color: const Color(0xFF4C8CFF),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }

  // মেসেজ আকারে হিসেবের উইজেট
  Widget _buildTransactionMessage({
    required String title,
    required String date,
    required String amount,
    required bool isIncome,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}