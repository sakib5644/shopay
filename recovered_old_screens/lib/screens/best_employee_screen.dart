import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BestEmployeeScreen extends StatefulWidget {
  const BestEmployeeScreen({super.key});

  @override
  State<BestEmployeeScreen> createState() => _BestEmployeeScreenState();
}

class _BestEmployeeScreenState extends State<BestEmployeeScreen>
    with SingleTickerProviderStateMixin {
  double balance = 0.00;
  int remainingSpins = 0;
  bool isSpinning = false;
  String selectedEmployeeText = 'ঘুরানোর জন্য শুরু বাটনে চাপুন';
  bool _isAdmin = false;

  // হুইলের স্লাইসগুলো (অর্ডার ঠিক রাখুন)
  final List<String> employees = [
    '🏍️ মোটরসাইকেল',
    '💻 ল্যাপটপ',
    '💰 ক্যাশ বোনাস',
    '✈️ কাপল ট্যুর',
    '🎁 গিফট ভাউচার',
    '📈 প্রমোশন'
  ];

  // অ্যাডমিনের সিলেক্টেড ইনডেক্স (ডিফল্ট ০)
  int adminSelectedIndex = 0;

  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;
  final double pointerAngle = -pi / 2;

  late ConfettiController _confettiController;
  List<String> selectionHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            setState(() {
              _isAdmin = data['role'] == 'admin';
              balance = (data['balance'] ?? 0.0).toDouble();
              remainingSpins = data['bestWorkerCount'] ?? 0;

              // নিখুঁतভাবে টার্গেট প্রাইজ হ্যান্ডেল করার লজিক
              var target = data['targetPrize'];
              if (target != null) {
                if (target is int) {
                  adminSelectedIndex = target;
                } else if (target is String) {
                  int idx = employees.indexOf(target);
                  // যদি হুবহু মিলে যায় বা স্পেস/ইমোজির কারণে সমস্যা হয়, সেটার বিকল্প চেক
                  if (idx != -1) {
                    adminSelectedIndex = idx;
                  } else {
                    // যদি স্ট্রিংয়ের ভেতরে নাম মিলে যায়
                    int matchedIdx = employees.indexWhere((e) => e.contains(target) || target.contains(e));
                    adminSelectedIndex = matchedIdx != -1 ? matchedIdx : 0;
                  }
                }
              }
            });
          }
        }
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _updateUserDataInFirestore(int newSpins, double newBalance) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        // ট্রানজেকশনের মাধ্যমে নিখুঁতভাবে ডেটা আপডেট করা যাতে আগের কাউন্ট ওভাররাইট না হয়
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (snapshot.exists) {
            transaction.update(docRef, {
              'bestWorkerCount': newSpins,
              'balance': newBalance,
            });
          }
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _shareResult(String prizeName) async {
    final String message = '''
🏆 ঘোষণা: সেরা কর্মী পুরস্কার জিতেছি!

⭐ পুরস্কার: $prizeName
🎯 সময়: ${DateTime.now().toString().substring(0, 16)}

অভিনন্দন!
    ''';

    try {
      await Share.share(message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শেয়ার করতে সমস্যা হয়েছে')),
      );
    }
  }

  void _showHistory() {
    if (selectionHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোনো ইতিহাস নেই!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.amber),
            SizedBox(width: 8),
            Text('পুরস্কারের ইতিহাস', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: selectionHistory.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade100,
                  child: Text('${selectionHistory.length - index}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(selectionHistory[index], style: const TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.star, color: Colors.amber),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectionHistory.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ইতিহাস ক্লিয়ার করা হয়েছে')),
              );
            },
            child: const Text('ক্লিয়ার', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  void addBonusSpinFromReferral() {
    setState(() {
      remainingSpins++;
    });
    _updateUserDataInFirestore(remainingSpins, balance);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('অভিনন্দন! সফল রেফারের কারণে ১টি সুযোগ যোগ হয়েছে!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> spinWheel() async {
    if (isSpinning) return;

    if (remainingSpins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('রেফার করে স্পিন ঘোরার সুযোগ নিন।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSpinning = true;
      remainingSpins--;
      selectedEmployeeText = 'ঘুরছে... ভাগ্য পরীক্ষা করুন!';
    });
    _updateUserDataInFirestore(remainingSpins, balance);

    // অ্যাডমিনের সিলেক্টেড ইনডেক্স অনুযায়ী হুইল থামানোর লজিক
    int selectedIndex = adminSelectedIndex;
    if (selectedIndex < 0 || selectedIndex >= employees.length) selectedIndex = 0;

    double totalItems = employees.length.toDouble();
    double radiansPerItem = (2 * pi) / totalItems;
    double targetSegmentCenter = selectedIndex * radiansPerItem + radiansPerItem / 2;
    double targetWheelAngle = pointerAngle - targetSegmentCenter;

    targetWheelAngle = targetWheelAngle % (2 * pi);
    if (targetWheelAngle < 0) targetWheelAngle += 2 * pi;

    int extraRotations = 5 + Random().nextInt(4);
    double finalAngle = targetWheelAngle + (extraRotations * 2 * pi);

    while (finalAngle <= _currentAngle) {
      finalAngle += 2 * pi;
    }

    _animation = Tween<double>(begin: _currentAngle, end: finalAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    _controller.reset();
    _controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        isSpinning = false;
        _currentAngle = finalAngle % (2 * pi);
        if (_currentAngle < 0) _currentAngle += 2 * pi;

        String wonPrize = employees[selectedIndex];
        selectedEmployeeText = '🎉 অভিনন্দন! আপনি জিতেছেন: $wonPrize';
        balance += 100;

        String historyEntry = '${DateTime.now().toString().substring(0, 16)} - জিতেছেন: $wonPrize';
        selectionHistory.add(historyEntry);
      });
      _updateUserDataInFirestore(remainingSpins, balance);

      _confettiController.play();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
              SizedBox(width: 8),
              Text('🎉 অভিনন্দন!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('আপনি জিতেছেন:', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(
                employees[selectedIndex],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () => _shareResult(employees[selectedIndex]),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('শেয়ার করুন'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('বেস্ট এমপ্লয়ী স্পিন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'ইতিহাস',
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('🏆 অ্যাওয়ার্ড পয়েন্ট', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${balance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                        ],
                      ),
                      Container(height: 40, width: 1, color: Colors.grey.shade700),
                      Column(
                        children: [
                          const Text('🎯 বাকি সুযোগ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$remainingSpins', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 340,
                  width: 340,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          double angle = isSpinning ? _animation.value : _currentAngle;
                          return Transform.rotate(
                            angle: angle,
                            child: Container(
                              height: 320,
                              width: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0F172A), width: 8),
                              ),
                              child: CustomPaint(
                                painter: EmployeeWheelPainter(employees: employees),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 0,
                          height: 0,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(width: 18, color: Colors.transparent),
                              right: BorderSide(width: 18, color: Colors.transparent),
                              bottom: BorderSide(width: 30, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: spinWheel,
                        child: Container(
                          height: 85,
                          width: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Text(
                              isSpinning ? 'ঘুরছে' : 'শুরু',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    selectedEmployeeText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selectedEmployeeText.contains('অভিনন্দন') ? Colors.green.shade700 : Colors.deepOrange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text('বাকি সুযোগ: $remainingSpins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: addBonusSpinFromReferral,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade300)),
                          child: const Center(child: Text('👥 রেফার করে সুযোগ পান', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeWheelPainter extends CustomPainter {
  final List<String> employees;
  EmployeeWheelPainter({required this.employees});

  @override
  void paint(Canvas canvas, Size size) {
    double center = size.width / 2;
    Rect rect = Rect.fromCircle(center: Offset(center, center), radius: center);
    Paint paint = Paint()..style = PaintingStyle.fill;
    double angleStep = 2 * pi / employees.length;

    final List<Color> colors = [
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    for (int i = 0; i < employees.length; i++) {
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, i * angleStep, angleStep, true, paint);

      canvas.save();
      canvas.translate(center, center);
      canvas.rotate(i * angleStep + angleStep / 2);

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: employees[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(center * 0.45, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}