import 'package:flutter/material.dart';

class StoreLevelScreen extends StatelessWidget {
  final String currentVip;

  const StoreLevelScreen({
    super.key,
    this.currentVip = 'V1',
  });

  // স্ক্রিনশটের চার্ট অনুযায়ী ভিআইপি লেভেলের ডাটা (স্ট্যাটিকালি ডিক্লেয়ার করা ভালো)
  static final List<Map<String, dynamic>> _vipLevelsData = [
    {
      'id': 'V1',
      'name': 'V1',
      'deposit': '৳ ৩,০০০',
      'tasks': '৫টি',
      'unitPrice': '৳ ২০',
      'dailyIncome': '৳ ১০০',
      'monthlyIncome': '৳ ৩,০০০',
      'yearIncome': '৳ ৩৬,৫০০',
      'twoYearsIncome': '৳ ৭৩,০০০',
      'color': Colors.red,
    },
    {
      'id': 'V2',
      'name': 'V2',
      'deposit': '৳ ৬,০০০',
      'tasks': '১০টি',
      'unitPrice': '৳ ২০',
      'dailyIncome': '৳ ২০০',
      'monthlyIncome': '৳ ৬,০০০',
      'yearIncome': '৳ ৭৩,০০০',
      'twoYearsIncome': '৳ ১,৪৬,০০০',
      'color': Colors.blue,
    },
    {
      'id': 'V3',
      'name': 'V3',
      'deposit': '৳ ১০,০০০',
      'tasks': '১৪টি',
      'unitPrice': '৳ ২৫',
      'dailyIncome': '৳ ৩৫০',
      'monthlyIncome': '৳ ১০,৫০০',
      'yearIncome': '৳ ১,২৭,৭৫০',
      'twoYearsIncome': '৳ ২,৫৫,৫০০',
      'color': Colors.green,
    },
    {
      'id': 'V4',
      'name': 'V4',
      'deposit': '৳ ২০,০০০',
      'tasks': '২০টি',
      'unitPrice': '৳ ৩৭.৫',
      'dailyIncome': '৳ ৭৫০',
      'monthlyIncome': '৳ ২২,৫০০',
      'yearIncome': '৳ ২,৭৩,৭৫০',
      'twoYearsIncome': '৳ ৫,৪৭,৫০০',
      'color': Colors.purple,
    },
    {
      'id': 'V5',
      'name': 'V5',
      'deposit': '৳ ৩০,০০০',
      'tasks': '২৫টি',
      'unitPrice': '৳ ৪২',
      'dailyIncome': '৳ ১,০৫০',
      'monthlyIncome': '৳ ৩১,৫০০',
      'yearIncome': '৳ ৩,৮৩,২৫০',
      'twoYearsIncome': '৳ ৭,৬৬,৫০০',
      'color': Colors.brown,
    },
    {
      'id': 'V6',
      'name': 'V6',
      'deposit': '৳ ৫০,০০০',
      'tasks': '৩০টি',
      'unitPrice': '৳ ৬০',
      'dailyIncome': '৳ ১,৮০০',
      'monthlyIncome': '৳ ৫৪,০০০',
      'yearIncome': '৳ ৬,৫৭,০০০',
      'twoYearsIncome': '৳ ১৩,১৪,০০০',
      'color': Colors.teal,
    },
    {
      'id': 'V7',
      'name': 'V7',
      'deposit': '৳ ১,০০,০০০',
      'tasks': '৪০টি',
      'unitPrice': '৳ ৮৭.৫',
      'dailyIncome': '৳ ৩,৫০০',
      'monthlyIncome': '৳ ১,০৫,০০০',
      'yearIncome': '৳ ১২,৭৭,৫০০',
      'twoYearsIncome': '৳ ২৫,৫৫,০০০',
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'দোকানের স্তর ও আয়ের তালিকা',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // হেডিং ব্যানার
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    '১. কাজের স্তর ও আয় টেবিল',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // টেবিল লিস্ট
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vipLevelsData.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _vipLevelsData[index];
                final bool isCurrent = item['id'] == currentVip;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.red.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? Colors.redAccent : Colors.grey.shade300,
                      width: isCurrent ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: item['color'],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'আপনার বর্তমান স্তর',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          Text(
                            'জামানত: ${item['deposit']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn('দৈনিক কাজ', item['tasks']),
                          _buildInfoColumn('একক মূল্য', item['unitPrice']),
                          _buildInfoColumn('দৈনিক আয়', item['dailyIncome'],
                              isGreen: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn('৩০ দিনের আয়', item['monthlyIncome']),
                          _buildInfoColumn('৩৬৫ দিনের আয়', item['yearIncome']),
                          _buildInfoColumn(
                              '৭৩০ দিনের আয়', item['twoYearsIncome']),
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
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isGreen = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isGreen ? Colors.green.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }
}