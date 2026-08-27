import 'package:flutter/material.dart';

// 🔹 লেনদেনের মডেল ক্লাস
class TransactionItem {
  final String title;
  final double amount;
  final bool isIncome; // true = আয় (লাল/গোলাপী +), false = ব্যয় (সবুজ -)
  final double originalBalance;
  final double newBalance;
  final String time;

  TransactionItem({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.originalBalance,
    required this.newBalance,
    required this.time,
  });
}

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🔹 ডেমো ডেটা (ছবি অনুযায়ী)
    final List<TransactionItem> transactions = [
      TransactionItem(
        title: 'ব্যালেন্সে যান',
        amount: 20000,
        isIncome: false,
        originalBalance: 20000,
        newBalance: 0,
        time: '18:11',
      ),
      TransactionItem(
        title: 'ফ্র্যাঞ্চাইজি ফি ফেরত',
        amount: 20000,
        isIncome: true,
        originalBalance: 0,
        newBalance: 20000,
        time: '17:56',
      ),
      TransactionItem(
        title: 'ব্যালেন্সে যান',
        amount: 200,
        isIncome: false,
        originalBalance: 200,
        newBalance: 0,
        time: '17:01',
      ),
      TransactionItem(
        title: 'লটারি পুরস্কার পরিমাণ',
        amount: 200,
        isIncome: true,
        originalBalance: 0,
        newBalance: 200,
        time: '17:00',
      ),
      TransactionItem(
        title: 'ব্যালেন্সে যান',
        amount: 9013.51,
        isIncome: false,
        originalBalance: 9013.51,
        newBalance: 0,
        time: '16:17',
      ),
      TransactionItem(
        title: 'সুপারিশ কার্যক্রম',
        amount: 9000,
        isIncome: true,
        originalBalance: 13.51,
        newBalance: 9013.51,
        time: '16:08',
      ),
      TransactionItem(
        title: 'ফ্র্যাঞ্চাইজি ফি',
        amount: 60000,
        isIncome: false,
        originalBalance: 60013.51,
        newBalance: 13.51,
        time: '16:04',
      ),
      TransactionItem(
        title: 'রিচার্জ সফল',
        amount: 30000,
        isIncome: true,
        originalBalance: 30013.51,
        newBalance: 60013.51,
        time: '15:30',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB), // ব্লু হেডার
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'লেনদেনেররেকর্ড',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 আয়-ব্যয়ের বিবরণ হেডার স্ট্রিপ
          Container(
            color: const Color(0xFF3B82F6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'আয়-ব্যয়েরবিবরণ',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '2026-01',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // 🔹 লেনদেনের তালিকা
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // তারিখ ও মোট আয়/ব্যয় সামারি
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'January 6',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Row(
                        children: [
                          Text('আয়৳ 80,201.04', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 10),
                          Text('ব্যয়৳ 89,213.51', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.8),

                // আইটেমগুলোর লিস্ট
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final item = transactions[index];
                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // টাইটেল
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              // অ্যামাউন্ট (আয় হলে লাল/গোলাপী, ব্যয় হলে সবুজ)
                              Text(
                                '${item.isIncome ? '+' : '-'}৳ ${item.amount.toStringAsFixed(item.amount.truncateToDouble() == item.amount ? 0 : 2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: item.isIncome ? const Color(0xFFE11D48) : const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ব্যালেন্স ডিটেইলস
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'মূলঅ্যাকাউন্টব্যালেন্স:৳ ${item.originalBalance.toStringAsFixed(item.originalBalance.truncateToDouble() == item.originalBalance ? 0 : 2)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    'পরিচালনারপরেঅ্যাকাউন্টব্যালেন্স:৳ ${item.newBalance.toStringAsFixed(item.newBalance.truncateToDouble() == item.newBalance ? 0 : 2)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              // সময়
                              Text(
                                item.time,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}