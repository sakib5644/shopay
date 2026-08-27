import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDepositRequestsScreen extends StatelessWidget {
const AdminDepositRequestsScreen({super.key});

// ============================================================
// VIP LEVEL নির্ধারণ
// ============================================================

String? _getVipLevel(double amount) {
if (amount == 3000) {
return 'V1';
}

if (amount == 6000) {
return 'V2';
}

if (amount == 10000) {
return 'V3';
}

if (amount == 20000) {
return 'V4';
}

if (amount == 30000) {
return 'V5';
}

if (amount == 50000) {
return 'V6';
}

if (amount == 100000) {
return 'V7';
}

return null;
}

// ============================================================
// VIP NAME
// ============================================================

String _getVipName(String vipLevel) {
switch (vipLevel) {
case 'V1':
return 'V1 VIP';

case 'V2':
return 'V2 VIP';

case 'V3':
return 'V3 VIP';

case 'V4':
return 'V4 VIP';

case 'V5':
return 'V5 VIP';

case 'V6':
return 'V6 VIP';

case 'V7':
return 'V7 VIP';

default:
return 'VIP';
}
}

// ============================================================
// APPROVE DEPOSIT
// ============================================================

Future<void> _approveDeposit(
BuildContext context,
String docId,
String userId,
double amount,
) async {
try {
final firestore = FirebaseFirestore.instance;

// --------------------------------------------------------
// Deposit amount অনুযায়ী VIP নির্ধারণ
// --------------------------------------------------------

final String? vipLevel = _getVipLevel(amount);

// নির্ধারিত amount না হলে Approve হবে না
if (vipLevel == null) {
if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'এই Deposit amount-এর জন্য কোনো VIP level নির্ধারিত নেই।',
),
backgroundColor: Colors.red,
),
);

return;
}

final String vipName = _getVipName(vipLevel);

// --------------------------------------------------------
// Firestore References
// --------------------------------------------------------

final depositRef =
firestore.collection('deposit_requests').doc(docId);

final userRef =
firestore.collection('users').doc(userId);

// --------------------------------------------------------
// সব Update একই Transaction-এর মধ্যে
// --------------------------------------------------------

await firestore.runTransaction((transaction) async {
// Deposit request পড়া
final depositSnapshot =
await transaction.get(depositRef);

// User document পড়া
final userSnapshot =
await transaction.get(userRef);

// ------------------------------------------------------
// Deposit আছে কি না
// ------------------------------------------------------

if (!depositSnapshot.exists) {
throw Exception(
'Deposit request পাওয়া যায়নি।',
);
}

// ------------------------------------------------------
// User আছে কি না
// ------------------------------------------------------

if (!userSnapshot.exists) {
throw Exception(
'User account পাওয়া যায়নি।',
);
}

final depositData =
depositSnapshot.data() as Map<String, dynamic>;

final userData =
userSnapshot.data() as Map<String, dynamic>;

// ------------------------------------------------------
// বর্তমান Deposit Status
// ------------------------------------------------------

final String currentStatus =
depositData['status']
?.toString()
.toLowerCase() ??
'pending';

// ------------------------------------------------------
// Already Approved হলে আবার Approve করা যাবে না
// ------------------------------------------------------

if (currentStatus == 'approved') {
throw Exception(
'এই Deposit ইতিমধ্যে Approved হয়েছে।',
);
}

// ------------------------------------------------------
// বর্তমান Balance
// ------------------------------------------------------

final double currentBalance =
(userData['balance'] ?? 0).toDouble();

// ------------------------------------------------------
// বর্তমান Shop Deposit
// ------------------------------------------------------

final double currentShopDeposit =
(userData['shopDeposit'] ??
userData['depositBalance'] ??
0)
.toDouble();

// ------------------------------------------------------
// নতুন Balance
// ------------------------------------------------------

final double newBalance =
currentBalance + amount;

// ------------------------------------------------------
// নতুন Shop Deposit
// ------------------------------------------------------

final double newShopDeposit =
currentShopDeposit + amount;

// ======================================================
// ১. DEPOSIT REQUEST APPROVED
// ======================================================

transaction.update(
depositRef,
{
'status': 'approved',
'approvedAt':
FieldValue.serverTimestamp(),
'approvedVipLevel':
vipLevel,
'approvedVipName':
vipName,
},
);

// ======================================================
// ২. USER ACCOUNT UPDATE
// ======================================================

transaction.update(
userRef,
{
'balance': newBalance,
'shopDeposit': newShopDeposit,
'depositStatus': 'approved',
'lastDepositAmount': amount,
'vipLevel': vipLevel,
'currentVip': vipLevel,
'vip_id': vipLevel,
'isVipActive': true,
'vipName': vipName,
'vipActivatedAt':
FieldValue.serverTimestamp(),
'updatedAt':
FieldValue.serverTimestamp(),
},
);

// ======================================================
// ৩. DEPOSIT TRANSACTION HISTORY
// ======================================================

final transactionRef = userRef
.collection('transactions')
.doc();

transaction.set(
transactionRef,
{
'type': 'deposit',
'amount': amount,
'title':
'Deposit Approved - $vipName',
'vipLevel':
vipLevel,
'status':
'approved',
'depositRequestId':
docId,
'createdAt':
FieldValue.serverTimestamp(),
'userId':
userId,
},
);

// ======================================================
// ৪. REFERRAL COMMISSION & LUCKY SPIN (নতুন সংযোজন)
// ======================================================
// যদি এই ইউজারের কোনো 'referredBy' (রেফারকারী) থেকে থাকে
final String referrerId = userData['referredBy'] ?? 'none';

if (referrerId != 'none' && referrerId.isNotEmpty) {
final referrerRef = firestore.collection('users').doc(referrerId);
final referrerSnapshot = await transaction.get(referrerRef);

if (referrerSnapshot.exists) {
// ১০% কমিশন হিসাব (যেমন: ৩০০০ এর ১০% = ৩০০, ৬০০০ এর ১০% = ৬০০)
double commissionAmount = amount * 0.10;

// রেফারকারী ইউজারের ব্যালেন্সে কমিশন যোগ এবং ১টি লাকি স্পিন যোগ
transaction.update(referrerRef, {
'balance': FieldValue.increment(commissionAmount),
'luckySpinCount': FieldValue.increment(1), // বা আপনার ডাটাবেজে লাকি স্পিনের ফিল্ডের নাম অনুযায়ী
});
}
}
});

