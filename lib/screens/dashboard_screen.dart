import 'package:shopay/screens/referral_screen.dart';
import 'admin_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'withdraw_screen.dart';
import 'best_employee_screen.dart';
import 'support_screen.dart';
import 'whatsapp_screen.dart';
import 'app_download_screen.dart';
import 'lucky_spin_screen.dart';
import 'shopay_shop_screen.dart';
import 'store_level_screen.dart';
import 'product_list_screen.dart';
import 'wallet_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userPhone;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

// ============================================================
// USER DATA
// ============================================================

  double _userBalance = 0.0;
  double _shopDeposit = 0.0;
  double _todayEarnings = 0.0;
  double _totalEarnings = 0.0;

  bool _isAdmin = false;

// ============================================================
// ADMIN GLOBAL SETTINGS
// ============================================================

  bool _fridayTaskOff = true;
  bool _checkingAdminSettings = true;

// ============================================================
// CHECK ADMIN ACCESS
// ============================================================

  Future<bool> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();

      final bool roleIsAdmin =
          data?['role']?.toString().trim().toLowerCase() == 'admin';

      final bool isAdminFieldTrue =
          data?['isAdmin'] == true;

      return roleIsAdmin || isAdminFieldTrue;
    } catch (e) {
      debugPrint('Admin check error: $e');
      return false;
    }
  }

// ============================================================
// OPEN ADMIN PANEL
// ============================================================

  Future<void> _openAdminPanel() async {
    final isAdmin = await _checkAdminAccess();

    if (!mounted) return;

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'আপনার Admin Panel ব্যবহারের অনুমতি নেই।',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminPanel(),
      ),
    );
  }

// ============================================================
// VIP DATA
// ============================================================

  String _currentVipId = 'none';
  String _currentVipName = 'VIP সক্রিয় নয়';

  bool _isVipActive = false;

  int _dailyTaskLimit = 0;
  int _completedTasksCount = 0;

  double _currentVipUnitPrice = 0.0;

// ============================================================
// LOADING STATE
// ============================================================

  bool _isLoadingUserData = true;
  bool _isLoadingTasks = true;
  bool _isCompletingTask = false;

// ============================================================
// TASK DATA
// ============================================================

  List<Map<String, dynamic>> _workTasks = [];

  final List<Map<String, dynamic>> _completedTaskList =
  <Map<String, dynamic>>[];

  final Set<String> _completedTaskIds = <String>{};

// ============================================================
// CURRENT USER
// ============================================================

  User? get _currentUser {
    return _auth.currentUser;
  }

// ============================================================
// INIT
// ============================================================

  @override
  void initState() {
    super.initState();

    // গুরুত্বপূর্ণ:
    // আগে User + Admin + VIP data একসাথে load হবে।
    // আলাদা asynchronous admin check-এর উপর VIP logic নির্ভর করবে না।

    _fetchGlobalTaskSettings();
    _loadAllUserDataAndTasks();
  }

// ============================================================
// FETCH GLOBAL TASK SETTINGS
// ============================================================

  Future<void> _fetchGlobalTaskSettings() async {
    try {
      final doc = await _firestore
          .collection('admin_settings')
          .doc('global_config')
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data() ?? {};

        setState(() {
          _fridayTaskOff = data['fridayTaskOff'] ?? true;
          _checkingAdminSettings = false;
        });
      } else {
        setState(() {
          _checkingAdminSettings = false;
        });
      }
    } catch (e) {
      debugPrint('Global task settings error: $e');

      if (!mounted) return;

      setState(() {
        _checkingAdminSettings = false;
      });
    }
  }

// ============================================================
// CHECK IF TASK IS RESTRICTED
// ============================================================

  bool _isTaskRestrictedToday() {
    final now = DateTime.now();
    final weekday = now.weekday;

    if (weekday == DateTime.friday && _fridayTaskOff) {
      return true;
    }

    return false;
  }

// ============================================================
// TODAY KEY
// ============================================================

  String _todayKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

// ============================================================
// SAFE DOUBLE CONVERTER
// ============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    ) ??
        0.0;
  }

// ============================================================
// VIP COMMISSION
// ============================================================

  double getCommissionForVipLevel(String vipLevel) {
    switch (vipLevel.toUpperCase()) {
      case 'V1':
        return 20.0;

      case 'V2':
        return 30.0;

      case 'V3':
        return 45.0;

      case 'V4':
        return 60.0;

      case 'V5':
        return 70.0;

      case 'V6':
        return 80.0;

      case 'V7':
        return 87.5;

      default:
        return 20.0;
    }
  }

