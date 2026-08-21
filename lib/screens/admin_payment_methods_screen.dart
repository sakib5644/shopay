import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPaymentMethodsScreen extends StatefulWidget {
  const AdminPaymentMethodsScreen({super.key});

  @override
  State<AdminPaymentMethodsScreen> createState() => _AdminPaymentMethodsScreenState();
}

class _AdminPaymentMethodsScreenState extends State<AdminPaymentMethodsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddEditDialog({DocumentSnapshot? doc}) {
    final data = doc != null ? doc.data() as Map<String, dynamic> : null;

    final TextEditingController nameController =
    TextEditingController(text: data?['name'] ?? '');
    final TextEditingController numberController =
    TextEditingController(text: data?['number'] ?? '');
    final TextEditingController typeController =
    TextEditingController(text: data?['type'] ?? 'Personal');
    bool isActive = data?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(doc == null ? 'নতুন পেমেন্ট মাধ্যম যোগ করুন' : 'পেমেন্ট মাধ্যম এডিট করুন'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'মাধ্যমের নাম (যেমন: bKash, Nagad)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'একাউন্ট নম্বর (যেমন: 017XXXXXXXX)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'ধরন (যেমন: Personal / Agent)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('সক্রিয় (Active) রাখুন'),
                    value: isActive,
                    onChanged: (val) {
                      setDialogState(() {
                        isActive = val;
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final String name = nameController.text.trim();
                  final String number = numberController.text.trim();
                  final String type = typeController.text.trim();

                  if (name.isEmpty || number.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('নাম এবং নম্বর আবশ্যক!'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final Map<String, dynamic> paymentData = {
                    'name': name,
                    'number': number,
                    'type': type.isEmpty ? 'Personal' : type,
                    'isActive': isActive,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  try {
                    if (doc == null) {
                      await _firestore.collection('payment_methods').add(paymentData);
                    } else {
                      await _firestore.collection('payment_methods').doc(doc.id).update(paymentData);
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('সফলভাবে সংরক্ষণ করা হয়েছে!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('সংরক্ষণ করা যায়নি: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('সংরক্ষণ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteMethod(String docId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ডিলিট নিশ্চিত করুন'),
        content: const Text('আপনি কি এই পেমেন্ট মাধ্যমটি মুছে ফেলতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('না')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _firestore.collection('payment_methods').doc(docId).delete();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('মুছে ফেলা হয়েছে!'), backgroundColor: Colors.orange),
              );
            },
            child: const Text('হ্যাঁ, ডিলিট'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('পেমেন্ট গেটওয়ে কন্ট্রোল', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditDialog(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('payment_methods').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('কোনো পেমেন্ট মাধ্যম যুক্ত করা হয়নি। নিচে (+) আইকনে ক্লিক করে যোগ করুন।'),
            );
          }

          final methods = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final doc = methods[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isActive = data['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: isActive ? Colors.white : Colors.grey.shade200,
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green : Colors.grey,
                    child: const Icon(Icons.payment, color: Colors.white),
                  ),
                  title: Text(
                    '${data['name']} (${data['type'] ?? 'Personal'})',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey),
                  ),
                  subtitle: Text(
                    'নম্বর: ${data['number']}\nস্ট্যাটাস: ${isActive ? 'সক্রিয় (Active)' : 'নিষ্ক্রিয় (Inactive)'}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditDialog(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMethod(doc.id),
                      ),
                    ],
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