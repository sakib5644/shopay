import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String? referrerId;

  const RegistrationScreen({
    super.key,
    this.referrerId,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
final _nameController = TextEditingController();
final _phoneController = TextEditingController();
final _passwordController = TextEditingController();
final _captchaController = TextEditingController();

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

bool _isObscure = true;
bool _isLoading = false;

String _captchaCode = '';

// ============================================================
// REFERRAL ID
// ============================================================

String? get _referrerId {
final ref = widget.referrerId?.trim();

if (ref == null || ref.isEmpty) {
return null;
}

return ref;
}

@override
void initState() {
super.initState();
_generateCaptcha();
}

@override
void dispose() {
_nameController.dispose();
_phoneController.dispose();
_passwordController.dispose();
_captchaController.dispose();
super.dispose();
}

// ============================================================
// CAPTCHA
// ============================================================

void _generateCaptcha() {
const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

final random = Random();

String code = '';

for (int i = 0; i < 5; i++) {
code += characters[random.nextInt(characters.length)];
}

if (!mounted) return;

setState(() {
_captchaCode = code;
_captchaController.clear();
});
}

// ============================================================
// REGISTER
// ============================================================

Future<void> _registerAccount() async {
final name = _nameController.text.trim();
final phone = _phoneController.text.trim();
final password = _passwordController.text.trim();
final captcha = _captchaController.text.trim().toUpperCase();

// ----------------------------------------------------------
// Name
// ----------------------------------------------------------

if (name.isEmpty) {
_showMessage(
'Please enter your full name.',
Colors.orange,
);
return;
}

// ----------------------------------------------------------
// Phone
// ----------------------------------------------------------

if (phone.isEmpty) {
_showMessage(
'Please enter your phone number.',
Colors.orange,
);
return;
}

if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(phone)) {
_showMessage(
'Please enter a valid Bangladesh phone number.',
Colors.orange,
);
return;
}

// ----------------------------------------------------------
// Password
// ----------------------------------------------------------

if (password.length < 6) {
_showMessage(
'Password must be at least 6 characters.',
Colors.orange,
);
return;
}

// ----------------------------------------------------------
// CAPTCHA
// ----------------------------------------------------------

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

// ----------------------------------------------------------
// Loading
// ----------------------------------------------------------

setState(() {
_isLoading = true;
});

User? createdUser;

try {
// ========================================================
// INTERNAL EMAIL
// ========================================================

final loginEmail = '$phone@shopay.app';

// ========================================================
// FIREBASE AUTH ACCOUNT CREATE
// ========================================================

final userCredential =
await _auth.createUserWithEmailAndPassword(
email: loginEmail,
password: password,
);

createdUser = userCredential.user;

if (createdUser == null) {
throw Exception(
'Firebase user account could not be created.',
);
}

// ========================================================
// DISPLAY NAME
// ========================================================

await createdUser.updateDisplayName(name);

// ========================================================
// REFERRAL DATA
// ========================================================

final referralId = _referrerId;

// ========================================================
// USER FIRESTORE DATA
// ========================================================

final userData = <String, dynamic>{
'uid': createdUser.uid,
'name': name,
'phone': phone,
'loginEmail': loginEmail,
'balance': 0.0,
'shopDeposit': 0.0,
'vipLevel': 'V1',
'luckyDrawChances': 0,
'status': 'active',
'referredBy': referralId ?? 'none',
'createdAt': FieldValue.serverTimestamp(),
};

// ========================================================
// CREATE USER DOCUMENT
// ========================================================

await _firestore
.collection('users')
.doc(createdUser.uid)
.set(userData);

// ========================================================
// REFERRAL MEMBER COUNT
// ========================================================

if (referralId != null) {
final referrerRef =
_firestore.collection('users').doc(referralId);

final referrerSnapshot =
await referrerRef.get();

if (referrerSnapshot.exists) {
await referrerRef.update({
'referredMembers':
FieldValue.increment(1),
});
}
}

// ========================================================
// SIGN OUT
// ========================================================

await _auth.signOut();

if (!mounted) return;

setState(() {
_isLoading = false;
});

// ========================================================
// SUCCESS MESSAGE
// ========================================================

_showMessage(
referralId != null
? 'Account created successfully! Referral added.'
: 'Account created successfully! Please login.',
Colors.green,
);

await Future.delayed(
const Duration(milliseconds: 800),
);

if (!mounted) return;

// ========================================================
// GO TO LOGIN
// ========================================================

Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(
builder: (context) => const LoginScreen(),
),
(route) => false,
);
} on FirebaseAuthException catch (e) {
if (createdUser != null) {
try {
await createdUser.delete();
} catch (_) {}
}

if (!mounted) return;

setState(() {
_isLoading = false;
});

String message;

switch (e.code) {
case 'email-already-in-use':
message =
'This phone number is already registered.';
break;

case 'weak-password':
message =
'Password is too weak. Use at least 6 characters.';
break;

case 'invalid-email':
message = 'Invalid phone number.';
break;

case 'network-request-failed':
message =
'Internet connection problem.';
break;

default:
message =
e.message ?? 'Account creation failed.';
}

_showMessage(
message,
Colors.red,
);

_generateCaptcha();
} catch (e) {
if (createdUser != null) {
try {
await createdUser.delete();
} catch (_) {}
}

if (!mounted) return;

setState(() {
_isLoading = false;
});

_showMessage(
'Registration failed. Please try again.',
Colors.red,
);

_generateCaptcha();
}
}