// ============================================================
// VIP SETTINGS
// ============================================================

  void _setVipSettings(String vipId) {
    switch (vipId.toUpperCase()) {
      case 'V1':
        _dailyTaskLimit = 5;
        _currentVipUnitPrice = 20.0;
        _currentVipName = 'V1 VIP';
        break;

      case 'V2':
        _dailyTaskLimit = 10;
        _currentVipUnitPrice = 20.0;
        _currentVipName = 'V2 VIP';
        break;

      case 'V3':
        _dailyTaskLimit = 14;
        _currentVipUnitPrice = 25.0;
        _currentVipName = 'V3 VIP';
        break;

      case 'V4':
        _dailyTaskLimit = 20;
        _currentVipUnitPrice = 37.5;
        _currentVipName = 'V4 VIP';
        break;

      case 'V5':
        _dailyTaskLimit = 25;
        _currentVipUnitPrice = 42.0;
        _currentVipName = 'V5 VIP';
        break;

      case 'V6':
        _dailyTaskLimit = 30;
        _currentVipUnitPrice = 60.0;
        _currentVipName = 'V6 VIP';
        break;

      case 'V7':
        _dailyTaskLimit = 40;
        _currentVipUnitPrice = 87.5;
        _currentVipName = 'V7 VIP';
        break;

      default:
        _completedTasksCount = 0;
        _currentVipUnitPrice = 0.0;
        _currentVipName = 'VIP সক্রিয় নয়';
        break;
    }
  }

// ============================================================
// LOAD ALL USER + ADMIN + VIP + TASK DATA
// ============================================================

  Future<void> _loadAllUserDataAndTasks() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingUserData = true;
      _isLoadingTasks = true;
    });

    try {
      final user = _currentUser;

      if (user == null) {
        throw Exception('USER_NOT_LOGGED_IN');
      }

// ============================================================
// USER DOCUMENT
// ============================================================

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('USER_DOCUMENT_NOT_FOUND');
      }

      final data = userDoc.data() ?? {};

// ============================================================
// ADMIN STATUS
// ============================================================

      // Firebase-এর isAdmin এবং role — দুটোই গ্রহণ করা হবে।
      final bool roleIsAdmin =
          data['role']?.toString().trim().toLowerCase() == 'admin';

      final bool isAdminFieldTrue =
          data['isAdmin'] == true;

      // সবচেয়ে গুরুত্বপূর্ণ:
      // একই Firebase document থেকে Admin status নেওয়া হচ্ছে।
      // তাই asynchronous _checkAdminStatus() শেষ হওয়ার জন্য
      // অপেক্ষা করতে হবে না।

      final bool isAdminUser =
          roleIsAdmin || isAdminFieldTrue;

      _isAdmin = isAdminUser;

// ============================================================
// BALANCE DATA
// ============================================================

      _userBalance = _toDouble(
        data['balance'],
      );

      _shopDeposit = _toDouble(
        data['shopDeposit'] ??
            data['depositBalance'] ??
            0.0,
      );

      _todayEarnings = _toDouble(
        data['todayEarnings'],
      );

      _totalEarnings = _toDouble(
        data['totalEarnings'],
      );

// ============================================================
// VIP DATA
// ============================================================

      String vipId = 'none';

      // Firestore-এর সম্ভাব্য VIP fieldগুলো একসাথে support করা হলো।
      final savedVip =
          data['vipId'] ??
              data['vipLevel'] ??
              data['currentVip'] ??
              data['vip_id'];

      if (savedVip != null) {
        String rawVip = savedVip
            .toString()
            .trim()
            .toUpperCase();

        if (rawVip.isNotEmpty &&
            rawVip != 'NONE' &&
            rawVip != 'NULL') {

          // "V4 VIP" → "V4"
          if (rawVip.startsWith('V4')) {
            vipId = 'V4';
          } else if (rawVip.startsWith('V1')) {
            vipId = 'V1';
          } else if (rawVip.startsWith('V2')) {
            vipId = 'V2';
          } else if (rawVip.startsWith('V3')) {
            vipId = 'V3';
          } else if (rawVip.startsWith('V5')) {
            vipId = 'V5';
          } else if (rawVip.startsWith('V6')) {
            vipId = 'V6';
          } else if (rawVip.startsWith('V7')) {
            vipId = 'V7';
          } else if (int.tryParse(rawVip) != null) {
            vipId = 'V$rawVip';
          } else {
            vipId = rawVip;
          }
        }
      }

