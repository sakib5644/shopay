import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // সেরা কর্মী পুরস্কারের লিস্ট
  final List<String> _bestEmployeePrizes = const [
    '🏍️ মোটরসাইকেল',
    '💻 ল্যাপটপ',
    '💰 ক্যাশ বোনাস',
    '✈️ কাপল ট্যুর',
    '🎁 গিফট ভাউচার',
    '📈 প্রমোশন'
  ];

  // ইউজারের তথ্য আপডেট করার ডায়ালগ
  void _showEditUserDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final TextEditingController balanceController =
    TextEditingController(text: data['balance']?.toString() ?? '0');

    // ভিআইপি লেভেল থেকে শুধু সংখ্যা বের করা
    String rawVip = data['vipLevel']?.toString() ?? '1';
    rawVip = rawVip.replaceAll(RegExp(r'[^0-9]'), '');
    final TextEditingController vipController =
    TextEditingController(text: rawVip.isEmpty ? '1' : rawVip);

    // দোকানের জামানত কন্ট্রোলার
    final TextEditingController depositController =
    TextEditingController(text: data['shopDeposit']?.toString() ?? '0');

    final TextEditingController luckySpinController =
    TextEditingController(text: data['luckySpinCount']?.toString() ?? '0');
    final TextEditingController bestWorkerController =
    TextEditingController(text: data['bestWorkerCount']?.toString() ?? '0');

    // লাকি স্পিন টার্গেট এমাউন্টের জন্য টেক্সট কন্ট্রোলার (ফিক্সড দূর করার জন্য)
    final TextEditingController luckySpinTargetController =
    TextEditingController(text: data['luckySpinTarget']?.toString() ?? '20');

    String selectedTargetPrize = data['targetPrize']?.toString() ?? _bestEmployeePrizes[0];
    if (!_bestEmployeePrizes.contains(selectedTargetPrize)) {
      selectedTargetPrize = _bestEmployeePrizes[0];
    }

    bool isBlocked = data['isBlocked'] ?? false;
    bool deductFromBalance = false; // নতুন সুইচ কন্ট্রোল করার ভেরিয়েবল

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('ইউজার ম্যানেজ: ${data['name'] ?? data['email'] ?? 'User'}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ইমেল: ${data['email'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),

                  // ব্যালেন্স ইনপুট
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'মূল ব্যালেন্স (Balance)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // দোকানের জামানত ইনপুট
                  TextField(
                    controller: depositController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'দোকানের জামানত (Shop Deposit)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ভিআইপি লেভেল ইনপুট
                  TextField(
                    controller: vipController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ভিআইপি লেভেল (VIP Level 1-7 যেমন: 4)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // লাকি স্পিন সুযোগ ইনপুট
                  TextField(
                    controller: luckySpinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'বাকি স্পিন সংখ্যা (Lucky Spin Count)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // লাকি স্পিন টার্গেট এমাউন্ট ইনপুট (এখানে ইচ্ছামতো 20, 50 বা যেকোনো সংখ্যা দেওয়া যাবে)
                  TextField(
                    controller: luckySpinTargetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'লাকি স্পিন টার্গেট এমাউন্ট (Spin Target)',
                      prefixText: '৳ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // সেরা কর্মী পুরস্কার সুযোগ ইনপুট
                  TextField(
                    controller: bestWorkerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'কর্মী পুরস্কার সুযোগ (Best Worker Count)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Worker Target ড্রপডাউন (অপরিবর্তিত রাখা হয়েছে)
                  DropdownButtonFormField<String>(
                    value: selectedTargetPrize,
                    decoration: const InputDecoration(
                      labelText: 'সেরা কর্মী টার্গেট প্রাইজ (Worker Target)',
                      border: OutlineInputBorder(),
                    ),
                    items: _bestEmployeePrizes
                        .map((prize) => DropdownMenuItem(
                      value: prize,
                      child: Text(prize),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedTargetPrize = val;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 15),

                  // --------------------------------------------------
                  // নতুন ফিচার: ব্যালেন্স থেকে জামানত কাটার সুইচ
                  // --------------------------------------------------
                  SwitchListTile(
                    title: const Text(
                      'ব্যালেন্স থেকে জামানত কাটুন',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'টিক দিলে মূল ব্যালেন্স থেকে টাকা কেটে জামানতে যোগ হবে',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: deductFromBalance,
                    onChanged: (val) {
                      setDialogState(() {
                        deductFromBalance = val;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // অ্যাকাউন্ট ব্লক করার সুইচ
                  SwitchListTile(
                    title: const Text('অ্যাকাউন্ট ব্লক করুন', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    value: isBlocked,
                    onChanged: (val) {
                      setDialogState(() {
                        isBlocked = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('বাতিল'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                onPressed: () async {
                  final double currentBalance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                  final double depositToSet = double.tryParse(depositController.text.trim()) ?? 0.0;

                  // লেভেল ফরম্যাট করা (যেমন: V4)
                  final String rawVipInput = vipController.text.trim();
                  final String formattedVip = rawVipInput.toUpperCase().startsWith('V')
                      ? rawVipInput.toUpperCase()
                      : 'V$rawVipInput';

                  // যদি "ব্যালেন্স থেকে জামানত কাটুন" সুইচে টিক দেওয়া থাকে
                  if (deductFromBalance) {
                    if (currentBalance < depositToSet) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ইউজারের মূল ব্যালেন্সে পর্যাপ্ত টাকা নেই!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // ব্যালেন্স থেকে মাইনাস এবং জামানতে প্লাস হবে
                    await _firestore.collection('users').doc(doc.id).set({
                      'balance': FieldValue.increment(-depositToSet),
                      'shopDeposit': FieldValue.increment(depositToSet),
                      'vipLevel': formattedVip,
                      'luckySpinCount': int.tryParse(luckySpinController.text.trim()) ?? 0,
                      'bestWorkerCount': int.tryParse(bestWorkerController.text.trim()) ?? 0,
                      'luckySpinTarget': luckySpinTargetController.text.trim(),
                      'targetPrize': selectedTargetPrize,
                      'isBlocked': isBlocked,
                    }, SetOptions(merge: true));

                  } else {
                    // সাধারণ আপডেট
                    await _firestore.collection('users').doc(doc.id).set({
                      'balance': currentBalance,
                      'shopDeposit': depositToSet,
                      'vipLevel': formattedVip,
                      'luckySpinCount': int.tryParse(luckySpinController.text.trim()) ?? 0,
                      'bestWorkerCount': int.tryParse(bestWorkerController.text.trim()) ?? 0,
                      'luckySpinTarget': luckySpinTargetController.text.trim(),
                      'targetPrize': selectedTargetPrize,
                      'isBlocked': isBlocked,
                    }, SetOptions(merge: true));
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('সফলভাবে আপডেট করা হয়েছে!'), backgroundColor: Colors.green),
                  );
                },
                child: const Text('সংরক্ষণ'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management & Monitoring', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('কোনো রেজিস্টার্ড ইউজার পাওয়া যায়নি।'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final bool isBlocked = data['isBlocked'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: isBlocked ? Colors.red.shade50 : Colors.white,
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBlocked ? Colors.red : const Color(0xFF0F172A),
                    child: Text(
                      (data['name'] != null && data['name'].toString().isNotEmpty)
                          ? data['name'][0].toUpperCase()
                          : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? data['email'] ?? 'Unknown User',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isBlocked ? Colors.red : Colors.black),
                  ),
                  subtitle: Text(
                    'ব্যালেন্স: ৳${data['balance'] ?? 0} | জামানত: ৳${data['shopDeposit'] ?? 0} | VIP: ${data['vipLevel'] ?? 'None'}\nস্পিন সংখ্যা: ${data['luckySpinCount'] ?? 0} | কর্মী সুযোগ: ${data['bestWorkerCount'] ?? 0}\nটার겟 প্রাইজ: ${data['targetPrize'] ?? 'N/A'} | স্পিন টার্গেট: ৳${data['luckySpinTarget'] ?? '20'}',
                    style: const TextStyle(height: 1.3),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.manage_accounts, color: Colors.blue, size: 28),
                    onPressed: () => _showEditUserDialog(user),
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