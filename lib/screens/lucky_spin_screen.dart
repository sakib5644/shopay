import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LuckySpinScreen extends StatefulWidget {
  const LuckySpinScreen({super.key});

  @override
  State<LuckySpinScreen> createState() => _LuckySpinScreenState();
}

class _LuckySpinScreenState extends State<LuckySpinScreen>
    with SingleTickerProviderStateMixin {
  double balance = 0.00;
  int remainingSpins = 0;
  bool isSpinning = false;
  String selectedPrizeText = 'ঘুরানোর জন্য শুরু বাটনে চাপুন';

  // চাকার স্লাইসগুলো (ক্লকওয়াইজ সাজানো)
  final List<String> prizes = const [
    '50',
    '3000',
    '20',
    '5000',
    '150',
    '2500',
    '100',
    '1000',
  ];

  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;

  late ConfettiController _confettiController;
  List<String> spinHistory = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          balance = (data?['balance'] ?? 0.0).toDouble();
          remainingSpins = data?['luckySpinCount'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _showHistory() {
    if (spinHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোনো ইতিহাস নেই!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('স্পিন ইতিহাস'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: spinHistory.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(spinHistory[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  Future<void> spinWheel() async {
    if (isSpinning) return;

    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আপনি লগইন নন!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final docRef = _firestore.collection('users').doc(user.uid);

    int freshSpins = 0;

    try {
      final doc = await docRef.get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ইউজার ডাটা পাওয়া যায়নি!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = doc.data() as Map<String, dynamic>?;

      freshSpins = (data?['luckySpinCount'] ?? 0) is num
          ? (data?['luckySpinCount'] ?? 0).toInt()
          : int.tryParse('${data?['luckySpinCount'] ?? 0}') ?? 0;
    } catch (e) {
      debugPrint('Spin count read error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ডাটা ফেচ করতে সমস্যা হয়েছে!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (freshSpins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আপনার পর্যাপ্ত স্পিন নেই! রেফার করুন।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // শুধুমাত্র ৳50 (index 0) এবং ৳20 (index 2) ফিক্সড রাখা হলো
    const List<int> allowedIndices = [0, 2];
    final int selectedIndex = allowedIndices[math.Random().nextInt(allowedIndices.length)];

    final String wonAmountStr = prizes[selectedIndex];
    final double wonAmount = double.tryParse(wonAmountStr) ?? 0.0;

    setState(() {
      isSpinning = true;
      remainingSpins = freshSpins - 1;
      selectedPrizeText = 'স্পিন হচ্ছে...';
    });

    final double segmentAngle = (2 * math.pi) / prizes.length;
    final double segmentCenter = selectedIndex * segmentAngle + (segmentAngle / 2);
    const double pointerAngle = -math.pi / 2;

    double targetAngle = pointerAngle - segmentCenter;
    targetAngle %= (2 * math.pi);

    if (targetAngle < 0) {
      targetAngle += 2 * math.pi;
    }

    final double currentNormalized = _currentAngle % (2 * math.pi);
    double rotationNeeded = targetAngle - currentNormalized;

    if (rotationNeeded < 0) {
      rotationNeeded += 2 * math.pi;
    }

    final int extraRotations = 6 + math.Random().nextInt(4);
    final double finalAngle = _currentAngle + (extraRotations * 2 * math.pi) + rotationNeeded;

    _animation = Tween<double>(
      begin: _currentAngle,
      end: finalAngle,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.reset();
    await _controller.forward();

    if (!mounted) return;

    bool updateSuccessful = false;

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('User document not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;

        final int latestSpins = (data['luckySpinCount'] ?? 0) is num
            ? (data['luckySpinCount'] ?? 0).toInt()
            : int.tryParse('${data['luckySpinCount'] ?? 0}') ?? 0;

        if (latestSpins <= 0) {
          throw Exception('No spins available');
        }

        final dynamic balanceValue = data['balance'] ?? 0;
        final double currentBalance = balanceValue is num
            ? balanceValue.toDouble()
            : double.tryParse('$balanceValue') ?? 0.0;

        final double newBalance = currentBalance + wonAmount;

        // ১. মূল ইউজারের ব্যালেন্স এবং স্পিন কাউন্ট আপডেট
        transaction.update(
          docRef,
          {
            'luckySpinCount': latestSpins - 1,
            'balance': newBalance,
          },
        );

        // ২. ট্রানজ্যাকশনের ভেতর ইউজারের earnings_history সাব-কালেকশনে রেকর্ড যুক্ত করা
        final earningsHistoryRef = docRef.collection('earnings_history').doc();
        transaction.set(earningsHistoryRef, {
          'amount': wonAmount,
          'sourceType': 'lucky_spin',
          'description': 'লাকি স্পিন থেকে প্রাপ্ত পুরস্কার: ৳$wonAmountStr',
          'createdAt': FieldValue.serverTimestamp(),
        });

        updateSuccessful = true;
      });
    } catch (e) {
      debugPrint('Final spin transaction error: $e');
    }

    if (!updateSuccessful) {
      setState(() {
        isSpinning = false;
        remainingSpins = freshSpins;
        _currentAngle = finalAngle % (2 * math.pi);
        selectedPrizeText = 'স্পিন সম্পন্ন হয়নি। আবার চেষ্টা করুন।';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('স্পিন সম্পন্ন করতে সমস্যা হয়েছে। টাকা যোগ করা হয়নি।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSpinning = false;
      _currentAngle = finalAngle % (2 * math.pi);
      remainingSpins = freshSpins - 1;
      balance += wonAmount;
      selectedPrizeText = '🎉 অভিনন্দন! আপনি জিতেছেন: ৳$wonAmountStr';

      spinHistory.insert(
        0,
        '${DateTime.now().toString().substring(0, 16)} - জিতেছেন ৳$wonAmountStr',
      );
    });

    _confettiController.play();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text('অভিনন্দন!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('আপনি জিতেছেন:', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 5),
            Text(
              '৳$wonAmountStr',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareResult(wonAmountStr);
            },
            child: const Text('শেয়ার করুন'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareResult(String prize) async {
    final String message = '''
🏆 আমি লাকি স্পিন খেলে জিতেছি!

🎁 জিতেছি: ৳$prize
🎯 সময়: ${DateTime.now().toString().substring(0, 16)}

আপনিও খেলুন এবং জিতে নিন!
    ''';
    try {
      await Share.share(message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শেয়ার করতে সমস্যা হয়েছে')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Lucky Spin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.military_tech, color: Colors.amber, size: 18),
                              SizedBox(width: 4),
                              Text('ব্যালেন্স', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('৳$balance', style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(height: 35, width: 1, color: Colors.white24),
                      Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.track_changes, color: Colors.redAccent, size: 18),
                              SizedBox(width: 4),
                              Text('বাকি স্পিন', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('$remainingSpins', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 330,
                  width: 330,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          double angle = isSpinning ? _animation.value : _currentAngle;
                          return Transform.rotate(
                            angle: angle,
                            child: SizedBox(
                              height: 300,
                              width: 300,
                              child: CustomPaint(painter: WheelPainter(prizes: prizes)),
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: spinWheel,
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.shade700,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Center(
                            child: Text(
                              isSpinning ? 'ঘুরছে' : 'শুরু',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        child: CustomPaint(
                          size: const Size(35, 30),
                          painter: TrianglePointerPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
                  ),
                  child: Text(
                    selectedPrizeText,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'বাকি স্পিন: $remainingSpins',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('রেফার লিংক শীঘ্রই আসছে!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF08A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people, color: Colors.blue, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'রেফার করে স্পিন পান',
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
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

// ============================================================
// PART 2: PAINTER CLASSES (Wheel & Pointer)
// ============================================================

class WheelPainter extends CustomPainter {
  final List<String> prizes;
  WheelPainter({required this.prizes});

  @override
  void paint(Canvas canvas, Size size) {
    double center = size.width / 2;
    Rect rect = Rect.fromCircle(center: Offset(center, center), radius: center);
    Paint paint = Paint()..style = PaintingStyle.fill;
    double angleStep = 2 * math.pi / prizes.length;

    final List<Color> colors = [
      Colors.teal,
      Colors.orange,
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.pink,
    ];

    for (int i = 0; i < prizes.length; i++) {
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, i * angleStep, angleStep, true, paint);

      canvas.save();
      canvas.translate(center, center);
      canvas.rotate(i * angleStep + angleStep / 2);

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '৳${prizes[i]}',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(center * 0.52, -textPainter.height / 2));
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TrianglePointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}