// ============================================================
// VIP ACTIVE LOGIC
// ============================================================

      bool vipActive = false;

      if (isAdminUser) {
        // ======================================================
        // ADMIN
        // ======================================================
        // Admin-এর জন্য Deposit বাধ্যতামূলক নয়।
        // Admin সবসময় VIP Active থাকবে।

        vipActive = true;

        // Firebase-এ VIP না থাকলেও Admin-এর default V4।
        if (vipId == 'none') {
          vipId = 'V4';
        }
      } else {
        // ======================================================
        // NORMAL USER / MEMBER
        // ======================================================

        if (vipId != 'none') {
          // আগে থেকেই VIP সেট করা থাকলে active।
          vipActive = true;
        } else {
          // নতুন user-এর জন্য Deposit থাকতে হবে।
          vipActive = _shopDeposit > 0;
        }
      }

// ============================================================
// SET VIP STATE
// ============================================================

      _currentVipId = vipId;
      _isVipActive = vipActive;

      if (_isVipActive) {
        _setVipSettings(_currentVipId);
      } else {
        _dailyTaskLimit = 0;
        _currentVipUnitPrice = 0.0;
        _currentVipName = 'VIP সক্রিয় নয়';
      }

      final double vipCommission =
      _isVipActive
          ? getCommissionForVipLevel(_currentVipId)
          : 0.0;

// ============================================================
// DEBUG INFORMATION
// ============================================================

      debugPrint(
        '================ USER DATA ================',
      );

      debugPrint(
        'UID: ${user.uid}',
      );

      debugPrint(
        'isAdmin: $_isAdmin',
      );

      debugPrint(
        'VIP ID: $_currentVipId',
      );

      debugPrint(
        'VIP Active: $_isVipActive',
      );

      debugPrint(
        'Shop Deposit: $_shopDeposit',
      );

      debugPrint(
        'Balance: $_userBalance',
      );

      debugPrint(
        '============================================',
      );

// ============================================================
// COMPLETED TASKS
// ============================================================

      final todayKey = _todayKey();

      final completedSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('completed_tasks')
          .where(
        'dateKey',
        isEqualTo: todayKey,
      )
          .get();

      final completedIds = <String>{};

      final completedList =
      <Map<String, dynamic>>[];

      for (final doc in completedSnapshot.docs) {
        final data = doc.data();

        final String savedTaskId =
            data['taskId']?.toString() ?? doc.id;

        completedIds.add(savedTaskId);

        completedList.add({
          'id': savedTaskId,
          'name': data['name'] ?? 'কাজ',
          'price': data['price'] ?? 0,
          'commission':
          data['commission'] ?? vipCommission,
        });
      }

// ============================================================
// LOAD ALL WORK TASKS
// ============================================================

      final snapshot = await _firestore
          .collection('work_tasks')
          .get();

      final List<Map<String, dynamic>> tasks = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final bool active =
            data['active'] != false;

        if (!active) {
          continue;
        }

        final String productName =
        data['name']
            ?.toString()
            .trim()
            .isNotEmpty ==
            true
            ? data['name'].toString()
            : 'ইলেকট্রনিক্স পণ্য';

        tasks.add({
          'id': doc.id,
          'name': productName,
          'price': data['price'] ?? 0,
          'category':
          data['category'] ?? 'Product',
          'active': true,
        });
      }
// ============================================================
// UPDATE UI STATE
// ============================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _currentVipId = vipId;
        _isVipActive = vipActive;

        _completedTaskIds
          ..clear()
          ..addAll(completedIds);

        _completedTaskList
          ..clear()
          ..addAll(completedList);

        _completedTasksCount = completedIds.length;

        _workTasks = tasks;

        _isLoadingUserData = false;
        _isLoadingTasks = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'Dashboard loading error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingUserData = false;
        _isLoadingTasks = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'তথ্য লোড করা যায়নি: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

// ============================================================
// TASK STATUS
// ============================================================

  bool _isTaskCompleted(String taskId) {
    return _completedTaskIds.contains(taskId);
  }

  bool get _dailyLimitReached {
    return _dailyTaskLimit > 0 &&
        _completedTasksCount >= _dailyTaskLimit;
  }

