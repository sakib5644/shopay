import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isObscure = true;
  bool _isLoading = false;

  String _captchaCode = '';

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  // =========================
  // CAPTCHA তৈরি
  // =========================
  void _generateCaptcha() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();

    String code = '';

    for (int i = 0; i < 5; i++) {
      code += characters[random.nextInt(characters.length)];
    }

    setState(() {
      _captchaCode = code;
      _captchaController.clear();
    });
  }

  // =========================
  // LOGIN
  // =========================
  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final captcha = _captchaController.text.trim().toUpperCase();

    // ফোন
    if (phone.isEmpty) {
      _showMessage(
        'Please enter your phone number.',
        Colors.orange,
      );
      return;
    }

    // বাংলাদেশি ফোন নম্বর
    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(phone)) {
      _showMessage(
        'Please enter a valid Bangladesh phone number.',
        Colors.orange,
      );
      return;
    }

    // Password
    if (password.isEmpty) {
      _showMessage(
        'Please enter your password.',
        Colors.orange,
      );
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must be at least 6 characters.',
        Colors.orange,
      );
      return;
    }

    // CAPTCHA
    if (captcha.isEmpty) {
      _showMessage(
        'Please enter the verification code.',
        Colors.orange,
      );
      return;
    }

    if (captcha != _captchaCode) {
      _showMessage(
        'Incorrect verification code.',
        Colors.red,
      );

      _generateCaptcha();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      /*
       * ফোন নম্বর থেকে internal email তৈরি করছি।
       *
       * যেমন:
       * 01712345678
       *
       * হবে:
       * 01712345678@shopay.app
       */
      final loginEmail = '$phone@shopay.app';

      // Firebase থেকে Login যাচাই
      await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      if (!mounted) return;

      final user = _auth.currentUser;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Login successful!',
        Colors.green,
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      // =========================
      // Dashboard
      // =========================
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            userName:
            user?.displayName ?? 'Shopay User',
            userPhone: phone,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String message;

      switch (e.code) {
        case 'user-not-found':
          message =
          'This phone number is not registered.';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message =
          'Phone number or password is incorrect.';
          break;

        case 'invalid-email':
          message = 'Invalid phone number.';
          break;

        case 'too-many-requests':
          message =
          'Too many attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
          'Internet connection problem.';
          break;

        default:
          message =
          'Login failed. Please check your phone number and password.';
      }

      _showMessage(
        message,
        Colors.red,
      );

      _generateCaptcha();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Something went wrong. Please try again.',
        Colors.red,
      );

      _generateCaptcha();
    }
  }

  // =========================
  // Message
  // =========================
  void _showMessage(
      String message,
      Color color,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                // =========================
                // Logo
                // =========================
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Colors.redAccent,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Login to continue with Shopay',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 36),

                // =========================
                // Phone
                // =========================
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  textInputAction:
                  TextInputAction.next,
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Phone Number',
                    hintText: '01XXXXXXXXX',
                    prefixIcon: const Icon(
                      Icons.phone_android_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // Password
                // =========================
                TextField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  textInputAction:
                  TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure =
                          !_isObscure;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // CAPTCHA
                // =========================
                const Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                          Colors.grey.shade200,
                          borderRadius:
                          BorderRadius.circular(12),
                          border: Border.all(
                            color:
                            Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _captchaCode,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight:
                            FontWeight.bold,
                            letterSpacing: 7,
                            fontStyle:
                            FontStyle.italic,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    SizedBox(
                      height: 56,
                      width: 56,
                      child: IconButton(
                        onPressed:
                        _generateCaptcha,
                        style:
                        IconButton.styleFrom(
                          backgroundColor:
                          Colors.grey.shade100,
                        ),
                        icon: const Icon(
                          Icons.refresh,
                          color:
                          Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                TextField(
                  controller:
                  _captchaController,
                  textCapitalization:
                  TextCapitalization.characters,
                  keyboardType:
                  TextInputType.text,
                  maxLength: 5,
                  decoration: InputDecoration(
                    counterText: '',
                    labelText:
                    'Enter verification code',
                    hintText:
                    'Type the code above',
                    prefixIcon: const Icon(
                      Icons.verified_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // =========================
                // Login Button
                // =========================
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                    _isLoading ? null : _login,
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.redAccent,
                      foregroundColor:
                      Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // Register
                // =========================
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const RegistrationScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}