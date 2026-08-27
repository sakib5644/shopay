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
  double _shopDeposit = 0.0; // Óº¿Óºª Óª╣Óª¥Óª£Óª¥Óª░ ÓªòÓºçÓªƒÓºç Óºª.Óºª ÓªòÓª░Óºç ÓªªÓºçÓªôÓºƒÓª¥ Óª╣Óª▓Óºï
  double _todayEarnings = 0.0;
  double _totalEarnings = 0.0;

  bool _isAdmin = false;

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await _checkAdminAccess();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

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

      return data?['role']?.toString().toLowerCase() == 'admin';
    } catch (e) {
      return false;
    }
  }

  Future<void> _openAdminPanel() async {
    final isAdmin = await _checkAdminAccess();

    if (!mounted) return;

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ÓªåÓª¬Óª¿Óª¥Óª░ Admin Panel Óª¼ÓºìÓª»Óª¼Óª╣Óª¥Óª░ÓºçÓª░ ÓªàÓª¿ÓºüÓª«ÓªñÓª┐ Óª¿ÓºçÓªçÓÑñ',
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
  String _currentVipName = 'VIP Óª©ÓªòÓºìÓª░Óª┐Óª»Óª╝ Óª¿Óª»Óª╝';

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
    _checkAdminStatus(); // Óª¬ÓºìÓª░ÓªÑÓª« ÓªòÓª¥Óª£
    _loadAllUserDataAndTasks(); // ÓªªÓºìÓª¼Óª┐ÓªñÓºÇÓºƒ ÓªòÓª¥Óª£
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
          value.toString(),
        ) ??
        0.0;
  }

// ============================================================
// VIP COMMISSION
//
// ÓªÅÓªûÓª¥Óª¿Óºç ÓªòÓª«Óª┐ÓªÂÓª¿ UI-ÓªñÓºç ÓªªÓºçÓªûÓª¥Óª¿Óºï Óª╣Óª¼Óºç Óª¿Óª¥ÓÑñ
// ÓªòÓª¥Óª£ Óª©Óª«ÓºìÓª¬Óª¿ÓºìÓª¿ Óª╣Óª▓Óºç ÓªÅÓªç amount Firebase balance-ÓªÅ Óª»ÓºïÓªù Óª╣Óª¼ÓºçÓÑñ
// ============================================================

  double getCommissionForVipLevel(
    String vipLevel,
  ) {
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
        _currentVipName = 'VIP Óª©ÓªòÓºìÓª░Óª┐Óª»Óª╝ Óª¿Óª»Óª╝';
        break;
    }
  }

// ============================================================
// LOAD ALL USER + VIP + TASK DATA
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
        throw Exception(
          'USER_NOT_LOGGED_IN',
        );
      }

// --------------------------------------------------------
// USER DOCUMENT
// --------------------------------------------------------

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      String vipId = 'none';
      bool vipActive = false;

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};

        _userBalance =
            _toDouble(data['balance']);

        _shopDeposit = _toDouble(
          data['shopDeposit'] ??
              data['depositBalance'] ??
              0.0,
        );

        _todayEarnings =
            _toDouble(data['todayEarnings']);

        _totalEarnings =
            _toDouble(data['totalEarnings']);

        final savedVip =
            data['vipLevel'] ??
                data['currentVip'] ??
                data['vip_id'];

        if (savedVip != null &&
            savedVip.toString().trim().isNotEmpty &&
            savedVip.toString().trim().toLowerCase() != 'none') {
          vipId =
              savedVip.toString().trim().toUpperCase();
        }

        // VIP ÓªÂÓºüÓªºÓºüÓª«Óª¥ÓªñÓºìÓª░ ÓªíÓª┐Óª¬ÓºïÓª£Óª┐Óªƒ ÓªÑÓª¥ÓªòÓª▓ÓºçÓªç Óª©ÓªòÓºìÓª░Óª┐Óª»Óª╝ Óª╣Óª¼ÓºçÓÑñ
        // Óª¿ÓªñÓºüÓª¿ ÓªçÓªëÓª£Óª¥Óª░ÓºçÓª░ shopDeposit = 0 Óª╣Óª▓Óºç VIP Óª¼Óª¿ÓºìÓªº ÓªÑÓª¥ÓªòÓª¼ÓºçÓÑñ
        vipActive =
            vipId != 'none' &&
                _shopDeposit > 0;
      }

// VIP SETTINGS
// --------------------------------------------------------

      _currentVipId = vipId;
      _isVipActive = vipActive;

      if (_isVipActive) {
        _setVipSettings(vipId);
      } else {
        _dailyTaskLimit = 0;
        _currentVipUnitPrice = 0.0;
        _currentVipName = 'VIP Óª©ÓªòÓºìÓª░Óª┐Óª»Óª╝ Óª¿Óª»Óª╝';
      }

      final double vipCommission =
      _isVipActive
          ? getCommissionForVipLevel(vipId)
          : 0.0;

