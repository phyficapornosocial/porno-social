import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Checks whether the current user has an active subscription to a creator.
Widget buildContentGate(String creatorId, Widget content) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return const LockedContentPlaceholder();
  }

  return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
    future: FirebaseFirestore.instance
        .collection('subscriptions')
        .where('subscriberId', isEqualTo: currentUser.uid)
        .where('creatorId', isEqualTo: creatorId)
        .where('status', isEqualTo: 'active')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .limit(1)
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LockedContentLoading();
      }

      if (snapshot.hasError) {
        return const LockedContentPlaceholder();
      }

      if (snapshot.data?.docs.isNotEmpty == true) {
        return content;
      }

      return const LockedContentPlaceholder();
    },
  );
}

class LockedContentPlaceholder extends StatelessWidget {
  const LockedContentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0f0f0f),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2b2b2b)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.lock_outline, color: Color(0xFFe8000a), size: 28),
          SizedBox(height: 10),
          Text(
            'Subscribers only content',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Subscribe to unlock this post.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LockedContentLoading extends StatelessWidget {
  const _LockedContentLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0f0f0f),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFe8000a)),
        ),
      ),
    );
  }
}
