import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> completedTasks;

  const ProductListScreen({
    super.key,
    required this.completedTasks,
  });

  @override
  Widget build(BuildContext context) {
    return completedTasks.isEmpty
        ? const Center(
      child: Text(
        'এখনো কোনো অর্ডার কাজ সম্পন্ন করা হয়নি!',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: completedTasks.length,
      itemBuilder: (context, index) {
        final item = completedTasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: Icon(item['icon'] ?? Icons.check_circle_outline, color: Colors.green),
            ),
            title: Text(
              item['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text('মূল্য: ৳${item['price']}'),
            trailing: Text(
              '+৳${item['commission']}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      },
    );
  }
}