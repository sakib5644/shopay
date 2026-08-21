import 'package:flutter/material.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int completedTasks;
  final int totalTasks;

  const ProductDetailsScreen({
    Key? key,
    this.completedTasks = 0,
    this.totalTasks = 10,
  }) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 টপ ব্যানার: আজকের কাজ ও সম্পন্ন কাজের কাউন্টার
            Container(
              color: const Color(0xFF1976D2),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${widget.totalTasks}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const Text('আজকের কাজ', style: TextStyle(fontSize: 10, color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${widget.completedTasks}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const Text('আজকের সম্পন্ন কাজ', style: TextStyle(fontSize: 10, color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 📢 নোটিফিকেশন বার
            Container(
              color: const Color(0xFF42A5F5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: const [
                  Icon(Icons.volume_up, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'অভিনন্দন ***26 ভি১ ব্যবহারকারীকে পরামর্শ দেওয়া হয়েছে এবং অর্জন করেছে ৳ 6400',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 📑 ৩টি ট্যাব (প্রদর্শনী, অর্ডার, অর্ডার হিস্টোরি)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.redAccent,
                unselectedLabelColor: Colors.black87,
                indicatorColor: Colors.redAccent,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'প্রদর্শনী'),
                  Tab(text: 'অর্ডার'),
                  Tab(text: 'অর্ডার হিস্টোরি'),
                ],
              ),
            ),

            // 📦 কোনো প্রোডাক্ট থাকবে না - এখানে শুধুমাত্র "ফাঁকাতথ্য" দেখাবে
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmptyBox(),
                  _buildEmptyBox(),
                  _buildEmptyBox(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBox() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.all_inbox_outlined, size: 80, color: Colors.lightBlue.shade100),
          const SizedBox(height: 12),
          Text('ফাঁকাতথ্য', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}