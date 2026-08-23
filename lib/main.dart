import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ফায়ারবেস অপশন ফাইলটি কানেক্ট করা হলো

import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ফ্লাটার ওয়েবের জন্য সঠিক প্ল্যাটফর্ম অপশনসহ ফায়ারবেস ইনিশিয়ালাইজ করা
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const ShopayApp());
}

class ShopayApp extends StatelessWidget {
  const ShopayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopay',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),

      // ফ্লাটার ওয়েবে রাউটিং নিখুঁত রাখতে onGenerateRoute ব্যবহার করা হয়েছে
      onGenerateRoute: (settings) {
        final uri = Uri.base;
        String routePath = settings.name ?? '/';

        // GitHub Pages fallback route check
        final githubRoute = uri.queryParameters['route'];
        if (githubRoute != null && githubRoute.isNotEmpty) {
          routePath = Uri.decodeComponent(githubRoute);
        }

        // যদি লিংকে #/register থাকে
        if (routePath.contains('/register')) {
          String? referrerId = uri.queryParameters['ref'];

          if (referrerId != null) {
            referrerId = referrerId.trim();
            if (referrerId.isEmpty) {
              referrerId = null;
            }
          }

          return MaterialPageRoute(
            builder: (context) => RegistrationScreen(
              referrerId: referrerId,
            ),
            settings: settings,
          );
        }

        // ডিফল্ট বা অন্য সব ক্ষেত্রে LoginScreen দেখাবে
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
          settings: settings,
        );
      },
    );
  }
}