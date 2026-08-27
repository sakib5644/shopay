import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'checkout_screen.dart';

class ShopayShopScreen extends StatefulWidget {
  const ShopayShopScreen({super.key});

  @override
  State<ShopayShopScreen> createState() => _ShopayShopScreenState();
}

class _ShopayShopScreenState extends State<ShopayShopScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ইউজার যে প্রোডাক্টগুলো সিলেক্ট বা কার্টে বাড়াবে তার ট্র্যাক রাখার ম্যাপ (productId -> quantity)
  final Map<String, int> _quantities = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Shopay Shop', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // সরাসরি ফায়ারস্টোরের 'shop_products' থেকে রিয়েল-টাইম ডাটা আনা হচ্ছে
        stream: _firestore.collection('shop_products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'শপে এই মুহূর্তে কোনো প্রোডাক্ট পাওয়া যায়নি।',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final products = snapshot.data!.docs;

          // মোট দাম হিসাব করার লজিক
          double totalPrice = 0;
          for (var doc in products) {
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            final price = (data['price'] ?? 0).toDouble();
            final qty = _quantities[id] ?? 1; // ডিফল্ট কোয়ান্টিটি ১
            totalPrice += price * qty;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final productId = doc.id;

                    final name = data['name'] ?? 'Product';
                    final price = (data['price'] ?? 0).toDouble();
                    final imageUrl = data['image'] ?? '';
                    final currentQty = _quantities[productId] ?? 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // প্রোডাক্টের ছবি ফায়ারস্টোর থেকে শো করা (লিংক না থাকলে আইকন দেখাবে)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: imageUrl.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.shopping_bag, color: Colors.redAccent),
                              ),
                            )
                                : const Icon(Icons.shopping_bag, color: Colors.redAccent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('৳ $price', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          // কোয়ান্টিটি বাড়ানো বা কমানোর বাটন
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    if (currentQty > 1) {
                                      _quantities[productId] = currentQty - 1;
                                    }
                                  });
                                },
                              ),
                              Text('$currentQty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _quantities[productId] = currentQty + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // বটম সামারি ও অর্ডার সম্পন্ন বাটন (সঠিক করা প্যাডিং)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('মোট সর্বমোট:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '৳ ${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          // সিলেক্টেড প্রোডাক্টগুলোর লিস্ট তৈরি করে চেকআউটে পাঠানো
                          List<Map<String, dynamic>> cartItems = [];
                          for (var doc in products) {
                            final data = doc.data() as Map<String, dynamic>;
                            final productId = doc.id;
                            final qty = _quantities[productId] ?? 1;

                            cartItems.add({
                              'name': data['name'],
                              'price': data['price'],
                              'qty': qty,
                            });
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutScreen(
                                cartItems: cartItems,
                                totalPrice: totalPrice,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'অর্ডার সম্পন্ন করুন',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}