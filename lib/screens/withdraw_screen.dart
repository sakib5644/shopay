import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WithdrawScreen extends StatefulWidget {
  final double userBalance; // ড্যাশবোর্ড থেকে ব্যালেন্স রিসিভ করার জন্য

  const WithdrawScreen({
    super.key,
    required this.userBalance,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  String selectedMethod = 'bKash';
  late double availableBalance;

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '400');
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _checkingSettings = true;
  bool _isAdmin = false; // অ্যাডমিন স্ট্যাটাস চেক করার জন্য

  // Admin Global Settings Variables for Withdrawal
  bool _withdrawalActive = true;
  bool _closeWithdrawalAfter5PM = false; // ভেরিয়েবলের নাম আগের মতোই রাখা হয়েছে
  bool _closeWithdrawalFriday = false;
  bool _closeWithdrawalSaturday = false;

  final List<double> quickAmounts = [
    400,
    1000,
    2500,
    5000,
    7500,
    10000,
    20000,
    30000,
    50000,
  ];

  @override
  void initState() {
    super.initState();
    availableBalance = widget.userBalance; // ড্যাশবোর্ডের ব্যালেন্স এখানে সেট করা হলো
    _checkAdminAndFetchSettings();
  }

  // ফায়ারবেস থেকে অ্যাডমিন স্ট্যাটাস এবং গ্লোবাল সেটিংস লোড করা
  Future<void> _checkAdminAndFetchSettings() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && (userData['isAdmin'] == true || userData['role'] == 'admin')) {
            setState(() {
              _isAdmin = true;
            });
          }
        }
      }

      final doc = await FirebaseFirestore.instance.collection('admin_settings').doc('global_config').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _withdrawalActive = data['withdrawalActive'] ?? true;
          _closeWithdrawalAfter5PM = data['closeWithdrawalAfter5PM'] ?? false;
          _closeWithdrawalFriday = data['closeWithdrawalFriday'] ?? false;
          _closeWithdrawalSaturday = data['closeWithdrawalSaturday'] ?? false;
          _checkingSettings = false;
        });
      } else {
        setState(() {
          _checkingSettings = false;
        });
      }
    } catch (e) {
      setState(() {
        _checkingSettings = false;
      });
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // উত্তোলন বন্ধ বা ছুটির দিন চেক করার ফাংশন (অ্যাডমিন হলে বাইপাস হয়ে যাবে)
  bool _isWithdrawalRestricted() {
    if (_isAdmin) {
      return false; // অ্যাডমিন হলে কোনো রেস্ট্রিকশন কাজ করবে না
    }

    if (!_withdrawalActive) {
      return true;
    }

    final now = DateTime.now();
    final weekday = now.weekday; // Monday = 1, ... Friday = 5, Saturday = 6, Sunday = 7
    final hour = now.hour; // ২৪ ঘণ্টার ফরম্যাটে বর্তমান ঘণ্টা (0 - 23)

    // ১. শুক্রবার (Friday = 5) এবং অ্যাডমিন প্যানেলে শুক্রবার বন্ধের অপশন অন থাকলে
    if (weekday == DateTime.friday && _closeWithdrawalFriday) {
      return true;
    }

    // ২. শনিবার (Saturday = 6) এবং অ্যাডমিন প্যানেলে শনিবার বন্ধের অপশন অন থাকলে
    if (weekday == DateTime.saturday && _closeWithdrawalSaturday) {
      return true;
    }

    // ৩. সকাল ৯:০০ টার আগে (< 9) অথবা সন্ধ্যা ৬:০০ টার পরে (>= 18) এবং অ্যাডমিন প্যানেলের সময়সীমার নিয়ম অন থাকলে
    if (_closeWithdrawalAfter5PM && (hour < 9 || hour >= 18)) {
      return true;
    }

    return false;
  }

  void _submitWithdrawal() async {
    if (_isWithdrawalRestricted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আজকে ছুটির দিন বা সময় শেষ, উত্তোলন বন্ধ রয়েছে।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    String accountNumber = _accountController.text.trim();
    String amountStr = _amountController.text.trim();
    String password = _passwordController.text.trim();

    if (accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('দয়া করে আপনার $selectedMethod অ্যাকাউন্ট নম্বর দিন')),
      );
      return;
    }

    if (amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('দয়া করে নির্দিষ্ট অ্যামাউন্ট সিলেক্ট করুন')),
      );
      return;
    }

    double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক পরিমাণ নির্বাচন করুন')),
      );
      return;
    }

    if (amount > availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আপনার অ্যাকাউন্টে পর্যাপ্ত উত্তোলনযোগ্য ব্যালেন্স নেই')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('দয়া করে লেনদেন পাসওয়ার্ড লিখুন')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    double fee = amount * 0.10;
    double netAmount = amount - fee;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('উত্তোলন সফল হয়েছে!'),
        content: Text(
          'আপনার $selectedMethod ($accountNumber) নম্বরে ৳$amount উত্তোলনের আবেদন সফলভাবে গৃহীত হয়েছে।\n\nপ্রসেসিং ফি (১০%): ৳${fee.toStringAsFixed(2)}\nপ্রকৃত পরিমাণ পাবেন: ৳${netAmount.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('ঠিক আছে', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openSupportChat() async {
    final Uri url = Uri.parse('https://t.me/your_support_username');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সাপোর্ট লিংক ওপেন করা সম্ভব হচ্ছে না')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double currentEnteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    double processingFee = currentEnteredAmount * 0.10;
    double netReceiveAmount = currentEnteredAmount - processingFee;

    bool isClosedNow = _isWithdrawalRestricted();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          _isAdmin ? 'ট্রান্সফার করুন (অ্যাডমিন মোড)' : 'ট্রান্সফার করুন',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _checkingSettings
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isClosedNow) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'আজকে ছুটির দিন অথবা সকাল ৯টা থেকে সন্ধ্যা ৬টার বাইরে সময় হওয়ায় উত্তোলন বন্ধ রয়েছে।',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'উত্তোলনযোগ্য টাকার পরিমাণ:',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '৳ ${availableBalance.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'ই-মানিব্যাগ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMethodCard('Nagad', Colors.orange.shade800)),
                const SizedBox(width: 12),
                Expanded(child: _buildMethodCard('bKash', Colors.pink.shade700)),
              ],
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _accountController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '$selectedMethod অ্যাকাউন্ট নম্বর (যেমন: 013XXXXXXXX)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'উত্তোলনের পরিমাণ সিলেক্ট করুন (নিচের অপশন থেকে):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickAmounts.map((amount) {
                bool isSelected = currentEnteredAmount == amount;
                return ChoiceChip(
                  label: Text('৳${amount.toInt()}'),
                  selected: isSelected,
                  selectedColor: Colors.blue.shade600,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _amountController.text = amount.toInt().toString();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'নির্বাচিত উত্তোলনের পরিমাণ',
                prefixText: '৳ ',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('উত্তোলনের পরিমাণ:', style: TextStyle(color: Colors.black54)),
                      Text('৳ ${currentEnteredAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('প্রসেসিং ফি:', style: TextStyle(color: Colors.black54)),
                      Text('10%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('প্রকৃত পরিমাণ:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('৳ ${netReceiveAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'লেনদেন পাসওয়ার্ড',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '******',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: (_isLoading || isClosedNow) ? null : _submitWithdrawal,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  isClosedNow ? 'উত্তোলন বন্ধ রয়েছে' : 'উত্তোলন সম্পূর্ণ করুন',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'সদয় টিপস:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'উত্তোলনের সময়: শুক্রবার, শনিবার এবং প্রতিদিন সকাল ৯টার আগে ও সন্ধ্যা ৬টার পর উত্তোলন বন্ধ থাকে।',
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: _openSupportChat,
                      icon: const Icon(Icons.support_agent, color: Colors.white, size: 18),
                      label: const Text('সাপোর্টে যোগাযোগ করুন', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(String methodName, Color activeColor) {
    bool isSelected = selectedMethod == methodName;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = methodName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              methodName == 'bKash' ? Icons.phone_android : Icons.account_balance_wallet,
              color: activeColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              methodName,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}