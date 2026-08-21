import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_deposit_requests_screen.dart';
import 'admin_withdrawal_requests_screen.dart';
import 'work_tasks_screen.dart';
import 'shop_products_screen.dart';
import 'user_management_screen.dart';
import 'admin_payment_methods_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _vipLevels = [];

  @override
  void initState() {
    super.initState();
    _loadVipLevels();
  }

  Future<void> _loadVipLevels() async {
    try {
      final snapshot = await _firestore.collection('vip_levels').get();
      final List<Map<String, dynamic>> data = [];

      for (final doc in snapshot.docs) {
        final map = doc.data();
        data.add({
          'id': doc.id,
          'commissionPerTask': _toDouble(map['commissionPerTask'] ?? map['commission']),
          'dailyTasks': _toInt(map['dailyTasks']),
        });
      }

      data.sort((a, b) {
        final aNumber = int.tryParse(a['id'].toString().replaceAll('v', '')) ?? 0;
        final bNumber = int.tryParse(b['id'].toString().replaceAll('v', '')) ?? 0;
        return aNumber.compareTo(bNumber);
      });

      if (!mounted) return;
      setState(() {
        _vipLevels = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _showMessage('VIP ডাটা লোড করা যায়নি।\n$e', Colors.red);
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _calculateDailyIncome(double commission, int dailyTasks) {
    return commission * dailyTasks;
  }

  Future<void> _editVip(Map<String, dynamic> vip) async {
    final String vipId = vip['id'].toString().toUpperCase();
    final TextEditingController taskController =
    TextEditingController(text: vip['dailyTasks'].toString());
    final TextEditingController commissionController =
    TextEditingController(text: vip['commissionPerTask'].toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$vipId VIP পরিবর্তন করুন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'দৈনিক কাজ', hintText: 'যেমন: 5'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commissionController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'প্রতি কাজের কমিশন', prefixText: '৳ ', hintText: 'যেমন: 20'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                final int? dailyTasks = int.tryParse(taskController.text.trim());
                final double? commission = double.tryParse(commissionController.text.trim());
                if (dailyTasks == null || commission == null || dailyTasks <= 0 || commission < 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('সঠিক সংখ্যা লিখুন।')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      taskController.dispose();
      commissionController.dispose();
      return;
    }

    final int dailyTasks = int.tryParse(taskController.text.trim()) ?? 0;
    final double commission = double.tryParse(commissionController.text.trim()) ?? 0;
    taskController.dispose();
    commissionController.dispose();

    if (dailyTasks <= 0 || commission < 0) return;
    await _saveVip(vipId, dailyTasks, commission);
  }

  Future<void> _saveVip(String vipId, int dailyTasks, double commission) async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });

    try {
      await _firestore.collection('vip_levels').doc(vipId.toLowerCase()).set({
        'dailyTasks': dailyTasks,
        'commissionPerTask': commission,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _loadVipLevels();
      if (!mounted) return;
      _showMessage('$vipId সফলভাবে আপডেট হয়েছে।', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showMessage('VIP আপডেট করা যায়নি।\n$e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  Widget _buildHeader() {
    final User? user = _auth.currentUser;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.white, size: 42),
          const SizedBox(height: 10),
          const Text(
            'Shopay Admin Control',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(user?.email ?? 'Admin', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          const Text(
            'VIP কমিশন, স্পিন ও টার্গেট পুরস্কার Firebase থেকে নিয়ন্ত্রণ করুন',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildVipCard(Map<String, dynamic> vip) {
    final String vipId = vip['id'].toString().toUpperCase();
    final int dailyTasks = _toInt(vip['dailyTasks']);
    final double commission = _toDouble(vip['commissionPerTask']);
    final double dailyIncome = _calculateDailyIncome(commission, dailyTasks);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _vipColor(vipId),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    vipId,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _saving ? null : () => _editVip(vip),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit VIP',
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: _infoBox('দৈনিক কাজ', '$dailyTasks টি', Icons.work_outline)),
                const SizedBox(width: 10),
                Expanded(child: _infoBox('প্রতি কাজ', '৳${commission.toStringAsFixed(2)}', Icons.payments_outlined)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.green),
                  const SizedBox(width: 10),
                  const Text('দৈনিক মোট আয়', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    '৳${dailyIncome.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _vipColor(String vipId) {
    switch (vipId) {
      case 'V1':
        return Colors.red;
      case 'V2':
        return Colors.blue;
      case 'V3':
        return Colors.green;
      case 'V4':
        return Colors.indigo;
      case 'V5':
        return Colors.red.shade800;
      case 'V6':
        return Colors.blueGrey;
      case 'V7':
        return Colors.orange.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadVipLevels,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),

            _buildNavigationCard(
              icon: Icons.account_balance_wallet,
              color: Colors.orange,
              title: 'ডিপোজিট রিকোয়েস্ট চেক করুন',
              subtitle: 'পেন্ডিং ডিপোজিট অনুমোদন করুন',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDepositRequestsScreen()),
              ),
            ),
            const SizedBox(height: 12),

            _buildNavigationCard(
              icon: Icons.payment,
              color: Colors.redAccent,
              title: 'উত্তোলন রিকোয়েস্ট চেক করুন',
              subtitle: 'পেন্ডিং উত্তোলন অনুমোদন করুন',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminWithdrawalRequestsScreen()),
              ),
            ),
            const SizedBox(height: 12),

            _buildNavigationCard(
              icon: Icons.task,
              color: Colors.indigo,
              title: 'Work Tasks Management',
              subtitle: 'টাস্ক বা কাজের ক্ষেত্র ম্যানেজ করুন',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkTasksScreen()),
              ),
            ),
            const SizedBox(height: 12),

            _buildNavigationCard(
              icon: Icons.shopping_bag,
              color: Colors.teal,
              title: 'Shop Products Management',
              subtitle: 'শপের রিয়েল প্রোডাক্ট ও স্টক ম্যানেজ করুন',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopProductsScreen()),
              ),
            ),
            const SizedBox(height: 12),

            _buildNavigationCard(
              icon: Icons.manage_accounts,
              color: Colors.blue,
              title: 'User Management & Monitoring',
              subtitle: 'সকল ইউজারের ব্যালেন্স, স্পিন ও টার্গেট পুরস্কার সেট করুন',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManagementScreen()),
              ),
            ),
            const SizedBox(height: 12),

            _buildNavigationCard(
              icon: Icons.account_balance,
              color: Colors.purple,
              title: 'পেমেন্ট মাধ্যম ম্যানেজ (bKash/Nagad)',
              subtitle: 'সেন্ড মানি নম্বর ও অ্যাকাউন্ট নিয়ন্ত্রণ করুন',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminPaymentMethodsScreen()),
              ),
            ),
            const SizedBox(height: 20),

            if (_vipLevels.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Firebase-এ কোনো VIP পাওয়া যায়নি।'),
                ),
              ),
            ..._vipLevels.map((vip) => _buildVipCard(vip)),
          ],
        ),
      ),
    );
  }
}