// --------------------------------------------------------
// COMPLETED TASKS
// --------------------------------------------------------

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

      final completedList = <Map<String, dynamic>>[];

      for (final doc in completedSnapshot.docs) {
        final data = doc.data();

        final String savedTaskId = data['taskId']?.toString() ?? doc.id;

        completedIds.add(
          savedTaskId,
        );

        completedList.add({
          'id': savedTaskId,
          'name': data['name'] ?? 'ÓªòÓª¥Óª£',
          'price': data['price'] ?? 0,
          'commission': data['commission'] ?? vipCommission,
        });
      }

// --------------------------------------------------------
// LOAD ALL WORK TASKS
// --------------------------------------------------------

      final snapshot = await _firestore.collection('work_tasks').get();

      final List<Map<String, dynamic>> tasks = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final bool active = data['active'] != false;

        if (!active) {
          continue;
        }

        final String productName =
            data['name']?.toString().trim().isNotEmpty == true
                ? data['name'].toString()
                : 'ÓªçÓª▓ÓºçÓªòÓªƒÓºìÓª░Óª¿Óª┐ÓªòÓºìÓª© Óª¬ÓªúÓºìÓª»';

        tasks.add({
          'id': doc.id,

// ÓªÂÓºüÓªºÓºü Óª¬ÓªúÓºìÓª»ÓºçÓª░ Óª¿Óª¥Óª«
          'name': productName,

// ÓªÂÓºüÓªºÓºü Óª¬ÓªúÓºìÓª»ÓºçÓª░ ÓªªÓª¥Óª«
          'price': data['price'] ?? 0,

// ÓªòÓª«Óª┐ÓªÂÓª¿ ÓªÅÓªûÓª¥Óª¿Óºç Óª░Óª¥ÓªûÓª¥ Óª╣ÓªÜÓºìÓªøÓºç Óª¿Óª¥
// UI-ÓªñÓºçÓªô ÓªªÓºçÓªûÓª¥Óª¿Óºï Óª╣Óª¼Óºç Óª¿Óª¥

          'category': data['category'] ?? 'Product',

          'active': true,
        });
      }

