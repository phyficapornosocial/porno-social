import 'package:cloud_firestore/cloud_firestore.dart';

class UserPrivate {
  final String uid;
  final String email;
  final DateTime dateOfBirth;
  final String verificationStatus; // 'pending' | 'approved' | 'rejected'

  UserPrivate({
    required this.uid,
    required this.email,
    required this.dateOfBirth,
    required this.verificationStatus,
  });

  factory UserPrivate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPrivate(
      uid: doc.id,
      email: data['email'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      verificationStatus: data['verificationStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'verificationStatus': verificationStatus,
    };
  }

  UserPrivate copyWith({
    String? uid,
    String? email,
    DateTime? dateOfBirth,
    String? verificationStatus,
  }) {
    return UserPrivate(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}
