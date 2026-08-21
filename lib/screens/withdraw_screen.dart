import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  String selectedMethod = 'bKash';

  // নতুন অ্যাকাউন্ট হওয়ার কারণে ব্যালেন্স ০ করা হলো
  final double availableBalance = 0.00;

  // বাকি কন্ট্রোলার ও কোড আগের মতোই থাকবে...

  // কন্ট্রোলারসমূহ (অ্যামাউন্ট ফিল্ডটি এখন লকড থাকবে)
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '400'); // ডিফল্ট ৪০০ টাকা সেট করা
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // আপনার দেওয়া নির্দিষ্ট অ্যামাউন্টগুলোর তালিকা
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
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitWithdrawal() async {
    FocusScope.of(context).unfocus();

    String accountNumber = _accountController.text.trim();
    String amountStr = _amountController.text.trim();
    String password = _passwordController.text.trim();

    // ভ্যালিডেশন
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

    // প্রসেসিং সিমুলেশন (২ সেকেন্ড)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // হিসাব: ১০% প্রসেসিং ফি বাদ দিয়ে প্রকৃত পরিমাণ
    double fee = amount * 0.10;
    double netAmount = amount - fee;

    // সফল ডায়ালগ দেখানো
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
              Navigator.pop(context); // ডায়ালগ বন্ধ করবে
              Navigator.pop(context); // আগের স্ক্রিনে ফিরে যাবে
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

    // ফি ক্যালকুলেশন (১০%)
    double processingFee = currentEnteredAmount * 0.10;
    double netReceiveAmount = currentEnteredAmount - processingFee;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('ট্রান্সফার করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. উত্তোলনযোগ্য টাকার পরিমাণ কার্ড
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

            // ২. ই-মানিব্যাগ সেকশন (Nagad ও bKash)
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

            // অ্যাকাউন্ট নম্বর ইনপুট ফিল্ড
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

            // ৩. নির্ধারিত অ্যামাউন্ট অপশনসমূহ (শুধু ক্লিক করে সিলেক্ট করার জন্য)
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

            // ৪. অ্যামাউন্ট ডিসপ্লে বক্স (এটি সম্পূর্ণ Read-Only / লক করা, কেউ লিখে চেঞ্জ করতে পারবে না)
            TextField(
              controller: _amountController,
              readOnly: true, // ইউজার এখানে টাইপ করতে পারবে না
              decoration: InputDecoration(
                labelText: 'নির্বাচিত উত্তোলনের পরিমাণ',
                prefixText: '৳ ',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // ৫. হিসাব বিবরণী বক্স
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

            // ৬. লেনদেন পাসওয়ার্ড ইনপুট
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

            // সাবমিট বাটন
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isLoading ? null : _submitWithdrawal,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('উত্তোলন সম্পূর্ণ করুন', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            // ৭. সদয় টিপস এবং সাপোর্ট সেকশন
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
                    'দোকান খোলার সময়: সোমবার থেকে বৃহস্পতিবার, রবিবার 09:00-18:00\nহ্যান্ডলিং ফি: টাকা তোলার সময় ১০% হ্যান্ডলিং ফি প্রয়োজন, যা ট্যাক্স ফাইলিং এবং অন্যান্য খরচের জন্য ব্যবহৃত হয়!',
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