// ========================================================
// SUCCESS MESSAGE
// ========================================================

if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Deposit Approved সফল হয়েছে!\n'
'৳ ${amount.toStringAsFixed(0)} → '
'$vipName ($vipLevel) সক্রিয় হয়েছে।',
),
backgroundColor: Colors.green,
duration: const Duration(seconds: 4),
),
);
}

// ==========================================================
// FIREBASE ERROR
// ==========================================================

on FirebaseException catch (e) {
if (!context.mounted) return;

String message;

if (e.code == 'permission-denied') {
message =
'Permission Denied। Firestore Security Rules-এ Admin permission দিতে হবে।';
} else if (e.code == 'unavailable') {
message =
'Firebase সংযোগ পাওয়া যাচ্ছে না। Internet connection পরীক্ষা করুন।';
} else {
message =
'Firebase Error: ${e.code}';
}

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor: Colors.red,
duration: const Duration(seconds: 5),
),
);
}

// ==========================================================
// OTHER ERROR
// ==========================================================

catch (e) {
if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Deposit Approve করা যায়নি।\n$e',
),
backgroundColor: Colors.red,
duration: const Duration(seconds: 5),
),
);
}
}
// ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ডিপোজিট রিকোয়েস্ট',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      // ========================================================
      // PENDING DEPOSIT LIST
      // ========================================================

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deposit_requests')
            .where(
          'status',
          isEqualTo: 'pending',
        )
            .snapshots(),

        builder: (context, snapshot) {
          // ----------------------------------------------------
          // Loading
          // ----------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ----------------------------------------------------
          // Error
          // ----------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'ডেটা লোড করা যায়নি.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          // ----------------------------------------------------
          // No Data
          // ----------------------------------------------------

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'কোনো Pending Deposit Request নেই।',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // ----------------------------------------------------
          // Request List
          // ----------------------------------------------------

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              final data =
              doc.data() as Map<String, dynamic>;

              final String docId = doc.id;

              final String userId =
                  data['userId']?.toString() ?? '';

              final double amount =
              (data['amount'] ?? 0).toDouble();

              final String phone =
                  data['phone']?.toString() ?? 'N/A';

              final String trxId =
                  data['trxId']?.toString() ?? 'N/A';

              final String method =
                  data['method']?.toString() ??
                      'bKash/Nagad';

              final String? vipLevel =
              _getVipLevel(amount);

              final bool validAmount =
                  vipLevel != null;

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // ========================================
                      // AMOUNT
                      // ========================================

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Text(
                            '৳ ${amount.toStringAsFixed(0)}',
                            style:
                            const TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration:
                            BoxDecoration(
                              color: validAmount
                                  ? Colors
                                  .green
                                  .shade50
                                  : Colors
                                  .red
                                  .shade50,
                              borderRadius:
                              BorderRadius
                                  .circular(20),
                            ),
                            child: Text(
                              validAmount
                                  ? '$vipLevel VIP'
                                  : 'Invalid Amount',
                              style: TextStyle(
                                color: validAmount
                                    ? Colors
                                    .green
                                    .shade700
                                    : Colors
                                    .red
                                    .shade700,
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ========================================
                      // USER INFORMATION
                      // ========================================

                      Text(
                        'নম্বর: $phone',
                        style:
                        const TextStyle(
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'Transaction ID: $trxId',
                        style:
                        const TextStyle(
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'Method: $method',
                        style:
                        const TextStyle(
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ========================================
                      // VIP INFORMATION
                      // ========================================

                      if (validAmount)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: Text(
                            'এই Deposit Approve করলে '
                                '$vipLevel VIP সক্রিয় হবে।',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      if (!validAmount)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'এই amount-এর জন্য কোনো VIP level নির্ধারিত নেই। '
                                'Approve করা যাবে না।',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ========================================
                      // APPROVE BUTTON
                      // ========================================

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: validAmount
                                ? Colors.green
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                          ),
                          onPressed:
                          validAmount &&
                              userId.isNotEmpty
                              ? () {
                            _approveDeposit(
                              context,
                              docId,
                              userId,
                              amount,
                            );
                          }
                              : null,
                          icon: const Icon(
                            Icons.check_circle_outline,
                          ),
                          label: Text(
                            validAmount
                                ? 'Approve → $vipLevel VIP'
                                : 'Approve করা যাবে না',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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