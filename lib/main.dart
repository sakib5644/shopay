import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

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

      // =========================================================
      // ROUTING
      // =========================================================

      onGenerateRoute: (settings) {
        final uri = Uri.base;

        // -------------------------------------------------------
        // Normal route
        // -------------------------------------------------------

        String routePath = settings.name ?? '/';

        // -------------------------------------------------------
        // GitHub Pages 404.html থেকে আসা route
        //
        // উদাহরণ:
        // /shopay/index.html?route=%2Fregister&ref=ABC123
        // -------------------------------------------------------

        final githubRoute =
        uri.queryParameters['route'];

        if (githubRoute != null &&
            githubRoute.isNotEmpty) {
          routePath = Uri.decodeComponent(githubRoute);
        }

        // -------------------------------------------------------
        // Registration route
        // -------------------------------------------------------

        if (routePath == '/register' ||
            routePath == '/register/') {

          String? referrerId =
          uri.queryParameters['ref'];

          if (referrerId != null) {
            referrerId = referrerId.trim();
          }

          if (referrerId != null &&
              referrerId.isEmpty) {
            referrerId = null;
          }

          return MaterialPageRoute(
            builder: (context) {
              return RegistrationScreen(
                referrerId: referrerId,
              );
            },
            settings: settings,
          );
        }

        // -------------------------------------------------------
        // Default Login
        // -------------------------------------------------------

        return MaterialPageRoute(
          builder: (context) {
            return const LoginScreen();
          },
          settings: settings,
        );
      },

      // সাধারণভাবে Login Screen
      home: const LoginScreen(),
    );
  }
}