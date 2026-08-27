import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminWithdrawalRequestsScreen extends StatefulWidget {
  const AdminWithdrawalRequestsScreen({super.key});

  @override
  State<AdminWithdrawalRequestsScreen> createState() => _AdminWithdrawalRequestsScreenState();
}

class _AdminWithdrawalRequestsScreenState extends State<AdminWithdrawalRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // রিকোয়েস্ট অনুমোদন (Approve) করার লজিক (ট্রানজ্যাকশন সহ)
  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final String requestId = request['id'];
    final String userId = request['userId'];
    final double amount = (request['amount'] as num).toDouble();

    setState(() => _isLoading = true);

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final withdrawalRef = _firestore.collection('withdrawals').doc(requestId);

      // ট্রানজ্যাকশনের মাধ্যমে ইউজারের ব্যালেন্স থেকে টাকা মাইনাস এবং উইথড্রাল স্ট্যাটাস আপডেট
      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          throw Exception('ইউজার পাওয়া যায়নি!');
        }

        double currentBalance = (userSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

        if (currentBalance < amount) {
          throw Exception('ইউজারের পর্যাপ্ত ব্যালেন্স নেই!');
        }

        // ১. ইউজারের ব্যালেন্স কমানো
        transaction.update(userRef, {
          'balance': currentBalance - amount,
        });

        // ২. উইথড্রাল রিকোয়েস্ট স্ট্যাটাস approved করা
        transaction.update(withdrawalRef, {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('উত্তোলন রিকোয়েস্ট সফলভাবে অনুমোদিত হয়েছে!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ত্রুটি: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // রিকোয়েস্ট বাতিল (Reject) করার লজিক
  Future<void> _rejectRequest(String requestId) async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('withdrawals').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('উত্তোলন রিকোয়েস্ট বাতিল করা হয়েছে।'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('উত্তোলন রিকোয়েস্টসমূহ'),
        backgroundColor: Colors.redAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        // শুধু পেন্ডিং রিকোয়েস্টগুলো ফিল্টার করে আনা হচ্ছে
        stream: _firestore
            .collection('withdrawals')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'কোনো পেন্ডিং উত্তোলন রিকোয়েস্ট নেই।',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;

              final String requestId = data['id'] ?? '';
              final String method = data['method'] ?? 'N/A';
              final String accountNumber = data['accountNumber'] ?? 'N/A';
              final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'মেথড: $method',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                          ),
                          Text(
                            '৳ ${amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'অ্যাকাউন্ট নম্বর: $accountNumber',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _rejectRequest(requestId),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('বাতিল', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _approveRequest(data),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('অনুমোদন', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}