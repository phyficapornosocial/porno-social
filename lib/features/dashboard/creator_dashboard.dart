import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreatorDashboard extends StatelessWidget {
  const CreatorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in required to access dashboard.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        title: const Text(
          'Creator Dashboard',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('subscriptions')
                  .where('creatorId', isEqualTo: uid)
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? const [];
                final count = docs.length;
                final revenue = docs.fold<double>(0, (total, doc) {
                  final data = doc.data();
                  final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                  return total + price;
                });

                return Row(
                  children: [
                    _StatCard(label: 'Subscribers', value: '$count'),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Monthly Revenue',
                      value: 'GBP ${revenue.toStringAsFixed(2)}',
                    ),
                    const SizedBox(width: 12),
                    _PostsCountCard(uid: uid),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Earnings (last 30 days)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Chart placeholder (use fl_chart)',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe8000a),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
                label: const Text(
                  'Request Payout via Paxum',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payout flow placeholder')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _SubscriptionPriceEditor(uid: uid),
          ],
        ),
      ),
    );
  }
}

class _PostsCountCard extends StatelessWidget {
  final String uid;

  const _PostsCountCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          final count = snap.data?.docs.length ?? 0;
          return _StatCard(label: 'Posts', value: '$count');
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionPriceEditor extends StatefulWidget {
  final String uid;

  const _SubscriptionPriceEditor({required this.uid});

  @override
  State<_SubscriptionPriceEditor> createState() =>
      _SubscriptionPriceEditorState();
}

class _SubscriptionPriceEditorState extends State<_SubscriptionPriceEditor> {
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Price (GBP/month)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixText: 'GBP ',
                    prefixStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe8000a),
                ),
                onPressed: () async {
                  final price = double.tryParse(_priceController.text);
                  if (price == null) return;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.uid)
                      .update({'subscriptionPrice': price, 'isCreator': true});

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Price updated!')),
                  );
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
