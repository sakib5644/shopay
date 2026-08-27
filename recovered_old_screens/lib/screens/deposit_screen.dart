import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  // =========================================================================
  // 🛠️ [ADMIN CONTROL]: এখান থেকে আপনি যখন ইচ্ছা মার্চেন্ট নাম্বার পরিবর্তন করতে পারবেন।
  // =========================================================================
  final Map<String, String> activeMerchantNumbers = {
    'bKash': '01317157943',
    'Nagad': '01317157943',
    'Rocket': '01317157943',
  };

  String selectedMethod = 'Nagad';

  // অ্যামাউন্ট ইনপুট কন্ট্রোলার
  final TextEditingController _amountController = TextEditingController(text: '3000');
  final TextEditingController _txnController = TextEditingController();

  bool _isLoading = false;

  // কুইক অ্যামাউন্ট বাটনগুলোর লিস্ট
  final List<double> quickAmounts = [3000, 6000, 10000, 20000, 30000];

  @override
  void dispose() {
    _amountController.dispose();
    _txnController.dispose();
    super.dispose();
  }

  // ফায়ারবেসে ডিপোজিট রিকোয়েস্ট পাঠানোর ফাংশন
  void _verifyAndSubmit() async {
    String amountStr = _amountController.text.trim();
    String txnId = _txnController.text.trim();

    if (amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('দয়া করে ডিপোজিটের পরিমাণ লিখুন')),
      );
      return;
    }

    double? amount = double.tryParse(amountStr);
    if (amount == null || amount < 100 || amount > 25000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('৳১০০ থেকে ২৫,০০০ টাকার মধ্যে সঠিক পরিমাণ লিখুন')),
      );
      return;
    }

    if (txnId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('দয়া করে সঠিক ট্রানজেকশন আইডি (TxnID) লিখুন')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ইউজার লগইন করা নেই!')),
        );
        return;
      }

      // ফায়ারবেসের deposit_requests কালেকশনে ডাটা পাঠানো
      await FirebaseFirestore.instance.collection('deposit_requests').add({
        'userId': user.uid,
        'amount': amount,
        'trxId': txnId,
        'paymentMethod': selectedMethod, // বিকাশ, নগদ বা রকেট
        'status': 'pending', // প্রাথমিক স্ট্যাটাস পেন্ডিং থাকবে
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
      });

      // সফলতার ডায়ালগ বক্স
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('সফলভাবে জমা হয়েছে!'),
          content: Text('আপনার $selectedMethod এর মাধ্যমে ৳$amount জমার রিকোয়েস্ট সাবমিট হয়েছে। TxnID: $txnId। অ্যাডমিন অনুমোদন করলে ব্যালেন্স যোগ হবে।'),
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ত্রুটি হয়েছে: $e')),
      );
    }
  }

  void _openSupportChat() async {
    final Uri url = Uri.parse('https://t.me/your_support_username');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সাপোর্ট লিংক ওপেন করা সম্ভব হচ্ছে না')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentNumber = activeMerchantNumbers[selectedMethod] ?? '018XXXXXXXX';
    double currentEnteredAmount = double.tryParse(_amountController.text) ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.orange.shade800,
      appBar: AppBar(
        title: const Text('টাকা ডিপোজিট করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'আপনার পছন্দের পেমেন্ট মাধ্যম সিলেক্ট করুন:',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // পেমেন্ট মাধ্যম সিলেক্ট করার অপশন (bKash, Nagad, Rocket)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMethodCard('bKash', Colors.pink.shade700),
                _buildMethodCard('Nagad', Colors.orange.shade900),
                _buildMethodCard('Rocket', Colors.purple.shade700),
              ],
            ),
            const SizedBox(height: 20),

            // মার্চেন্ট ইনফো কার্ড
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shopay-$selectedMethod (Send Money)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('সক্রিয় অ্যাকাউন্ট', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('মার্চেন্ট নম্বর:', style: TextStyle(fontSize: 15, color: Colors.grey)),
                      Row(
                        children: [
                          Text(currentNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: currentNumber));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নম্বর কপি করা হয়েছে!')));
                            },
                            child: const Icon(Icons.copy, size: 20, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ডিপোজিট পরিমাণ সেকশন
            const Text(
              'ডিপোজিটের পরিমাণ সিলেক্ট বা লিখুন (৳১০০ - ৳২৫,০০০):',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // কুইক অ্যামাউন্ট চিপস
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickAmounts.map((amount) {
                bool isSelected = currentEnteredAmount == amount;
                return ChoiceChip(
                  label: Text('৳${amount.toInt()}'),
                  selected: isSelected,
                  selectedColor: Colors.amber.shade400,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.black54,
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
            const SizedBox(height: 12),

            // অ্যামাউন্ট ইনপুট ফিল্ড
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'পরিমাণ লিখুন (যেমন: 5000)',
                prefixText: '৳ ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),

            // ট্রানজেকশন আইডি ইনপুট ফিল্ড
            const Text(
              'ট্রানজেকশন আইডি (TxnID) এখানে লিখুন:',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _txnController,
              decoration: InputDecoration(
                hintText: 'যেমন: 74XQQU0T',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            // সাবমিট বাটন
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isLoading ? null : _verifyAndSubmit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('জমা দিন ও রিকোয়েস্ট পাঠান', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            // ম্যানুয়াল সাপোর্ট সেকশন
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'ট্রানজেকশন আইডি বসাতে সমস্যা হচ্ছে বা রিকোয়েস্ট জমা দিতে সমস্যা হলে?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: _openSupportChat,
                    icon: const Icon(Icons.support_agent, color: Colors.white),
                    label: const Text('ম্যানুয়াল সাপোর্টে যোগাযোগ করুন', style: TextStyle(color: Colors.white)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.yellow.shade300 : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))]
              : [],
        ),
        child: Text(
          methodName,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}