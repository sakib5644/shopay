import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopProductsScreen extends StatefulWidget {
  const ShopProductsScreen({super.key});

  @override
  State<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends State<ShopProductsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // নতুন শপ প্রোডাক্ট যোগ বা এডিট করার ডায়ালগ
  void _showProductDialog({DocumentSnapshot? doc}) {
    final TextEditingController nameController = TextEditingController(text: doc?['name'] ?? '');
    final TextEditingController descriptionController = TextEditingController(text: doc?['description'] ?? '');
    final TextEditingController imageController = TextEditingController(text: doc?['image'] ?? '');
    final TextEditingController priceController = TextEditingController(text: doc?['price']?.toString() ?? '');
    final TextEditingController stockController = TextEditingController(text: doc?['stock']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? 'নতুন শপ প্রোডাক্ট যোগ করুন' : 'প্রোডাক্ট এডিট করুন'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'প্রোডাক্টের নাম (Product Name)'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'বিবরণ (Description)'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'প্রোডাক্ট ইমেজ লিংক (Image URL)'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'মূল্য (Price)'),
              ),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'স্টক পরিমাণ (Stock Quantity)'),
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
            onPressed: () async {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final image = imageController.text.trim();
              final double? price = double.tryParse(priceController.text.trim());
              final int? stock = int.tryParse(stockController.text.trim());

              // যদি নাম, দাম বা স্টক খালি থাকে বা ভুল হয়, তাহলে অ্যালার্ট দেখাবে
              if (name.isEmpty || price == null || stock == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('দয়া করে সঠিক নাম, মূল্য এবং স্টক পূরণ করুন।'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                if (doc == null) {
                  // ফায়ারস্টোরে নতুন প্রোডাক্ট সেভ করা
                  await _firestore.collection('shop_products').add({
                    'name': name,
                    'description': description,
                    'image': image,
                    'price': price,
                    'stock': stock,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  // বিদ্যমান প্রোডাক্ট আপডেট করা
                  await _firestore.collection('shop_products').doc(doc.id).update({
                    'name': name,
                    'description': description,
                    'image': image,
                    'price': price,
                    'stock': stock,
                  });
                }

                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('প্রোডাক্ট সফলভাবে সংরক্ষিত হয়েছে!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('সেভ করতে সমস্যা হয়েছে: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(doc == null ? 'সংরক্ষণ' : 'আপডেট'),
          ),
        ],
      ),
    );
  }

  // প্রোডাক্ট ডিলিট করার ফাংশন
  Future<void> _deleteProduct(String id) async {
    await _firestore.collection('shop_products').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Products Management'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('shop_products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('শপে কোনো প্রোডাক্ট পাওয়া যায়নি।'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final data = product.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: data['image'] != null && data['image'].toString().isNotEmpty
                      ? Image.network(data['image'], width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag))
                      : const Icon(Icons.shopping_bag, size: 50),
                  title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('দাম: ৳${data['price']} | স্টক: ${data['stock']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProductDialog(doc: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(product.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}