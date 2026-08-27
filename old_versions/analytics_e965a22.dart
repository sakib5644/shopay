import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedFilter = 'Óª«Óª¥Óª©';

  // Óª¿ÓªñÓºüÓª¿ ÓªçÓªëÓª£Óª¥Óª░ÓºçÓª░ Óª£Óª¿ÓºìÓª» ÓªçÓª¿Óª┐ÓªÂÓª┐ÓºƒÓª¥Óª▓Óª┐ Óª©Óª¼ ÓªíÓºçÓªƒÓª¥ Óºª Óª¼Óª¥ Óª½Óª¥ÓªòÓª¥ Óª░Óª¥ÓªûÓª¥ Óª╣Óª▓Óºï, Óª»Óª¥ Óª¬Óª░Óª¼Óª░ÓºìÓªñÓºÇÓªñÓºç Óª½Óª¥ÓºƒÓª¥Óª░Óª©ÓºìÓªƒÓºïÓª░ ÓªÑÓºçÓªòÓºç ÓªíÓª¥ÓªçÓª¿Óª¥Óª«Óª┐Óªò Óª╣Óª¼Óºç
  double totalIncome = 0.0;
  double todayIncome = 0.0;
  double yesterdayIncome = 0.0;
  double pendingBalance = 0.0;
  double percentageChange = 0.0;

  // ÓªíÓª¥ÓªçÓª¿Óª¥Óª«Óª┐Óªò ÓªƒÓºìÓª░Óª¥Óª¿Óª£ÓºçÓªòÓªÂÓª¿ Óª▓Óª┐Óª©ÓºìÓªƒ (ÓªÂÓºüÓª░ÓºüÓªñÓºç Óª½Óª¥ÓªòÓª¥ ÓªÑÓª¥ÓªòÓª¼Óºç)
  List<Map<String, dynamic>> transactionList = [];

  // ÓªíÓª¥ÓªçÓª¿Óª¥Óª«Óª┐Óªò Óª¼Óª¥Óª░ ÓªÜÓª¥Óª░ÓºìÓªƒ ÓªíÓºçÓªƒÓª¥ (ÓªÂÓºüÓª░ÓºüÓªñÓºç ÓªÂÓºéÓª¿ÓºìÓª» Óª¼Óª¥ Óª½Óª¥ÓªòÓª¥)
  List<double> chartValues = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  List<String> chartLabels = ['ÓºªÓº½', 'ÓºªÓº¼', 'ÓºªÓº¡', 'ÓºªÓº«', 'ÓºªÓº»', 'ÓººÓºª'];

  @override
  void initState() {
    super.initState();
    // ÓªÅÓªûÓª¥Óª¿Óºç ÓªåÓª¬Óª¿Óª¥Óª░ Óª½Óª¥ÓºƒÓª¥Óª░Óª©ÓºìÓªƒÓºïÓª░ ÓªÑÓºçÓªòÓºç Óª¼Óª░ÓºìÓªñÓª«Óª¥Óª¿ ÓªçÓªëÓª£Óª¥Óª░ÓºçÓª░ Óª░Óª┐ÓºƒÓºçÓª▓ ÓªíÓºçÓªƒÓª¥ Óª½ÓºçÓªÜ ÓªòÓª░Óª¥Óª░ Óª½Óª¥ÓªéÓªÂÓª¿ ÓªòÓª▓ ÓªòÓª░ÓªñÓºç Óª╣Óª¼Óºç
    // e.g., _fetchUserAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'ÓªñÓªÑÓºìÓª»Óª¬Óª░Óª┐Óª©ÓªéÓªûÓºìÓª»Óª¥Óª¿ Óªô Óª¼Óª┐Óª¼Óª░Óªú',
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
            // Óºº. Óª¿ÓºÇÓª▓ Óª░ÓªÖÓºçÓª░ "Óª«ÓºïÓªƒ ÓªåÓª»Óª╝" ÓªòÓª¥Óª░ÓºìÓªí
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
                  const Text('Óª«ÓºïÓªƒÓªåÓª»Óª╝', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    'Óº│ ${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('ÓªùÓªñÓª«Óª¥Óª©ÓºçÓª░ÓªñÓºüÓª▓Óª¿Óª¥Óª»Óª╝ ${percentageChange.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Óº¿. Óº®ÓªƒÓª┐ ÓªøÓºïÓªƒ Óª©Óª«Óª¬Óª░Óª┐Óª«Óª¥Óªú ÓªòÓª¥Óª░ÓºìÓªí
            Row(
              children: [
                Expanded(child: _buildSmallStatCard('ÓªåÓª£ÓªòÓºçÓª░ÓªåÓª»Óª╝', 'Óº│ ${todayIncome.toStringAsFixed(2)}')),
                const SizedBox(width: 10),
                Expanded(child: _buildSmallStatCard('ÓªùÓªñÓªòÓª¥Óª▓ÓªòÓºçÓª░ÓªåÓª»Óª╝', 'Óº│ ${yesterdayIncome.toStringAsFixed(2)}')),
                const SizedBox(width: 10),
                Expanded(child: _buildSmallStatCard('Óª╣Óª┐Óª©Óª¥Óª¼ Óª╣Óª¼Óºç', 'Óº│ ${pendingBalance.toStringAsFixed(2)}')),
              ],
            ),
            const SizedBox(height: 20),

            // Óº®. Óª▓Óª¥Óª¡ Óª¼Óª┐ÓªÂÓºìÓª▓ÓºçÓªÀÓªú Óªô ÓªÜÓª¥Óª░ÓºìÓªƒ Óª©ÓºçÓªòÓªÂÓª¿
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
                        'Óª▓Óª¥Óª¡Óª¼Óª┐ÓªÂÓºìÓª▓ÓºçÓªÀÓªú',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: ['ÓªªÓª┐Óª¿', 'Óª«Óª¥Óª©', 'Óª¼ÓªøÓª░'].map((filter) {
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

                  // ÓªíÓª¥ÓªçÓª¿Óª¥Óª«Óª┐Óªò Óª¼Óª¥Óª░ ÓªÜÓª¥Óª░ÓºìÓªƒ (ÓªíÓºçÓªƒÓª¥ Óª¿Óª¥ ÓªÑÓª¥ÓªòÓª▓Óºç ÓªÂÓºéÓª¿ÓºìÓª» ÓªëÓªÜÓºìÓªÜÓªñÓª¥ ÓªªÓºçÓªûÓª¥Óª¼Óºç)
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

            // Óº¬. ÓªåÓª»Óª╝ Óª¼ÓºìÓª»Óª»Óª╝ÓºçÓª░ Óª¼Óª┐Óª¼Óª░Óªú
            const Text(
              'ÓªåÓª»Óª╝ Óª¼ÓºìÓª»Óª»Óª╝ÓºçÓª░ Óª¼Óª┐Óª¼Óª░Óªú',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Óª»ÓªªÓª┐ ÓªƒÓºìÓª░Óª¥Óª¿Óª£ÓºçÓªòÓªÂÓª¿ Óª¿Óª¥ ÓªÑÓª¥ÓªòÓºç ÓªñÓª¼Óºç Óª«ÓºçÓª©ÓºçÓª£ Óª¼Óª¥ Óª½Óª¥ÓªòÓª¥ Óª▓Óª┐Óª©ÓºìÓªƒ ÓªªÓºçÓªûÓª¥Óª¼Óºç
            transactionList.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'ÓªÅÓªûÓª¿Óºï ÓªòÓºïÓª¿Óºï Óª▓ÓºçÓª¿ÓªªÓºçÓª¿ Óª¼Óª¥ ÓªåÓºƒ ÓªÂÓºüÓª░Óºü Óª╣ÓºƒÓª¿Óª┐',
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

  // ÓªøÓºïÓªƒ ÓªòÓª¥Óª░ÓºìÓªíÓºçÓª░ ÓªëÓªçÓª£ÓºçÓªƒ
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

  // ÓªòÓª¥Óª©ÓºìÓªƒÓª« Óª¼Óª¥Óª░ ÓªÜÓª¥Óª░ÓºìÓªƒÓºçÓª░ ÓªëÓªçÓª£ÓºçÓªƒ
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

  // Óª«ÓºçÓª©ÓºçÓª£ ÓªåÓªòÓª¥Óª░Óºç Óª╣Óª┐Óª©ÓºçÓª¼ÓºçÓª░ ÓªëÓªçÓª£ÓºçÓªƒ
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