// ============================================================
// AUTOMATIC PRODUCT IMAGE
//
// পণ্যের নাম/ক্যাটাগরি দেখে ছবি নির্বাচন করা হবে।
// ============================================================

  String getAutoImageUrl(
      String productName, {
        String? category,
      }) {
    final text = '${productName.toLowerCase()} '
        '${category?.toLowerCase() ?? ''}';

    // ============================================================
    // PRODUCT NUMBER বের করা
    //
    // যেমন:
    // ইলেকট্রনিক পণ্য আইটেম #41
    // ইলেকট্রনিক পণ্য আইটেম #64
    // ইলেকট্রনিক পণ্য আইটেম #177
    // ============================================================

    final numberMatch = RegExp(r'#(\d+)').firstMatch(text);

    int itemNumber = 0;

    if (numberMatch != null) {
      itemNumber =
          int.tryParse(numberMatch.group(1) ?? '0') ?? 0;
    }

    // ============================================================
    // ১. মোবাইল / ফোন
    // ============================================================

    if (text.contains('phone') ||
        text.contains('mobile') ||
        text.contains('মোবাইল') ||
        text.contains('ফোন') ||
        text.contains('iphone') ||
        text.contains('samsung')) {
      final images = [
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1598327105666-5b89351aff97?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ২. ল্যাপটপ / কম্পিউটার
    // ============================================================

    if (text.contains('laptop') ||
        text.contains('ল্যাপটপ') ||
        text.contains('computer') ||
        text.contains('কম্পিউটার')) {
      final images = [
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1593642702749-b7d2a804fbcf?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ৩. হেডফোন / ইয়ারফোন
    // ============================================================

    if (text.contains('headphone') ||
        text.contains('earphone') ||
        text.contains('হেডফোন') ||
        text.contains('ইয়ারফোন') ||
        text.contains('ইয়ারফোন')) {
      final images = [
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1484704849700-f032a568e944?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1578319439584-104c94d37305?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1546435770-a3e426bf472b?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ৪. ঘড়ি
    // ============================================================

    if (text.contains('watch') ||
        text.contains('ঘড়ি') ||
        text.contains('ঘড়ি')) {
      final images = [
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1524805444758-089113d48a6d?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1434056886845-dac89ffe9b56?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1526045431048-f857369baa09?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ৫. ক্যামেরা
    // ============================================================

    if (text.contains('camera') ||
        text.contains('ক্যামেরা')) {
      final images = [
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1452780212940-6f5c0d14d848?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1606986628253-4f8b7b4c4e4f?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ৬. TV
    // ============================================================

    if (text.contains('tv') ||
        text.contains('television') ||
        text.contains('টিভি')) {
      final images = [
        'https://images.unsplash.com/photo-1593784991095-a205069470b6?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1461151304267-38535e780c79?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ৭. জুতা / স্যান্ডেল
    // ============================================================

    if (text.contains('shoe') ||
        text.contains('জুতা') ||
        text.contains('স্যান্ডেল') ||
        text.contains('সেন্ডেল') ||
        text.contains('sandal')) {
      final images = [
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1560769629-975ec94e6a86?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1495555961986-6d4c1ecb7be3?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ৮. ব্যাগ
    // ============================================================

    if (text.contains('bag') ||
        text.contains('ব্যাগ') ||
        text.contains('backpack')) {
      final images = [
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1581605405669-fcdf81165afa?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1622560480605-d83c853bc5c3?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ৯. শার্ট / পোশাক
    // ============================================================

    if (text.contains('shirt') ||
        text.contains('শার্ট') ||
        text.contains('জামা') ||
        text.contains('dress') ||
        text.contains('পোশাক') ||
        text.contains('clothing')) {
      final images = [
        'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1562157873-818bc0726f68?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১০. জ্যাকেট / শীতের পোশাক
    // ============================================================

    if (text.contains('jacket') ||
        text.contains('জ্যাকেট') ||
        text.contains('শীত') ||
        text.contains('winter') ||
        text.contains('সোয়েটার') ||
        text.contains('সোয়েটার') ||
        text.contains('হুডি')) {
      final images = [
        'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1548883354-94bcfe321cbb?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১১. প্যান্ট / জিন্স
    // ============================================================

    if (text.contains('pant') ||
        text.contains('প্যান্ট') ||
        text.contains('jeans') ||
        text.contains('জিন্স')) {
      final images = [
        'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1604176354204-9268737828e4?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১২. মাছ ধরা / Fishing
    // ============================================================

    if (text.contains('fishing') ||
        text.contains('fishing rod') ||
        text.contains('ফিশিং') ||
        text.contains('মাছ ধরা') ||
        text.contains('মাছ') ||
        text.contains('বড়শি') ||
        text.contains('বড়শি') ||
        text.contains('ছিপ')) {
      final images = [
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1534943441045-1009d7cbf8c0?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1445282768818-728615cc910a?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১৩. কসমেটিকস / পারফিউম
    // ============================================================

    if (text.contains('cosmetic') ||
        text.contains('কসমেটিক') ||
        text.contains('lipstick') ||
        text.contains('লিপস্টিক') ||
        text.contains('perfume') ||
        text.contains('পারফিউম') ||
        text.contains('সুগন্ধি')) {
      final images = [
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1612817288484-6f916006741a?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1588405748880-12d1d2a59f75?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১৪. রান্নাঘরের পণ্য
    // ============================================================

    if (text.contains('kitchen') ||
        text.contains('কিচেন') ||
        text.contains('রান্না') ||
        text.contains('হাঁড়ি') ||
        text.contains('হাড়ি') ||
        text.contains('পাতিল') ||
        text.contains('বাটি')) {
      final images = [
        'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1556912167-f556f1f39fdf?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1556909212-d5b604d0c90d?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১৫. USB / Flash Drive / Pendrive
    // ============================================================

    if (text.contains('usb') ||
        text.contains('flash drive') ||
        text.contains('pendrive') ||
        text.contains('পেনড্রাইভ')) {
      final images = [
        'https://images.unsplash.com/photo-1625842268584-8f3296236761?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1614064641938-3bbee52942c7?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১৬. Charger
    // ============================================================

    if (text.contains('charger') ||
        text.contains('চার্জার') ||
        text.contains('charging')) {
      final images = [
        'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1609592424848-2f4f0e7b2f77?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১৭. Cable
    // ============================================================

    if (text.contains('cable') ||
        text.contains('কেবল') ||
        text.contains('তার')) {
      final images = [
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1544724569-5f546fd6f2b5?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1625842268584-8f3296236761?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১৮. Speaker / Bluetooth
    // ============================================================

    if (text.contains('speaker') ||
        text.contains('স্পিকার') ||
        text.contains('bluetooth') ||
        text.contains('ব্লুটুথ')) {
      final images = [
        'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1589003077984-894e133dabab?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ১৯. Power Bank
    // ============================================================

    if (text.contains('power bank') ||
        text.contains('পাওয়ার ব্যাংক') ||
        text.contains('পাওয়ার ব্যাংক')) {
      final images = [
        'https://images.unsplash.com/photo-1609592424848-2f4f0e7b2f77?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1609592424632-9d9c5c8c7d8e?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1591290619762-c588c4f0a6c5?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ২০. Router / WiFi
    // ============================================================

    if (text.contains('router') ||
        text.contains('রাউটার') ||
        text.contains('wifi') ||
        text.contains('wi-fi')) {
      final images = [
        'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1606904825846-647eb07f5be2?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ২১. সাধারণ ELECTRONIC পণ্য
    // ============================================================

    if (text.contains('electronic') ||
        text.contains('electronics') ||
        text.contains('ইলেকট্রনিক')) {
      final electronicImages = [
        'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1588508065123-287b28e013da?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1593642702749-b7d2a804fbcf?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1562408590-e32931084e23?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1593642532973-d31b6557fa68?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=600&q=80',
      ];

      return electronicImages[
      itemNumber % electronicImages.length
      ];
    }

    // ============================================================
    // ২২. সাধারণ পণ্যের জন্য
    // ============================================================

    final generalImages = [
      'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1472851294608-062f824d29cc?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1491553895911-0055eca6402d?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=600&q=80',
    ];

    return generalImages[
    itemNumber % generalImages.length
    ];
  }
// ============================================================
// PART 2 - TASK COMPLETION + WORKSPACE (PART 1)
// ============================================================

  Future<void> _completeTask(Map<String, dynamic> task) async {
    final user = _currentUser;

    if (user == null) {
      return;
    }

    // ========================================================
    // WEEKEND CHECK (শুধুমাত্র শুক্রবার কাজ বন্ধ - অ্যাডমিন ছাড়া)
    // ========================================================
    final bool isAdminUser = _isAdmin || _currentVipId.toLowerCase() == 'admin';

    final now = DateTime.now();
    final currentDay = now.weekday; // Friday = 5

    if (currentDay == DateTime.friday && !isAdminUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'আজ শুক্রবার, সাপ্তাহিক ছুটির কারণে আজ কোনো কাজ করা যাবে না।',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // ========================================================
    // ADMIN / VIP ACCESS CHECK
    // ========================================================

    if (!isAdminUser &&
        (!_isVipActive ||
            _currentVipId == 'none' ||
            _currentVipId.isEmpty ||
            _shopDeposit <= 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'কাজ করতে হলে আগে ডিপোজিট করে VIP লেভেল সক্রিয় করতে হবে।',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ========================================================
    // TASK ID
    // ========================================================

    final String taskId = task['id']?.toString() ?? '';

    if (taskId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('পণ্যের ID পাওয়া যায়নি।'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ========================================================
    // DAILY TASK LIMIT (চার্ট অনুযায়ী ডাইনামিক লিমিট সেট করা হলো)
    // ========================================================
    int dynamicTaskLimit = _dailyTaskLimit;
    if (!isAdminUser) {
      String vId = _currentVipId.toLowerCase().trim();
      if (vId == 'v1') dynamicTaskLimit = 5;
      else if (vId == 'v2') dynamicTaskLimit = 10;
      else if (vId == 'v3') dynamicTaskLimit = 14;
      else if (vId == 'v4') dynamicTaskLimit = 20;
      else if (vId == 'v5') dynamicTaskLimit = 25;
      else if (vId == 'v6') dynamicTaskLimit = 30;
      else if (vId == 'v7') dynamicTaskLimit = 40;
    }

    if (_completedTasksCount >= dynamicTaskLimit && !isAdminUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'আজকের জন্য আপনার নির্ধারিত $dynamicTaskLimit টি কাজ সম্পূর্ণ হয়েছে। এর বেশি কাজ করা যাবে না।',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // ========================================================
    // DUPLICATE TASK CHECK
    // ========================================================

    if (_isTaskCompleted(taskId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('এই কাজটি ইতিমধ্যে সম্পন্ন করা হয়েছে।'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // ========================================================
    // PREVENT DOUBLE CLICK
    // ========================================================

    if (_isCompletingTask) {
      return;
    }

    setState(() {
      _isCompletingTask = true;
    });

    try {
      // ======================================================
      // TASK INFORMATION (চার্ট অনুযায়ী সঠিক কমিশন নির্ধারণ)
      // ======================================================
      double calculatedCommission = _currentVipUnitPrice;
      if (!isAdminUser) {
        String vId = _currentVipId.toLowerCase().trim();
        if (vId == 'v1') calculatedCommission = 20.0;
        else if (vId == 'v2') calculatedCommission = 20.0;
        else if (vId == 'v3') calculatedCommission = 25.0;
        else if (vId == 'v4') calculatedCommission = 37.5;
        else if (vId == 'v5') calculatedCommission = 42.0;
        else if (vId == 'v6') calculatedCommission = 60.0;
        else if (vId == 'v7') calculatedCommission = 87.5;
      } else {
        calculatedCommission = _currentVipUnitPrice > 0 ? _currentVipUnitPrice : 37.5;
      }

      final double commission = calculatedCommission;

      final double price = _toDouble(
        task['price'],
      );

      final String taskName =
      task['name']?.toString().trim().isNotEmpty == true
          ? task['name'].toString().trim()
          : 'কাজ';

      final String dateKey = _todayKey();

      final userRef = _firestore
          .collection('users')
          .doc(user.uid);

      final completedTaskRef = userRef
          .collection('completed_tasks')
          .doc('${dateKey}_$taskId');

      final transactionRef = userRef
          .collection('transactions')
          .doc();

      final earningsHistoryRef = userRef
          .collection('earnings_history')
          .doc();

      // ======================================================
      // FIREBASE TRANSACTION
      // ======================================================

      await _firestore.runTransaction(
            (transaction) async {
          final completedSnapshot =
          await transaction.get(
            completedTaskRef,
          );

          if (completedSnapshot.exists) {
            throw Exception(
              'TASK_ALREADY_COMPLETED',
            );
          }

          final userSnapshot =
          await transaction.get(
            userRef,
          );

          if (!userSnapshot.exists) {
            throw Exception(
              'USER_DOCUMENT_NOT_FOUND',
            );
          }

          final Map<String, dynamic> data =
          userSnapshot.data()
          as Map<String, dynamic>;

          final double currentBalance =
          _toDouble(
            data['balance'],
          );

          final double currentTodayEarnings =
          _toDouble(
            data['todayEarnings'],
          );

          final double currentTotalEarnings =
          _toDouble(
            data['totalEarnings'],
          );

          final double newBalance =
              currentBalance + commission;

          final double newTodayEarnings =
              currentTodayEarnings + commission;

          final double newTotalEarnings =
              currentTotalEarnings + commission;

          transaction.set(
            completedTaskRef,
            {
              'taskId': taskId,
              'name': taskName,
              'price': price,
              'commission': commission,
              'vipLevel': _currentVipId,
              'dateKey': dateKey,
              'completedAt':
              FieldValue.serverTimestamp(),
              'userId': user.uid,
            },
          );

          transaction.set(
            transactionRef,
            {
              'type': 'task_commission',
              'amount': commission,
              'title': taskName,
              'taskId': taskId,
              'vipLevel': _currentVipId,
              'createdAt':
              FieldValue.serverTimestamp(),
              'userId': user.uid,
            },
          );

          transaction.set(
            earningsHistoryRef,
            {
              'amount': commission,
              'sourceType': 'task',
              'description':
              'ভিআইপি টাস্ক ($taskName) সম্পন্ন করার কমিশন বাবদ',
              'taskId': taskId,
              'vipLevel': _currentVipId,
              'createdAt':
              FieldValue.serverTimestamp(),
              'userId': user.uid,
            },
          );

          transaction.update(
            userRef,
            {
              'balance': newBalance,
              'todayEarnings': newTodayEarnings,
              'totalEarnings': newTotalEarnings,
            },
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _completedTaskIds.add(
          taskId,
        );

        _completedTasksCount++;

        _userBalance += commission;

        _todayEarnings += commission;

        _totalEarnings += commission;

        _completedTaskList.add(
          {
            'id': taskId,
            'name': taskName,
            'price': price,
            'commission': commission,
          },
        );
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'কাজ সম্পন্ন হয়েছে! কমিশন ৳ ${commission.toStringAsFixed(2)} উত্তোলনযোগ্য ব্যালেন্সে যোগ হয়েছে।',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(
            seconds: 4,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Task completion error: $e',
      );

      if (!mounted) {
        return;
      }

      String errMessage =
      e.toString();

      if (errMessage.contains(
        'TASK_ALREADY_COMPLETED',
      )) {
        errMessage =
        'এই কাজটি ইতিমধ্যে সম্পন্ন করা হয়েছে।';
      } else if (errMessage.contains(
        'USER_DOCUMENT_NOT_FOUND',
      )) {
        errMessage =
        'আপনার User Document Firebase-এ পাওয়া যায়নি।';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'কাজ সম্পন্ন করা যায়নি: $errMessage',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(
            seconds: 5,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingTask = false;
        });
      }
    }
  }
  // ============================================================
// CONFIRM ORDER DIALOG
// ============================================================

  void _confirmOrderDialog(
      Map<String, dynamic> product,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'কাজ নিশ্চিতকরণ',
          ),
          content: Text(
            '${product['name'] ?? 'কাজ'}\n\n'
                'মূল্য: ৳ ${product['price'] ?? 0}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'বাতিল',
              ),
            ),
            ElevatedButton(
              onPressed: _isCompletingTask
                  ? null
                  : () {
                Navigator.pop(
                  dialogContext,
                );

                _completeTask(
                  product,
                );
              },
              child: const Text(
                'নিশ্চিত করুন',
              ),
            ),
          ],
        );
      },
    );
  }

// ============================================================
// WORK SPACE PAGE
// ============================================================

  Widget _buildWorkSpacePage() {
    return Column(
      children: [
        // ======================================================
        // VIP / DAILY TASK HEADER
        // ======================================================

        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.redAccent,
                Colors.deepOrange.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'দৈনিক কাজ ($_currentVipName)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentVipName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'আজকের সম্পন্ন কাজ: '
                    '$_completedTasksCount / $_dailyTaskLimit',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 8),

              LinearProgressIndicator(
                value: _dailyTaskLimit == 0
                    ? 0
                    : (_completedTasksCount / _dailyTaskLimit)
                    .clamp(0.0, 1.0),
                backgroundColor: Colors.white30,
                valueColor:
                const AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),

        // ======================================================
        // WORK TASK LIST
        // ======================================================

        Expanded(
          child: _isLoadingTasks || _isLoadingUserData
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.redAccent,
            ),
          )
              : _workTasks.isEmpty
              ? const Center(
            child: Text(
              'কোনো কাজ পাওয়া যায়নি!',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          )
              : RefreshIndicator(
            color: Colors.redAccent,
            onRefresh: _loadAllUserDataAndTasks,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _workTasks.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = _workTasks[index];

                final String taskId =
                    product['id']?.toString() ?? '';

                final bool completed =
                _isTaskCompleted(taskId);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: completed
                        ? Colors.green.shade50
                        : Colors.white,
                    borderRadius:
                    BorderRadius.circular(12),
                    border: Border.all(
                      color: completed
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ==================================
                      // PRODUCT IMAGE
                      // ==================================

                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(
                              getAutoImageUrl(
                                product['name']
                                    ?.toString() ??
                                    '',
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ==================================
                      // PRODUCT INFORMATION
                      // ==================================

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name']
                                  ?.toString() ??
                                  'পণ্য',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'দাম: ৳ ${product['price'] ?? 0}',
                              style: TextStyle(
                                color:
                                Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ==================================
                      // COMPLETED / ACTION BUTTON
                      // ==================================

                      completed
                          ? Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                          Colors.green.shade100,
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Text(
                          'সম্পন্ন',
                          style: TextStyle(
                            color: Colors
                                .green.shade800,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      )
                          : IconButton(
                        onPressed:
                        _isCompletingTask
                            ? null
                            : () {
                          // ==================================
                          // ADMIN CHECK
                          // ==================================

                          final bool
                          effectiveAdmin =
                              _isAdmin ||
                                  _currentVipId
                                      .toLowerCase() ==
                                      'admin';

                          // ==================================
                          // VIP / DEPOSIT CHECK
                          // ==================================

                          if (!effectiveAdmin &&
                              (!_isVipActive ||
                                  _currentVipId ==
                                      'none' ||
                                  _currentVipId
                                      .isEmpty ||
                                  _shopDeposit <=
                                      0)) {
                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'কাজ করতে হলে আগে ডিপোজিট করে VIP লেভেল সক্রিয় করতে হবে।',
                                ),
                                backgroundColor:
                                Colors.red,
                              ),
                            );

                            return;
                          }

                          // ==================================
                          // OPEN CONFIRMATION
                          // ==================================

                          _confirmOrderDialog(
                            product,
                          );
                        },
                        icon:
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor:
                          Colors.redAccent,
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
// ============================================================
// PRODUCT IMAGE WIDGET
// ============================================================
  Widget _buildProductImage(
      Map<String, dynamic> product,
      ) {
    final String name =
        product['name']?.toString() ?? 'পণ্য';

    final String? category =
    product['category']?.toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        getAutoImageUrl(
          name,
          category: category,
        ),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Colors.grey.shade500,
              size: 30,
            ),
          );
        },
        loadingBuilder: (
            context,
            child,
            loading,
            ) {
          if (loading == null) {
            return child;
          }

          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }
// ============================================================
  // PART 3 - PROFILE + NAVIGATION + BUILD
  // ============================================================

  Widget _buildMyProfilePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.orangeAccent,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'UID: ${widget.userPhone}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAdmin)
                IconButton(
                  onPressed: _openAdminPanel,
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ব্যালেন্স',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳ ${_userBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        // মানিব্যাগে প্রবেশ করার জন্য WalletScreen এ পাঠানো হলো
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WalletScreen(
                              balance: _userBalance,
                              depositBalance: _shopDeposit,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'মানিব্যাগে প্রবেশ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'দোকানের জামানত  ৳ ${_shopDeposit.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          // ডোমেইন নাম shopayshop.com আপডেট করা হলো
                          'আমন্ত্রণ লিংক: https://shopayshop.com/register?ref=${_currentUser?.uid ?? ''}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          final String referralLink = 'https://shopayshop.com/register?ref=${_currentUser?.uid ?? ''}';
                          Clipboard.setData(
                            ClipboardData(text: referralLink),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('রেফারেল লিংক কপি করা হয়েছে!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: const Text(
                            'কপি করুন',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'সবাই ব্যবহার করছে',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              _buildGridOptionTile(
                title: 'প্রতিদিন লাকি ড্র',
                icon: Icons.stars_rounded,
                iconColor: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LuckySpinScreen(),
                    ),
                  );
                },
              ),
              _buildGridOptionTile(
                title: 'সেরা কর্মী পুরস্কার',
                icon: Icons.emoji_events_outlined,
                iconColor: Colors.orangeAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BestEmployeeScreen(),
                    ),
                  );
                },
              ),
              _buildGridOptionTile(
                title: 'দোকান',
                icon: Icons.storefront_rounded,
                iconColor: Colors.deepOrange,
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              ),
              _buildGridOptionTile(
                title: "What's up এ যান",
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WhatsappScreen(),
                    ),
                  );
                },
              ),
              _buildGridOptionTile(
                title: 'App Download',
                icon: Icons.phone_android_rounded,
                iconColor: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppDownloadScreen(),
                    ),
                  );
                },
              ),
              _buildGridOptionTile(
                title: 'সাপোর্ট ম্যানেজার',
                icon: Icons.support_agent_outlined,
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupportScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ======================================================
          // আমাদের টিম (Team) অপশন বাটন (ড্যাশবোর্ড স্ক্রিনের জন্য)
          // ======================================================
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReferralScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: Colors.orange.shade800,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'আমাদের টিম',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'আপনার রেফার করা সদস্য ও কমিশন দেখুন',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGridOptionTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconColor.withOpacity(0.15),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBottomNavigationBar() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.check_box_outline_blank, 'কর্মক্ষেত্র'),
          _buildNavItem(1, Icons.assignment_outlined, 'পণ্যঅর্ডার'),
          GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                ' Sho Pay',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          _buildNavItem(3, Icons.diamond_outlined, 'দোকানেরস্তর'),
          _buildNavItem(4, Icons.sentiment_satisfied_alt_outlined, 'আমার'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index,
      IconData icon,
      String label,
      ) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.redAccent : Colors.grey.shade600,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.redAccent : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Shopay - কর্মক্ষেত্র' : 'Shopay',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildWorkSpacePage(),
            ProductListScreen(
              completedTasks: _completedTaskList,
            ),
            const ShopayShopScreen(),
            StoreLevelScreen(
              currentVip: _currentVipId,
            ),
            _buildMyProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
    );
  }
}