// --------------------------------------------------------
// UPDATE UI
// --------------------------------------------------------

      if (!mounted) {
        return;
      }

      setState(() {
        _currentVipId = vipId;

        _completedTaskIds
          ..clear()
          ..addAll(
            completedIds,
          );

        _completedTasksCount = completedIds.length;

        _completedTaskList
          ..clear()
          ..addAll(
            completedList,
          );

        _workTasks = tasks;

        _isLoadingUserData = false;

        _isLoadingTasks = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingUserData = false;

        _isLoadingTasks = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'ÓªñÓªÑÓºìÓª» Óª▓ÓºïÓªí ÓªòÓª░Óª¥ Óª»Óª¥ÓºƒÓª¿Óª┐: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

// ============================================================
// TASK STATUS
// ============================================================

  bool _isTaskCompleted(
    String taskId,
  ) {
    return _completedTaskIds.contains(taskId);
  }

  bool get _dailyLimitReached {
    return _completedTasksCount >= _dailyTaskLimit;
  }

// ============================================================
// AUTOMATIC PRODUCT IMAGE
//
// Óª¬ÓªúÓºìÓª»ÓºçÓª░ Óª¿Óª¥Óª«/ÓªòÓºìÓª»Óª¥ÓªƒÓª¥ÓªùÓª░Óª┐ ÓªªÓºçÓªûÓºç ÓªøÓª¼Óª┐ Óª¿Óª┐Óª░ÓºìÓª¼Óª¥ÓªÜÓª¿ ÓªòÓª░Óª¥ Óª╣Óª¼ÓºçÓÑñ
// ============================================================
  String getAutoImageUrl(
    String productName, {
    String? category,
  }) {
    final text = '${productName.toLowerCase()} '
        '${category?.toLowerCase() ?? ''}';

    // ============================================================
    // PRODUCT NUMBER Óª¼ÓºçÓª░ ÓªòÓª░Óª¥
    // Óª»ÓºçÓª«Óª¿:
    // ÓªçÓª▓ÓºçÓªòÓªƒÓºìÓª░Óª¿Óª┐Óªò Óª¬ÓªúÓºìÓª» ÓªåÓªçÓªƒÓºçÓª« #41
    // ÓªçÓª▓ÓºçÓªòÓªƒÓºìÓª░Óª¿Óª┐Óªò Óª¬ÓªúÓºìÓª» ÓªåÓªçÓªƒÓºçÓª« #64
    // ÓªçÓª▓ÓºçÓªòÓªƒÓºìÓª░Óª¿Óª┐Óªò Óª¬ÓªúÓºìÓª» ÓªåÓªçÓªƒÓºçÓª« #177
    // ============================================================

    final numberMatch = RegExp(r'#(\d+)').firstMatch(text);

    int itemNumber = 0;

    if (numberMatch != null) {
      itemNumber = int.tryParse(numberMatch.group(1) ?? '0') ?? 0;
    }

    // ============================================================
    // Óºº. Óª«ÓºïÓª¼Óª¥ÓªçÓª▓ / Óª½ÓºïÓª¿
    // ============================================================

    if (text.contains('phone') ||
        text.contains('mobile') ||
        text.contains('Óª«ÓºïÓª¼Óª¥ÓªçÓª▓') ||
        text.contains('Óª½ÓºïÓª¿') ||
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
    // Óº¿. Óª▓ÓºìÓª»Óª¥Óª¬ÓªƒÓª¬ / ÓªòÓª«ÓºìÓª¬Óª┐ÓªëÓªƒÓª¥Óª░
    // ============================================================

    if (text.contains('laptop') ||
        text.contains('Óª▓ÓºìÓª»Óª¥Óª¬ÓªƒÓª¬') ||
        text.contains('computer') ||
        text.contains('ÓªòÓª«ÓºìÓª¬Óª┐ÓªëÓªƒÓª¥Óª░')) {
      final images = [
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1593642702749-b7d2a804fbcf?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // Óº®. Óª╣ÓºçÓªíÓª½ÓºïÓª¿ / ÓªçÓª»Óª╝Óª¥Óª░Óª½ÓºïÓª¿
    // ============================================================

    if (text.contains('headphone') ||
        text.contains('earphone') ||
        text.contains('Óª╣ÓºçÓªíÓª½ÓºïÓª¿') ||
        text.contains('ÓªçÓºƒÓª¥Óª░Óª½ÓºïÓª¿') ||
        text.contains('ÓªçÓª»Óª╝Óª¥Óª░Óª½ÓºïÓª¿')) {
      final images = [
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1484704849700-f032a568e944?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1578319439584-104c94d37305?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1546435770-a3e426bf472b?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // Óº¬. ÓªÿÓªíÓª╝Óª┐
    // ============================================================

    if (text.contains('watch') ||
        text.contains('ÓªÿÓº£Óª┐') ||
        text.contains('ÓªÿÓªíÓª╝Óª┐')) {
      final images = [
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1524805444758-089113d48a6d?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1434056886845-dac89ffe9b56?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1526045431048-f857369baa09?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // Óº½. ÓªòÓºìÓª»Óª¥Óª«ÓºçÓª░Óª¥
    // ============================================================

    if (text.contains('camera') || text.contains('ÓªòÓºìÓª»Óª¥Óª«ÓºçÓª░Óª¥')) {
      final images = [
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1452780212940-6f5c0d14d848?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1606986628253-4f8b7b4c4e4f?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // Óº¼. TV
    // ============================================================

    if (text.contains('tv') ||
        text.contains('television') ||
        text.contains('ÓªƒÓª┐Óª¡Óª┐')) {
      final images = [
        'https://images.unsplash.com/photo-1593784991095-a205069470b6?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1461151304267-38535e780c79?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // Óº¡. Óª£ÓºüÓªñÓª¥ / Óª©ÓºìÓª»Óª¥Óª¿ÓºìÓªíÓºçÓª▓
    // ============================================================

    if (text.contains('shoe') ||
        text.contains('Óª£ÓºüÓªñÓª¥') ||
        text.contains('Óª©ÓºìÓª»Óª¥Óª¿ÓºìÓªíÓºçÓª▓') ||
        text.contains('Óª©ÓºçÓª¿ÓºìÓªíÓºçÓª▓') ||
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
    // Óº«. Óª¼ÓºìÓª»Óª¥Óªù
    // ============================================================

    if (text.contains('bag') ||
        text.contains('Óª¼ÓºìÓª»Óª¥Óªù') ||
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
    // Óº». ÓªÂÓª¥Óª░ÓºìÓªƒ / Óª¬ÓºïÓªÂÓª¥Óªò
    // ============================================================

    if (text.contains('shirt') ||
        text.contains('ÓªÂÓª¥Óª░ÓºìÓªƒ') ||
        text.contains('Óª£Óª¥Óª«Óª¥') ||
        text.contains('dress') ||
        text.contains('Óª¬ÓºïÓªÂÓª¥Óªò') ||
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
    // ÓººÓºª. Óª£ÓºìÓª»Óª¥ÓªòÓºçÓªƒ / ÓªÂÓºÇÓªñÓºçÓª░ Óª¬ÓºïÓªÂÓª¥Óªò
    // ============================================================

    if (text.contains('jacket') ||
        text.contains('Óª£ÓºìÓª»Óª¥ÓªòÓºçÓªƒ') ||
        text.contains('ÓªÂÓºÇÓªñ') ||
        text.contains('winter') ||
        text.contains('Óª©ÓºïÓºƒÓºçÓªƒÓª¥Óª░') ||
        text.contains('Óª©ÓºïÓª»Óª╝ÓºçÓªƒÓª¥Óª░') ||
        text.contains('Óª╣ÓºüÓªíÓª┐')) {
      final images = [
        'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1548883354-94bcfe321cbb?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ÓººÓºº. Óª¬ÓºìÓª»Óª¥Óª¿ÓºìÓªƒ / Óª£Óª┐Óª¿ÓºìÓª©
    // ============================================================

    if (text.contains('pant') ||
        text.contains('Óª¬ÓºìÓª»Óª¥Óª¿ÓºìÓªƒ') ||
        text.contains('jeans') ||
        text.contains('Óª£Óª┐Óª¿ÓºìÓª©')) {
      final images = [
        'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1604176354204-9268737828e4?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ÓººÓº¿. Óª«Óª¥Óªø ÓªºÓª░Óª¥ / Fishing
    // ============================================================

    if (text.contains('fishing') ||
        text.contains('fishing rod') ||
        text.contains('Óª½Óª┐ÓªÂÓª┐Óªé') ||
        text.contains('Óª«Óª¥Óªø ÓªºÓª░Óª¥') ||
        text.contains('Óª«Óª¥Óªø') ||
        text.contains('Óª¼Óº£ÓªÂÓª┐') ||
        text.contains('Óª¼ÓªíÓª╝ÓªÂÓª┐') ||
        text.contains('ÓªøÓª┐Óª¬')) {
      final images = [
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1534943441045-1009d7cbf8c0?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1445282768818-728615cc910a?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ÓººÓº®. ÓªòÓª©Óª«ÓºçÓªƒÓª┐ÓªòÓª© / Óª¬Óª¥Óª░Óª½Óª┐ÓªëÓª«
    // ============================================================

    if (text.contains('cosmetic') ||
        text.contains('ÓªòÓª©Óª«ÓºçÓªƒÓª┐Óªò') ||
        text.contains('lipstick') ||
        text.contains('Óª▓Óª┐Óª¬Óª©ÓºìÓªƒÓª┐Óªò') ||
        text.contains('perfume') ||
        text.contains('Óª¬Óª¥Óª░Óª½Óª┐ÓªëÓª«') ||
        text.contains('Óª©ÓºüÓªùÓª¿ÓºìÓªºÓª┐')) {
      final images = [
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1612817288484-6f916006741a?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1588405748880-12d1d2a59f75?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ÓººÓº¬. Óª░Óª¥Óª¿ÓºìÓª¿Óª¥ÓªÿÓª░ÓºçÓª░ Óª¬ÓªúÓºìÓª»
    // ============================================================

    if (text.contains('kitchen') ||
        text.contains('ÓªòÓª┐ÓªÜÓºçÓª¿') ||
        text.contains('Óª░Óª¥Óª¿ÓºìÓª¿Óª¥') ||
        text.contains('Óª╣Óª¥ÓªüÓº£Óª┐') ||
        text.contains('Óª╣Óª¥Óº£Óª┐') ||
        text.contains('Óª¬Óª¥ÓªñÓª┐Óª▓') ||
        text.contains('Óª¼Óª¥ÓªƒÓª┐')) {
      final images = [
        'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1556912167-f556f1f39fdf?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1556909212-d5b604d0c90d?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ÓººÓº½. USB / Flash Drive / Pendrive
    // ============================================================

    if (text.contains('usb') ||
        text.contains('flash drive') ||
        text.contains('pendrive') ||
        text.contains('Óª¬ÓºçÓª¿ÓªíÓºìÓª░Óª¥ÓªçÓª¡')) {
      final images = [
        'https://images.unsplash.com/photo-1625842268584-8f3296236761?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1614064641938-3bbee52942c7?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ÓººÓº¼. Charger
    // ============================================================

    if (text.contains('charger') ||
        text.contains('ÓªÜÓª¥Óª░ÓºìÓª£Óª¥Óª░') ||
        text.contains('charging')) {
      final images = [
        'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1609592424848-2f4f0e7b2f77?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ÓººÓº¡. Cable
    // ============================================================

    if (text.contains('cable') ||
        text.contains('ÓªòÓºçÓª¼Óª▓') ||
        text.contains('ÓªñÓª¥Óª░')) {
      final images = [
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1544724569-5f546fd6f2b5?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1625842268584-8f3296236761?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ÓººÓº«. Speaker / Bluetooth
    // ============================================================

    if (text.contains('speaker') ||
        text.contains('Óª©ÓºìÓª¬Óª┐ÓªòÓª¥Óª░') ||
        text.contains('bluetooth') ||
        text.contains('Óª¼ÓºìÓª▓ÓºüÓªƒÓºüÓªÑ')) {
      final images = [
        'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1589003077984-894e133dabab?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // ÓººÓº». Power Bank
    // ============================================================

    if (text.contains('power bank') ||
        text.contains('Óª¬Óª¥ÓªôÓª»Óª╝Óª¥Óª░ Óª¼ÓºìÓª»Óª¥ÓªéÓªò') ||
        text.contains('Óª¬Óª¥ÓªôÓºƒÓª¥Óª░ Óª¼ÓºìÓª»Óª¥ÓªéÓªò')) {
      final images = [
        'https://images.unsplash.com/photo-1609592424848-2f4f0e7b2f77?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1609592424632-9d9c5c8c7d8e?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1591290619762-c588c4f0a6c5?auto=format&fit=crop&w=600&q=80',
      ];

      return images[itemNumber % images.length];
    }

    // ============================================================
    // Óº¿Óºª. Router / WiFi
    // ============================================================

    if (text.contains('router') ||
        text.contains('Óª░Óª¥ÓªëÓªƒÓª¥Óª░') ||
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
    // Óº¿Óºº. Óª©Óª¥ÓªºÓª¥Óª░Óªú ELECTRONIC Óª¬ÓªúÓºìÓª»
    //
    // ÓªÅÓªòÓªç Óª¿Óª¥Óª« Óª╣Óª▓ÓºçÓªô # Óª¿Óª«ÓºìÓª¼Óª░ ÓªàÓª¿ÓºüÓª»Óª¥ÓºƒÓºÇ ÓªåÓª▓Óª¥ÓªªÓª¥ ÓªøÓª¼Óª┐ÓÑñ
    // ============================================================

    if (text.contains('electronic') ||
        text.contains('electronics') ||
        text.contains('ÓªçÓª▓ÓºçÓªòÓªƒÓºìÓª░Óª¿Óª┐Óªò')) {
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

      return electronicImages[itemNumber % electronicImages.length];
    }

    // ============================================================
    // Óº¿Óº¿. Óª©Óª¥ÓªºÓª¥Óª░Óªú Óª¬ÓªúÓºìÓª»ÓºçÓª░ Óª£Óª¿ÓºìÓª»
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

    return generalImages[itemNumber % generalImages.length];
  }

  Widget _buildProductImage(
    Map<String, dynamic> product,
  ) {
    final String name = product['name']?.toString() ?? 'Óª¬ÓªúÓºìÓª»';

    final String? category = product['category']?.toString();

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
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Colors.grey.shade500,
              size: 30,
            ),
          );
        },
        loadingBuilder: (context, child, loading) {
          if (loading == null) {
            return child;
          }

          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(
                10,
              ),
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
// PART 2 - TASK COMPLETION + WORKSPACE
// ============================================================

  Future<void> _completeTask(Map<String, dynamic> task) async {
    final user = _currentUser;
    if (user == null) return;

    if (!_isVipActive ||
        _currentVipId == 'none' ||
        _shopDeposit <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ÓªòÓª¥Óª£ ÓªòÓª░ÓªñÓºç Óª╣Óª▓Óºç ÓªåÓªùÓºç ÓªíÓª┐Óª¬ÓºïÓª£Óª┐Óªƒ ÓªòÓª░Óºç VIP Óª▓ÓºçÓª¡ÓºçÓª▓ Óª©ÓªòÓºìÓª░Óª┐Óª»Óª╝ ÓªòÓª░ÓªñÓºç Óª╣Óª¼ÓºçÓÑñ',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final String taskId = task['id']?.toString() ?? '';

    if (taskId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Óª¬ÓªúÓºìÓª»ÓºçÓª░ ID Óª¬Óª¥ÓªôÓºƒÓª¥ Óª»Óª¥ÓºƒÓª¿Óª┐ÓÑñ'),
          ),
        );
      }
      return;
    }

    if (_dailyLimitReached) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ÓªåÓª£ÓªòÓºçÓª░ $_dailyTaskLimit ÓªƒÓª┐ ÓªòÓª¥Óª£ ÓªçÓªñÓª┐Óª«ÓªºÓºìÓª»Óºç Óª©Óª«ÓºìÓª¬Óª¿ÓºìÓª¿ Óª╣ÓºƒÓºçÓªøÓºçÓÑñ',
            ),
          ),
        );
      }
      return;
    }

    if (_isTaskCompleted(taskId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ÓªÅÓªç ÓªòÓª¥Óª£ÓªƒÓª┐ ÓªçÓªñÓª┐Óª«ÓªºÓºìÓª»Óºç Óª©Óª«ÓºìÓª¬Óª¿ÓºìÓª¿ ÓªòÓª░Óª¥ Óª╣ÓºƒÓºçÓªøÓºçÓÑñ'),
          ),
        );
      }
      return;
    }

    if (_isCompletingTask) return;

    setState(() {
      _isCompletingTask = true;
    });

    try {
      final double commission = _currentVipUnitPrice;
      final double price = _toDouble(task['price']);
      final String taskName = task['name']?.toString() ?? 'ÓªòÓª¥Óª£';
      final String dateKey = _todayKey();

      final userRef = _firestore.collection('users').doc(user.uid);

      final completedTaskRef =
      userRef.collection('completed_tasks').doc('${dateKey}_$taskId');

      final transactionRef = userRef.collection('transactions').doc();

      // Óª½Óª¥ÓºƒÓª¥Óª░Óª©ÓºìÓªƒÓºïÓª░ ÓªƒÓºìÓª░Óª¥Óª¿Óª£ÓºìÓª»Óª¥ÓªòÓªÂÓª¿: ÓªòÓª¥Óª£ Óª©Óª«ÓºìÓª¬Óª¿ÓºìÓª¿, ÓªƒÓºìÓª░Óª¥Óª¿Óª£ÓºìÓª»Óª¥ÓªòÓªÂÓª¿ ÓªÅÓª¼Óªé ÓªçÓªëÓª£Óª¥Óª░ÓºçÓª░ Óª«ÓºçÓªçÓª¿ Óª¼ÓºìÓª»Óª¥Óª▓ÓºçÓª¿ÓºìÓª© ÓªåÓª¬ÓªíÓºçÓªƒ Óª╣Óª¼Óºç
      await _firestore.runTransaction((transaction) async {
        final completedSnapshot = await transaction.get(completedTaskRef);

        if (completedSnapshot.exists) {
          throw Exception('TASK_ALREADY_COMPLETED');
        }

        // ÓªçÓªëÓª£Óª¥Óª░ÓºçÓª░ Óª¼Óª░ÓºìÓªñÓª«Óª¥Óª¿ ÓªíÓª¥ÓªƒÓª¥ Óª½ÓºçÓªÜ ÓªòÓª░Óºç Óª¼ÓºìÓª»Óª¥Óª▓ÓºçÓª¿ÓºìÓª© Óª╣Óª┐Óª©Óª¥Óª¼ ÓªòÓª░Óª¥
        final userSnapshot = await transaction.get(userRef);
        double currentDbBalance = 0.0;
        if (userSnapshot.exists) {
          final data = userSnapshot.data() as Map<String, dynamic>;
          currentDbBalance = _toDouble(data['shopDeposit'] ?? data['balance'] ?? 0.0);
        }
        double newDbBalance = currentDbBalance + commission;

        // Óºº. completed_tasks ÓªÅ Óª░ÓºçÓªòÓª░ÓºìÓªí ÓªñÓºêÓª░Óª┐ (ÓªíÓºüÓª¬ÓºìÓª▓Óª┐ÓªòÓºçÓªƒ ÓªåÓªƒÓªòÓª¥Óª¿ÓºïÓª░ Óª£Óª¿ÓºìÓª»)
        transaction.set(
          completedTaskRef,
          {
            'taskId': taskId,
            'name': taskName,
            'price': price,
            'commission': commission,
            'vipLevel': _currentVipId,
            'dateKey': dateKey,
            'completedAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
          },
        );

        // Óº¿. transactions Óª╣Óª┐Óª©ÓºìÓªƒÓºìÓª░Óª┐ÓªñÓºç Óª░ÓºçÓªòÓª░ÓºìÓªí ÓªñÓºêÓª░Óª┐
        transaction.set(
          transactionRef,
          {
            'type': 'task_commission',
            'amount': commission,
            'title': taskName,
            'taskId': taskId,
            'vipLevel': _currentVipId,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
          },
        );

        // Óº®. ÓªçÓªëÓª£Óª¥Óª░ÓºçÓª░ Óª«ÓºéÓª▓ Óª¼ÓºìÓª»Óª¥Óª▓ÓºçÓª¿ÓºìÓª© Óª½Óª¥ÓºƒÓª¥Óª░Óª©ÓºìÓªƒÓºïÓª░Óºç Óª¬Óª¥Óª░ÓºìÓª«Óª¥Óª¿ÓºçÓª¿ÓºìÓªƒÓª▓Óª┐ ÓªåÓª¬ÓªíÓºçÓªƒ ÓªòÓª░Óª¥ (Óª»Óª¥ÓªñÓºç ÓªàÓºìÓª»Óª¥Óª¬ Óª░Óª┐Óª©ÓºìÓªƒÓª¥Óª░ÓºìÓªƒ ÓªªÓª┐Óª▓ÓºçÓªô ÓªƒÓª¥ÓªòÓª¥ Óª¿Óª¥ ÓªòÓª«Óºç)
        transaction.update(userRef, {
          'shopDeposit': newDbBalance,
          'balance': newDbBalance,
        });
      });

      if (!mounted) return;

      // Óª▓ÓºïÓªòÓª¥Óª▓ Óª©ÓºìÓªƒÓºçÓªƒÓºç Óª¼ÓºìÓª»Óª¥Óª▓ÓºçÓª¿ÓºìÓª© Óªô ÓªçÓª¿ÓªòÓª¥Óª« ÓªåÓª¬ÓªíÓºçÓªƒ ÓªòÓª░Óª¥
      setState(() {
        _completedTaskIds.add(taskId);
        _completedTasksCount++;

        _userBalance += commission;
        _todayEarnings += commission;
        _totalEarnings += commission;
        _shopDeposit += commission; // Óª▓ÓºïÓªòÓª¥Óª▓ Óª¡ÓºçÓª░Óª┐Óª»Óª╝ÓºçÓª¼Óª▓ Óª©Óª┐ÓªéÓªò Óª░Óª¥ÓªûÓª¥Óª░ Óª£Óª¿ÓºìÓª»

        _completedTaskList.add(
          {
            'id': taskId,
            'name': taskName,
            'price': price,
            'commission': commission,
          },
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ÓªòÓª¥Óª£ Óª©Óª«ÓºìÓª¬Óª¿ÓºìÓª¿ Óª╣ÓºƒÓºçÓªøÓºç! ÓªòÓª«Óª┐ÓªÂÓª¿ Óº│ ${commission.toStringAsFixed(2)} Óª»ÓºïÓªù Óª╣ÓºƒÓºçÓªøÓºçÓÑñ',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'ÓªòÓª¥Óª£ ÓªòÓª░ÓªñÓºç Óª╣Óª▓Óºç ÓªåÓªùÓºç ÓªíÓª┐Óª¬ÓºïÓª£Óª┐Óªƒ ÓªòÓª░Óºç VIP Óª▓ÓºçÓª¡ÓºçÓª▓ Óª©ÓªòÓºìÓª░Óª┐Óª»Óª╝ ÓªòÓª░ÓªñÓºç Óª╣Óª¼ÓºçÓÑñ';
      if (e.code == 'unavailable') {
        message = 'ÓªçÓª¿ÓºìÓªƒÓª¥Óª░Óª¿ÓºçÓªƒ Óª¼Óª¥ Firebase Óª©ÓªéÓª»ÓºïÓªù Óª¬Óª¥ÓªôÓºƒÓª¥ Óª»Óª¥ÓªÜÓºìÓªøÓºç Óª¿Óª¥ÓÑñ';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errMessage = e.toString();
      if (errMessage.contains('TASK_ALREADY_COMPLETED')) {
        errMessage = 'ÓªÅÓªç ÓªòÓª¥Óª£ÓªƒÓª┐ ÓªçÓªñÓª┐Óª«ÓªºÓºìÓª»Óºç Óª©Óª«ÓºìÓª¬Óª¿ÓºìÓª¿ ÓªòÓª░Óª¥ Óª╣ÓºƒÓºçÓªøÓºçÓÑñ';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ÓªòÓª¥Óª£ Óª©Óª«ÓºìÓª¬Óª¿ÓºìÓª¿ ÓªòÓª░Óª¥ Óª»Óª¥ÓºƒÓª¿Óª┐: $errMessage',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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

  void _confirmOrderDialog(
      Map<String, dynamic> product,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ÓªòÓª¥Óª£ Óª¿Óª┐ÓªÂÓºìÓªÜÓª┐ÓªñÓªòÓª░Óªú'),
          content: Text(
            '${product['name'] ?? 'ÓªòÓª¥Óª£'}\n\n'
                'Óª«ÓºéÓª▓ÓºìÓª»: Óº│ ${product['price'] ?? 0}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Óª¼Óª¥ÓªñÓª┐Óª▓'),
            ),
            ElevatedButton(
              onPressed: _isCompletingTask
                  ? null
                  : () {
                Navigator.pop(dialogContext);
                _completeTask(product);
              },
              child: const Text('Óª¿Óª┐ÓªÂÓºìÓªÜÓª┐Óªñ ÓªòÓª░ÓºüÓª¿'),
            ),
          ],
        );
      },
    );
  }
  Widget _buildWorkSpacePage() {
    return Column(
      children: [
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
                    'ÓªªÓºêÓª¿Óª┐Óªò ÓªòÓª¥Óª£ ($_currentVipName)',
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
                'ÓªåÓª£ÓªòÓºçÓª░ Óª©Óª«ÓºìÓª¬Óª¿ÓºìÓª¿ ÓªòÓª¥Óª£: '
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
                    : (_completedTasksCount / _dailyTaskLimit).clamp(0.0, 1.0),
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
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
              'ÓªòÓºïÓª¿Óºï ÓªòÓª¥Óª£ Óª¬Óª¥ÓªôÓºƒÓª¥ Óª»Óª¥ÓºƒÓª¿Óª┐!',
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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = _workTasks[index];

                final String taskId = product['id']?.toString() ?? '';

                final bool completed = _isTaskCompleted(taskId);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: completed
                        ? Colors.green.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: completed
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(
                              getAutoImageUrl(
                                product['name']?.toString() ?? '',
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name']?.toString() ?? 'Óª¬ÓªúÓºìÓª»',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ÓªªÓª¥Óª«: Óº│ ${product['price'] ?? 0}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      completed
                          ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Óª©Óª«ÓºìÓª¬Óª¿ÓºìÓª¿',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : IconButton(
                        onPressed: _isCompletingTask
                            ? null
                            : () {
                          if (!_isVipActive ||
                              _currentVipId == null ||
                              _currentVipId.isEmpty ||
                              _currentVipId == 'none' ||
                              _shopDeposit <= 0) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'ÓªòÓª¥Óª£ ÓªòÓª░ÓªñÓºç Óª╣Óª▓Óºç ÓªåÓªùÓºç ÓªíÓª┐Óª¬ÓºïÓª£Óª┐Óªƒ ÓªòÓª░Óºç VIP Óª▓ÓºçÓª¡ÓºçÓª▓ Óª©ÓªòÓºìÓª░Óª┐Óª»Óª╝ ÓªòÓª░ÓªñÓºç Óª╣Óª¼ÓºçÓÑñ'),
                                backgroundColor:
                                Colors.red,
                              ),
                            );
                          } else {
                            _confirmOrderDialog(product);
                          }
                        },
                        icon: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.redAccent,
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
                          'Óª¼ÓºìÓª»Óª¥Óª▓ÓºçÓª¿ÓºìÓª©',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Óº│ ${_userBalance.toStringAsFixed(2)}',
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
                        'Óª«Óª¥Óª¿Óª┐Óª¼ÓºìÓª»Óª¥ÓªùÓºç Óª¬ÓºìÓª░Óª¼ÓºçÓªÂ',
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
                  'ÓªªÓºïÓªòÓª¥Óª¿ÓºçÓª░ Óª£Óª¥Óª«Óª¥Óª¿Óªñ  Óº│ ${_shopDeposit.toStringAsFixed(0)}',
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
                          // ÓªíÓºïÓª«ÓºçÓªçÓª¿ Óª¿Óª¥Óª« shopayshop.com ÓªåÓª¬ÓªíÓºçÓªƒ ÓªòÓª░Óª¥ Óª╣Óª▓Óºï
                          'ÓªåÓª«Óª¿ÓºìÓªñÓºìÓª░Óªú Óª▓Óª┐ÓªéÓªò: https://shopayshop.com/register?ref=${_currentUser?.uid ?? ''}',
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
                              content: Text('Óª░ÓºçÓª½Óª¥Óª░ÓºçÓª▓ Óª▓Óª┐ÓªéÓªò ÓªòÓª¬Óª┐ ÓªòÓª░Óª¥ Óª╣ÓºƒÓºçÓªøÓºç!'),
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
                            'ÓªòÓª¬Óª┐ ÓªòÓª░ÓºüÓª¿',
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
                'Óª©Óª¼Óª¥Óªç Óª¼ÓºìÓª»Óª¼Óª╣Óª¥Óª░ ÓªòÓª░ÓªøÓºç',
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
                title: 'Óª¬ÓºìÓª░ÓªñÓª┐ÓªªÓª┐Óª¿ Óª▓Óª¥ÓªòÓª┐ ÓªíÓºìÓª░',
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
                title: 'Óª©ÓºçÓª░Óª¥ ÓªòÓª░ÓºìÓª«ÓºÇ Óª¬ÓºüÓª░Óª©ÓºìÓªòÓª¥Óª░',
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
                title: 'ÓªªÓºïÓªòÓª¥Óª¿',
                icon: Icons.storefront_rounded,
                iconColor: Colors.deepOrange,
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              ),
              _buildGridOptionTile(
                title: "What's up ÓªÅ Óª»Óª¥Óª¿",
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
                title: 'Óª©Óª¥Óª¬ÓºïÓª░ÓºìÓªƒ Óª«ÓºìÓª»Óª¥Óª¿ÓºçÓª£Óª¥Óª░',
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
          // ÓªåÓª«Óª¥ÓªªÓºçÓª░ ÓªƒÓª┐Óª« (Team) ÓªàÓª¬ÓªÂÓª¿ Óª¼Óª¥ÓªƒÓª¿ (ÓªíÓºìÓª»Óª¥ÓªÂÓª¼ÓºïÓª░ÓºìÓªí Óª©ÓºìÓªòÓºìÓª░Óª┐Óª¿ÓºçÓª░ Óª£Óª¿ÓºìÓª»)
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
                          'ÓªåÓª«Óª¥ÓªªÓºçÓª░ ÓªƒÓª┐Óª«',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ÓªåÓª¬Óª¿Óª¥Óª░ Óª░ÓºçÓª½Óª¥Óª░ ÓªòÓª░Óª¥ Óª©ÓªªÓª©ÓºìÓª» Óªô ÓªòÓª«Óª┐ÓªÂÓª¿ ÓªªÓºçÓªûÓºüÓª¿',
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
          _buildNavItem(0, Icons.check_box_outline_blank, 'ÓªòÓª░ÓºìÓª«ÓªòÓºìÓªÀÓºçÓªñÓºìÓª░'),
          _buildNavItem(1, Icons.assignment_outlined, 'Óª¬ÓªúÓºìÓª»ÓªàÓª░ÓºìÓªíÓª¥Óª░'),
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
          _buildNavItem(3, Icons.diamond_outlined, 'ÓªªÓºïÓªòÓª¥Óª¿ÓºçÓª░Óª©ÓºìÓªñÓª░'),
          _buildNavItem(4, Icons.sentiment_satisfied_alt_outlined, 'ÓªåÓª«Óª¥Óª░'),
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
          _currentIndex == 0 ? 'Shopay - ÓªòÓª░ÓºìÓª«ÓªòÓºìÓªÀÓºçÓªñÓºìÓª░' : 'Shopay',
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
