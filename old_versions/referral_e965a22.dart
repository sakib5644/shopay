import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Óª▓ÓºçÓª¡ÓºçÓª▓ A, B, C ÓªÅÓª░ Óª£Óª¿ÓºìÓª» Óº®ÓªƒÓª┐ ÓªƒÓºìÓª»Óª¥Óª¼
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String referralLink = 'https://shopay.app/register?ref=$currentUserId';

    if (currentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('ÓªåÓª«Óª¥ÓªªÓºçÓª░ ÓªƒÓª┐Óª«')),
        body: const Center(child: Text('ÓªªÓºƒÓª¥ ÓªòÓª░Óºç Óª¬ÓºìÓª░ÓªÑÓª«Óºç Óª▓ÓªùÓªçÓª¿ ÓªòÓª░ÓºüÓª¿ÓÑñ')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('ÓªåÓª«Óª¥ÓªªÓºçÓª░ ÓªƒÓª┐Óª« Óªô ÓªòÓª«Óª┐ÓªÂÓª¿', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Óª▓ÓºçÓª¡ÓºçÓª▓ A (Óª©Óª░Óª¥Óª©Óª░Óª┐)'),
            Tab(text: 'Óª▓ÓºçÓª¡ÓºçÓª▓ B'),
            Tab(text: 'Óª▓ÓºçÓª¡ÓºçÓª▓ C'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Óª½Óª¥Óª»Óª╝Óª¥Óª░Óª©ÓºìÓªƒÓºïÓª░ ÓªÑÓºçÓªòÓºç Óª¼Óª░ÓºìÓªñÓª«Óª¥Óª¿ ÓªçÓªëÓª£Óª¥Óª░ÓºçÓª░ Óª░ÓºçÓª½Óª¥Óª░ ÓªòÓª░Óª¥ Óª«ÓºçÓª«ÓºìÓª¼Óª¥Óª░ÓªªÓºçÓª░ ÓªíÓª¥ÓªƒÓª¥ ÓªåÓª¿Óª¥
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('referredBy', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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

            // Óª©ÓºìÓªƒÓºìÓª»Óª¥ÓªƒÓª¥Óª© ÓªÜÓºçÓªò (active / inactive)
            String status = data['status'] ?? 'active';
            if (status == 'active') {
              activeMembers++;
            } else {
              inactiveMembers++;
            }

            // ÓªòÓª«Óª┐ÓªÂÓª¿ Óª╣Óª┐Óª©Óª¥Óª¼ (Óª»ÓªªÓª┐ ÓªÑÓª¥ÓªòÓºç)
            if (data['commission'] != null) {
              totalCommission += (data['commission'] as num).toDouble();
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Óºº. ÓªôÓª¡Óª¥Óª░Óª¡Óª┐Óªë ÓªòÓª¥Óª░ÓºìÓªí (Óª«ÓºïÓªƒ Óª©ÓªªÓª©ÓºìÓª», ÓªàÓºìÓª»Óª¥ÓªòÓºìÓªƒÓª┐Óª¡, ÓªçÓª¿ÓªàÓºìÓª»Óª¥ÓªòÓºìÓªƒÓª┐Óª¡ Óªô Óª«ÓºïÓªƒ ÓªçÓª¿ÓªòÓª¥Óª«)
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
                        'ÓªåÓª¬Óª¿Óª¥Óª░ Óª░ÓºçÓª½Óª¥Óª░ÓºçÓª▓ ÓªƒÓª┐Óª« Óªô ÓªåÓºƒÓºçÓª░ Óª¼Óª┐Óª¼Óª░ÓªúÓºÇ',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Óª«ÓºïÓªƒ Óª©ÓªªÓª©ÓºìÓª»', '$totalMembers Óª£Óª¿'),
                          _buildStatItem('ÓªàÓºìÓª»Óª¥ÓªòÓºìÓªƒÓª┐Óª¡', '$activeMembers Óª£Óª¿'),
                          _buildStatItem('ÓªçÓª¿ÓªàÓºìÓª»Óª¥ÓªòÓºìÓªƒÓª┐Óª¡', '$inactiveMembers Óª£Óª¿'),
                        ],
                      ),
                      const Divider(color: Colors.white54, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Óª«ÓºïÓªƒ ÓªçÓª¿ÓªòÓª¥Óª«: Óº│ ${totalCommission.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Óº¿. Óª░ÓºçÓª½Óª¥Óª░ÓºçÓª▓ Óª▓Óª┐ÓªéÓªò ÓªòÓª¬Óª┐ ÓªòÓª░Óª¥Óª░ Óª¼ÓªòÓºìÓª©
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
                            const SnackBar(content: Text('Óª░ÓºçÓª½Óª¥Óª░ÓºçÓª▓ Óª▓Óª┐ÓªéÓªò Óª©Óª½Óª▓Óª¡Óª¥Óª¼Óºç ÓªòÓª¬Óª┐ ÓªòÓª░Óª¥ Óª╣ÓºƒÓºçÓªøÓºç!'), backgroundColor: Colors.green),
                          );
                        },
                        child: const Text('ÓªòÓª¬Óª┐ ÓªòÓª░ÓºüÓª¿'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Óº®. ÓªƒÓºìÓª»Óª¥Óª¼ ÓªàÓª¿ÓºüÓª»Óª¥ÓºƒÓºÇ Óª«ÓºçÓª«ÓºìÓª¼Óª¥Óª░ Óª▓Óª┐Óª©ÓºìÓªƒ (Level A, B, C)
                const Text(
                  'Óª©ÓªªÓª©ÓºìÓª»ÓªªÓºçÓª░ ÓªñÓª¥Óª▓Óª┐ÓªòÓª¥ (Óª¿Óª¥Óª« Óªô Óª«ÓºïÓª¼Óª¥ÓªçÓª▓ Óª¿Óª«ÓºìÓª¼Óª░)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMemberList(levelAMembers), // Óª▓ÓºçÓª¡ÓºçÓª▓ A (Óª©Óª░Óª¥Óª©Óª░Óª┐)
                      _buildEmptyLevel('Óª▓ÓºçÓª¡ÓºçÓª▓ B ÓªÅÓª░ ÓªòÓºïÓª¿Óºï Óª©ÓªªÓª©ÓºìÓª» Óª¿ÓºçÓªç'), // Óª▓ÓºçÓª¡ÓºçÓª▓ B
                      _buildEmptyLevel('Óª▓ÓºçÓª¡ÓºçÓª▓ C ÓªÅÓª░ ÓªòÓºïÓª¿Óºï Óª©ÓªªÓª©ÓºìÓª» Óª¿ÓºçÓªç'), // Óª▓ÓºçÓª¡ÓºçÓª▓ C
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
      child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }

  Widget _buildMemberList(List<Map<String, dynamic>> members) {
    if (members.isEmpty) {
      return const Center(
        child: Text('ÓªÅÓªç Óª▓ÓºçÓª¡ÓºçÓª▓Óºç ÓªÅÓªûÓª¿Óºï ÓªòÓºïÓª¿Óºï Óª©ÓªªÓª©ÓºìÓª» Óª»ÓºüÓªòÓºìÓªñ Óª╣ÓºƒÓª¿Óª┐!', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final name = member['name'] ?? 'Óª¿Óª¥Óª«Óª¼Óª┐Óª╣ÓºÇÓª¿ ÓªçÓªëÓª£Óª¥Óª░';
        final phone = member['phone'] ?? 'Óª¿Óª«ÓºìÓª¼Óª░ Óª¬Óª¥ÓªôÓºƒÓª¥ Óª»Óª¥ÓºƒÓª¿Óª┐';
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
                        'Óª½ÓºïÓª¿: $phone',
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
                  isActive ? 'Óª©ÓªòÓºìÓª░Óª┐Óºƒ' : 'Óª¿Óª┐ÓªÀÓºìÓªòÓºìÓª░Óª┐Óºƒ',
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
