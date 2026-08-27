import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedFilter = 'মাস';
  bool isLoading = true;

  double totalIncome = 0.0;
  double todayIncome = 0.0;
  double yesterdayIncome = 0.0;
  double pendingBalance = 0.0;
  double percentageChange = 0.0;

  List<Map<String, dynamic>> transactionList = [];
  List<double> chartValues = [0.2, 0.4, 0.6, 0.5, 0.8, 0.7]; // রিয়েল ডেটা না থাকলে ডিফল্ট রেশিও
  List<String> chartLabels = ['০৫', '০৬', '০৭', '০৮', '০৯', '১০'];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  // ফায়ারস্টোর থেকে রিয়েল-টাইম বা বর্তমান ডেটা ফেচ করার ফাংশন
  Future<void> _fetchAnalyticsData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      // ১. ইউজারের মূল ডাটা (যেমন মোট আয় বা ব্যালেন্স) ফেচ করা
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          totalIncome = (data['totalIncome'] ?? 0.0).toDouble();
          todayIncome = (data['todayIncome'] ?? 0.0).toDouble();
          yesterdayIncome = (data['yesterdayIncome'] ?? 0.0).toDouble();
          pendingBalance = (data['pendingBalance'] ?? 0.0).toDouble();
        }
      }

      // ২. ইউজারের উত্তোলন বা লেনদেনের হিস্ট্রি ফেচ করা
      final txSnapshot = await _firestore
          .collection('withdraw_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> loadedTransactions = [];
      for (var doc in txSnapshot.docs) {
        final txData = doc.data();

        // ফায়ারস্টোরের Timestamp ফরম্যাট হ্যান্ডেল করা
        String formattedDate = 'তারিখ নেই';
        if (txData['createdAt'] != null) {
          DateTime dateTime = (txData['createdAt'] as Timestamp).toDate();
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }

        bool isApproved = txData['status'] == 'success' || txData['status'] == 'Approved';

        loadedTransactions.add({
          'title': 'উত্তোলন রিকোয়েস্ট: ৳ ${txData['amount'] ?? 0}',
          'date': 'তারিখ: $formattedDate\nনম্বর: ${txData['phone'] ?? 'N/A'} (${txData['method'] ?? 'bKash'})',
          'amount': '৳ ${txData['amount'] ?? 0}',
          'isIncome': false, // উত্তোলন মানে টাকা কেটে নেওয়া/আউট
          'status': isApproved ? 'সফল (Approved)' : 'পেন্ডিং (Pending)',
          'isApproved': isApproved,
        });
      }

      if (!mounted) return;
      setState(() {
        transactionList = loadedTransactions;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ডেটা লোড করতে সমস্যা হয়েছে: $e')),
      );
    }
  }

  // নতুন উত্তোলন রিকোয়েস্ট জমা দেওয়ার ফাংশন (প্রয়োজনে কল করতে পারেন)
  Future<void> requestWithdrawal(double amount, String phoneNumber, String method) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // ইউজারনেম বা নাম সংগ্রহ
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String userName = userDoc.data()?['name'] ?? user.email ?? 'Unknown User';

      await _firestore.collection('withdraw_requests').add({
        'userId': user.uid,
        'userName': userName,
        'phone': phoneNumber,
        'method': method,
        'amount': amount,
        'status': 'Pending', // প্রথম অবস্থায় পেন্ডিং থাকবে
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ডাটা রিফ্রেশ করা
      _fetchAnalyticsData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('উত্তোলন রিকোয়েস্ট সফলভাবে জমা দেওয়া হয়েছে!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'তথ্য পরিসংখ্যান ও বিবরণ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchAnalyticsData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    const Text('মোট আয়', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      '৳ ${totalIncome.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text('রিয়েল-টাইম লাইভ আপডেট ডেটা', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ২. ৩টি ছোট সমপরিমাণ কার্ড
              Row(
                children: [
                  Expanded(child: _buildSmallStatCard('আজকের আয়', '৳ ${todayIncome.toStringAsFixed(2)}')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSmallStatCard('গতকালকের আয়', '৳ ${yesterdayIncome.toStringAsFixed(2)}')),
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
                          'লাভ বিশ্লেষণ',
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

                    // বার চার্ট
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

              // ৪. টাকা উত্তোলনের ইতিহাস বা বিবরণ
              const Text(
                'টাকা উত্তোলনের ইতিহাস',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),

              transactionList.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'এখনো কোনো উত্তোলনের রিকোয়েস্ট করা হয়নি',
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
                    status: tx['status'],
                    isApproved: tx['isApproved'],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ছোট কার্ডের উইজেট
  Widget _buildSmallStatCard(String title, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
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

  // উত্তোলনের হিসেব ও স্ট্যাটাস দেখানোর উইজেট
  Widget _buildTransactionMessage({
    required String title,
    required String date,
    required String amount,
    required String status,
    required bool isApproved,
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
            backgroundColor: isApproved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Icon(
              isApproved ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
              color: isApproved ? Colors.green : Colors.orange,
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
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isApproved ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}