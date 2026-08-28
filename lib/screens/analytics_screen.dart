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

  List<Map<String, dynamic>> transactionList = [];
  List<Map<String, dynamic>> earningsHistoryList = [];
  bool isLoadingTransactions = true;
  bool isLoadingEarnings = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _fetchEarningsHistory();
  }

  // উত্তোলনের হিস্ট্রি ফেচ করা (ইনডেক্স জনিত সমস্যা এড়াতে orderBy বাদ দিয়ে লোকালি সর্ট করা হয়েছে)
  Future<void> _fetchTransactions() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        setState(() => isLoadingTransactions = false);
        return;
      }

      final txSnapshot = await _firestore
          .collection('withdraw_requests')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> loadedTransactions = [];
      for (var doc in txSnapshot.docs) {
        final txData = doc.data();
        String formattedDate = 'তারিখ নেই';
        DateTime? dateTime;

        if (txData['createdAt'] != null) {
          dateTime = (txData['createdAt'] as Timestamp).toDate();
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }

        bool isApproved = txData['status'] == 'success' || txData['status'] == 'Approved';

        loadedTransactions.add({
          'title': 'উত্তোলন রিকোয়েস্ট: ৳ ${txData['amount'] ?? 0}',
          'date': 'তারিখ: $formattedDate\nনম্বর: ${txData['phone'] ?? 'N/A'} (${txData['method'] ?? 'bKash'})',
          'amount': '৳ ${txData['amount'] ?? 0}',
          'status': isApproved ? 'সফল (Approved)' : 'পেন্ডিং (Pending)',
          'isApproved': isApproved,
          'rawDate': dateTime ?? DateTime(2000), // সর্টিংয়ের জন্য
        });
      }

      // নতুন রিকোয়েস্টগুলো উপরে দেখানোর জন্য লোকালি সর্ট করা হলো
      loadedTransactions.sort((a, b) => (b['rawDate'] as DateTime).compareTo(a['rawDate'] as DateTime));

      if (!mounted) return;
      setState(() {
        transactionList = loadedTransactions;
        isLoadingTransactions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingTransactions = false);
    }
  }

  // আয়ের খাতের হিস্ট্রি ফেচ করা
  Future<void> _fetchEarningsHistory() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        setState(() => isLoadingEarnings = false);
        return;
      }

      final earnSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('earnings_history')
          .get();

      List<Map<String, dynamic>> loadedEarnings = [];
      for (var doc in earnSnapshot.docs) {
        final data = doc.data();
        String formattedDate = 'তারিখ নেই';
        DateTime? dateTime;

        if (data['createdAt'] != null) {
          dateTime = (data['createdAt'] as Timestamp).toDate();
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }

        loadedEarnings.add({
          'description': data['description'] ?? 'একাউন্টে আয় যুক্ত হয়েছে',
          'amount': '৳ ${data['amount'] ?? 0}',
          'date': formattedDate,
          'sourceType': data['sourceType'] ?? 'task',
          'rawDate': dateTime ?? DateTime(2000),
        });
      }

      loadedEarnings.sort((a, b) => (b['rawDate'] as DateTime).compareTo(a['rawDate'] as DateTime));

      if (!mounted) return;
      setState(() {
        earningsHistoryList = loadedEarnings;
        isLoadingEarnings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingEarnings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

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
      body: user == null
          ? const Center(child: Text('লগইন করা নেই'))
          : StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          double totalIncome = 0.0;
          double todayIncome = 0.0;
          double yesterdayIncome = 0.0;
          double thisMonthIncome = 0.0;
          double lastMonthIncome = 0.0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              totalIncome = (data['totalIncome'] ?? data['balance'] ?? 0.0).toDouble();
              todayIncome = (data['todayIncome'] ?? 0.0).toDouble();
              yesterdayIncome = (data['yesterdayIncome'] ?? 0.0).toDouble();
              thisMonthIncome = (data['thisMonthIncome'] ?? 0.0).toDouble();
              lastMonthIncome = (data['lastMonthIncome'] ?? 0.0).toDouble();
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _fetchTransactions();
              await _fetchEarningsHistory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ১. মোট স্থায়ী আয় কার্ড
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
                        const Text('সর্বমোট স্থায়ী আয়', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          '৳ ${totalIncome.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text('এই মোট আয় শুধুই বাড়বে, কমবে না', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ২. ছোট স্ট্যাটাস কার্ডসমূহ
                  Row(
                    children: [
                      Expanded(child: _buildSmallStatCard('আজকের আয়', '৳ ${todayIncome.toStringAsFixed(2)}')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSmallStatCard('গতকালের আয়', '৳ ${yesterdayIncome.toStringAsFixed(2)}')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildSmallStatCard('এই মাসের আয়', '৳ ${thisMonthIncome.toStringAsFixed(2)}')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSmallStatCard('গত মাসের আয়', '৳ ${lastMonthIncome.toStringAsFixed(2)}')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ৩. আয়ের খাতের বিবরণ
                  const Text(
                    'টাকা আয়ের খাতের বিবরণ (কোথা থেকে এসেছে)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  isLoadingEarnings
                      ? const Center(child: CircularProgressIndicator())
                      : earningsHistoryList.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'এখনো কোনো আয়ের রেকর্ড পাওয়া যায়নি',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: earningsHistoryList.length,
                    itemBuilder: (context, index) {
                      final earn = earningsHistoryList[index];
                      return _buildEarningSourceCard(
                        description: earn['description'],
                        amount: earn['amount'],
                        date: earn['date'],
                        sourceType: earn['sourceType'],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ৪. টাকা উত্তোলনের ইতিহাস
                  const Text(
                    'টাকা উত্তোলনের ইতিহাস',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  isLoadingTransactions
                      ? const Center(child: CircularProgressIndicator())
                      : transactionList.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
          );
        },
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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

  Widget _buildEarningSourceCard({
    required String description,
    required String amount,
    required String date,
    required String sourceType,
  }) {
    IconData iconData = Icons.work_outline;
    Color iconColor = Colors.blue;

    if (sourceType == 'referral') {
      iconData = Icons.group_add_outlined;
      iconColor = Colors.purple;
    } else if (sourceType == 'spin') {
      iconData = Icons.stars_outlined;
      iconColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(iconData, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            '+$amount',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

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