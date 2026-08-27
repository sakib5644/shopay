import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // টেক্সট কন্ট্রোলার (গ্রাহকের তথ্য সংরক্ষণের জন্য)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedPaymentMethod = 'ক্যাশ অন ডেলিভারি'; // ডিফল্ট পেমেন্ট মেথড

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // অর্ডার নিশ্চিত করার লজিক
  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      // এখানে অর্ডার সার্ভারে বা ডাটাবেজে পাঠানোর লজিক যুক্ত হবে
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('অর্ডার সফল হয়েছে!'),
            ],
          ),
          content: Text(
            'ধন্যবাদ ${_nameController.text}!\n'
                'আপনার অর্ডারটি সফলভাবে গ্রহণ করা হয়েছে। আমরা শীঘ্রই আপনার ডেলিভারি ঠিকানায় পণ্য পাঠিয়ে দেব।',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // ডায়ালগ বন্ধ
                Navigator.pop(context); // চেকআউট পেজ থেকে পেছনে ফিরে যাওয়া
              },
              child: const Text('ঠিক আছে', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('চেকআউট ও ডেলিভারি তথ্য'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- ১. গ্রাহকের ডেলিভারি তথ্য ফর্ম ----------------
              _buildSectionTitle('ডেলিভারি ঠিকানা ও গ্রাহকের তথ্য'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    // নাম
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'আপনার পুরো নাম *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'অনুগ্রহ করে আপনার নাম লিখুন';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ফোন নম্বর
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'মোবাইল নম্বর *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'অনুগ্রহ করে আপনার মোবাইল নম্বর লিখুন';
                        }
                        if (value.trim().length < 11) {
                          return 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // জেলা / শহর
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'জেলা / শহর *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'আপনার জেলা বা শহরের নাম লিখুন';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // বিস্তারিত ঠিকানা
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'সম্পূর্ণ ঠিকানা (বাসা/রোড/এলাকা) *',
                        prefixIcon: Icon(Icons.home_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'অনুগ্রহ করে আপনার বিস্তারিত ঠিকানা লিখুন';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // বিশেষ নোট (ঐচ্ছিক)
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'বিশেষ নির্দেশনা / নোট (ঐচ্ছিক)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- ২. পেমেন্ট পদ্ধতি ----------------
              _buildSectionTitle('পেমেন্ট পদ্ধতি নির্বাচন করুন'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      activeColor: Colors.redAccent,
                      title: const Text('ক্যাশ অন ডেলিভারি (পণ্য হাতে পেয়ে টাকা দিন)'),
                      value: 'ক্যাশ অন ডেলিভারি',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() => _selectedPaymentMethod = value!);
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      activeColor: Colors.redAccent,
                      title: const Text('বিকাশ / নগদ / রকেট (অনলাইন পেমেন্ট)'),
                      value: 'অনলাইন পেমেন্ট',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() => _selectedPaymentMethod = value!);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- ৩. অর্ডারের সংক্ষেপ (Summary) ----------------
              _buildSectionTitle('অর্ডার সামারি'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('মোট পণ্যের দাম:', style: TextStyle(fontSize: 14)),
                        Text('৳ ${widget.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ডেলিভারি চার্জ:', style: TextStyle(fontSize: 14)),
                        Text('৳ ৬০.০০', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('সর্বমোট টাকা:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '৳ ${(widget.totalPrice + 60.0).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------------- ৪. অর্ডার নিশ্চিত করুন বাটন ----------------
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitOrder,
                  child: const Text(
                    'অর্ডার কনফার্ম করুন',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}