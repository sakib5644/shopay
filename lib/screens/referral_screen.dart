import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();

  // ============================================================
  // রেফারেল বোনাস প্রদান করার স্ট্যাটিক ফাংশন
  // (যেখান থেকে বোনাস দেওয়া হবে, সেখানে এই ফাংশনটি কল করা যাবে)
  // ============================================================
  static Future<void> addReferralBonus({
    required String referrerUserId,
    required double bonusAmount,
    required String referredUserName,
  }) async {
    if (referrerUserId.isEmpty || bonusAmount <= 0) return;

    final referrerRef = FirebaseFirestore.instance.collection('users').doc(referrerUserId);
    final earningsHistoryRef = referrerRef.collection('earnings_history').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // ১. মূল রেফারারের ব্যালেন্স ও আয়ের হিসাব আপডেট
      transaction.update(referrerRef, {
        'balance': FieldValue.increment(bonusAmount),
        'totalIncome': FieldValue.increment(bonusAmount),
        'todayIncome': FieldValue.increment(bonusAmount),
      });

      // ২. অ্যানালিটিক্সের জন্য 'earnings_history' এ বাংলা বিবরণসহ সেভ করা
      transaction.set(earningsHistoryRef, {
        'amount': bonusAmount,
        'sourceType': 'referral',
        'description': 'রেফারেল বোনাস ($referredUserName এর একাউন্ট থেকে প্রাপ্ত)',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

class _ReferralScreenState extends State<ReferralScreen> with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late TabController _tabController;

  String _userReferralCode = ''; // ৫ সংখ্যার রেফার কোড সংরক্ষণের জন্য
  bool _isLoadingCode = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // লেভেল A, B, C এর জন্য ৩টি ট্যাব
    _fetchUserReferralCode();
  }

  // ফায়ারস্টোর থেকে ইউজারের নিজস্ব ৫ সংখ্যার রেফার কোডটি নিয়ে আসা
  Future<void> _fetchUserReferralCode() async {
    if (currentUserId.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          // যদি ডেটাবেজে 'referralCode' না থাকে, সাময়িকভাবে UID-এর প্রথম ৫ ডিজিট বা ডিফল্ট দেখাবে
          _userReferralCode = data?['referralCode'] ?? currentUserId.substring(0, 5).toUpperCase();
          _isLoadingCode = false;
        });
      }
    } catch (e) {
      setState(() {
        _userReferralCode = currentUserId.length >= 5 ? currentUserId.substring(0, 5).toUpperCase() : currentUserId;
        _isLoadingCode = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ৫ সংখ্যার রেফার কোড দিয়ে লিংক তৈরি (যেমন: ?ref=12345)
    final String referralLink = 'https://shopay.app/register?ref=$_userReferralCode';

    if (currentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('আমাদের টিম')),
        body: const Center(child: Text('দয়া করে প্রথমে লগইন করুন।')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('আমাদের টিম ও কমিশন', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'লেভেল A (সরাসরি)'),
            Tab(text: 'লেভেল B'),
            Tab(text: 'লেভেল C'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ফায়ারস্টোর থেকে বর্তমান ইউজারের রেফার করা মেম্বারদের ডাটা আনা
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('referredBy', isEqualTo: _userReferralCode.isNotEmpty ? _userReferralCode : currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoadingCode) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          final docs = snapshot.hasData ? snapshot.data!.docs : [];
          int totalMembers = docs.length;
          int activeMembers = 0;
          int inactiveMembers = 0;
          double totalCommission = 0.0;

          List<Map<String, dynamic>> levelAMembers = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            levelAMembers.add(data);

            // স্ট্যাটাস চেক (active / inactive)
            String status = data['status'] ?? 'active';
            if (status == 'active') {
              activeMembers++;
            } else {
              inactiveMembers++;
            }

            // কমিশন হিসাব (যদি থাকে)
            if (data['commission'] != null) {
              totalCommission += (data['commission'] as num).toDouble();
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ১. ওভারভিউ কার্ড (মোট সদস্য, অ্যাক্টিভ, ইনঅ্যাক্টিভ ও মোট ইনকাম)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade800, Colors.amber.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'আপনার রেফারেল টিম ও আয়ের বিবরণী',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('মোট সদস্য', '$totalMembers জন'),
                          _buildStatItem('অ্যাক্টিভ', '$activeMembers জন'),
                          _buildStatItem('ইনঅ্যাক্টিভ', '$inactiveMembers জন'),
                        ],
                      ),
                      const Divider(color: Colors.white54, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'মোট ইনকাম: ৳ ${totalCommission.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ২. রেফারেল লিংক কপি করার বক্স (৫ ডিজিট কোড সহ)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          referralLink,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('রেফারেল লিংক সফলভাবে কপি করা হয়েছে!'), backgroundColor: Colors.green),
                          );
                        },
                        child: const Text('কপি করুন'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ৩. ট্যাব অনুযায়ী মেম্বার লিস্ট (Level A, B, C)
                const Text(
                  'সদস্যদের তালিকা (নাম ও মোবাইল নম্বর)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMemberList(levelAMembers), // লেভেল A (সরাসরি)
                      _buildEmptyLevel('লেভেল B এর কোনো সদস্য নেই'), // লেভেল B
                      _buildEmptyLevel('লেভেল C এর কোনো সদস্য নেই'), // লেভেল C
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildEmptyLevel(String message) {
    return Center(
        child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13))
    );
  }

  Widget _buildMemberList(List<Map<String, dynamic>> members) {
    if (members.isEmpty) {
      return const Center(
        child: Text('এই লেভেলে এখনো কোনো সদস্য যুক্ত হয়নি!', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final name = member['name'] ?? 'নামবিহীন ইউজার';
        final phone = member['phone'] ?? 'নম্বর পাওয়া যায়নি';
        final status = member['status'] ?? 'active';
        final bool isActive = status == 'active';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      Icons.person,
                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ফোন: $phone',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  isActive ? 'সক্রিয়' : 'নিষ্ক্রিয়',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}