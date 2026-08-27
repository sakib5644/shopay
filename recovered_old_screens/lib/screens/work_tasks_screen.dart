import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkTasksScreen extends StatefulWidget {
  const WorkTasksScreen({super.key});

  @override
  State<WorkTasksScreen> createState() => _WorkTasksScreenState();
}

class _WorkTasksScreenState extends State<WorkTasksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // নতুন বা এডিট ডায়ালগ
  void _showTaskDialog({String? docId, Map<String, dynamic>? initialData}) {
    final TextEditingController nameController = TextEditingController(text: initialData?['name'] ?? '');
    final TextEditingController categoryController = TextEditingController(text: initialData?['category'] ?? '');
    final TextEditingController imageController = TextEditingController(text: initialData?['image'] ?? '');
    final TextEditingController priceController = TextEditingController(text: initialData?['price']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(docId == null ? 'নতুন কাজ/পণ্য যোগ করুন' : 'টাস্ক এডিট করুন'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'নাম (Name)'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'ক্যাটাগরি (Category)'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'প্রোডাক্ট ইমেজ লিংক (Image URL)'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'দাম (Price)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final category = categoryController.text.trim();
              final image = imageController.text.trim();
              final double? price = double.tryParse(priceController.text.trim());

              if (name.isEmpty || price == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('দয়া করে সঠিক নাম এবং দাম পূরণ করুন।'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                if (docId == null) {
                  // নতুন ডাটা সেভ করা
                  await _firestore.collection('work_tasks').add({
                    'name': name,
                    'category': category,
                    'image': image,
                    'price': price,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  // বিদ্যমান ডাটা আপডেট করা
                  await _firestore.collection('work_tasks').doc(docId).update({
                    'name': name,
                    'category': category,
                    'image': image,
                    'price': price,
                  });
                }

                if (!mounted) return;
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('সফলভাবে সংরক্ষিত হয়েছে!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('সমস্যা হয়েছে: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(docId == null ? 'সংরক্ষণ' : 'আপডেট'),
          ),
        ],
      ),
    );
  }

  // টাস্ক ডিলিট করার ফাংশন
  Future<void> _deleteTask(String id) async {
    try {
      await _firestore.collection('work_tasks').doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সফলভাবে মুছে ফেলা হয়েছে!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('মুছে ফেলতে সমস্যা হয়েছে: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Tasks Management'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('work_tasks').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('কোনো টাস্ক বা পণ্য পাওয়া যায়নি।'));
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final data = task.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: data['image'] != null && data['image'].toString().isNotEmpty
                      ? Image.network(data['image'], width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image))
                      : const Icon(Icons.image, size: 50),
                  title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ক্যাটাগরি: ${data['category']} | দাম: ৳${data['price']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // পেন্সিল আইকন ক্লিক ইভেন্ট
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showTaskDialog(
                            docId: task.id,
                            initialData: data,
                          );
                        },
                      ),
                      // ডিলিট আইকন
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTask(task.id),
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
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}