// ============================================================
// MESSAGE
// ============================================================

void _showMessage(
String message,
Color color,
) {
if (!mounted) return;

ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor: color,
behavior: SnackBarBehavior.floating,
),
);
}
  @override
  Widget build(BuildContext context) {
    final hasReferral = _referrerId != null;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: _isLoading
              ? null
              : () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,

              children: [
                // ==================================================
                // LOGO
                // ==================================================

                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 75,
                  color: Colors.redAccent,
                ),

                const SizedBox(height: 14),

                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Create your Shopay account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                // ==================================================
                // REFERRAL NOTICE
                // ==================================================

                if (hasReferral) ...[
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius:
                      BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.shade200,
                      ),
                    ),

                    child: const Text(
                      '🎉 You are registering via a referral invitation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ==================================================
                // NAME
                // ==================================================

                TextField(
                  controller: _nameController,

                  textInputAction:
                  TextInputAction.next,

                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',

                    prefixIcon: const Icon(
                      Icons.person_outline,
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // PHONE
                // ==================================================

                TextField(
                  controller: _phoneController,

                  keyboardType:
                  TextInputType.phone,

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

                // ==================================================
                // PASSWORD
                // ==================================================

                TextField(
                  controller: _passwordController,

                  obscureText: _isObscure,

                  textInputAction:
                  TextInputAction.done,

                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText:
                    'Minimum 6 characters',

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

                // ==================================================
                // CAPTCHA TITLE
                // ==================================================

                const Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // CAPTCHA DISPLAY
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,

                        alignment:
                        Alignment.center,

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
                        _isLoading
                            ? null
                            : _generateCaptcha,

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

                // ==================================================
                // CAPTCHA INPUT
                // ==================================================

                TextField(
                  controller:
                  _captchaController,

                  textCapitalization:
                  TextCapitalization.characters,

                  keyboardType:
                  TextInputType.text,

                  maxLength: 5,

                  textInputAction:
                  TextInputAction.done,

                  decoration: InputDecoration(
                    counterText: '',

                    labelText:
                    'Enter verification code',

                    hintText:
                    'Type the code above',

                    prefixIcon:
                    const Icon(
                      Icons.verified_outlined,
                    ),

                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // REGISTER BUTTON
                // ==================================================

                SizedBox(
                  height: 56,

                  child: ElevatedButton(
                    onPressed:
                    _isLoading
                        ? null
                        : _registerAccount,

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
                        color:
                        Colors.white,
                      ),
                    )
                        : const Text(
                      'Register',

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // LOGIN
                // ==================================================

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [
                    const Text(
                      'Already have an account? ',
                    ),

                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () =>
                          Navigator.pop(
                            context,
                          ),

                      child: const Text(
                        'Login',

                        style: TextStyle(
                          color:
                          Colors.redAccent,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}