import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:porno_social/models/auth_state.dart';
import 'package:porno_social/services/firebase_auth_service.dart';

// Auth service provider
final firebaseAuthServiceProvider = Provider((ref) {
  return FirebaseAuthService();
});

// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges();
});

// Comprehensive auth state provider
final authStateFullProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges().map((user) {
    return AuthState(firebaseUser: user);
  });
});

// Current user UID provider
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid;
});

// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user != null;
});

// Sign up notifier
final signUpProvider = FutureProvider.family<void, SignUpParams>((
  ref,
  params,
) async {
  final authService = ref.watch(firebaseAuthServiceProvider);
  await authService.signUpWithEmail(
    email: params.email,
    password: params.password,
  );
});

// Sign in notifier
final signInProvider = FutureProvider.family<void, SignInParams>((
  ref,
  params,
) async {
  final authService = ref.watch(firebaseAuthServiceProvider);
  await authService.signInWithEmail(
    email: params.email,
    password: params.password,
  );
});

// Sign out notifier
final signOutProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(firebaseAuthServiceProvider);
  await authService.signOut();
});

// Password reset notifier
final passwordResetProvider = FutureProvider.family<void, String>((
  ref,
  email,
) async {
  final authService = ref.watch(firebaseAuthServiceProvider);
  await authService.sendPasswordResetEmail(email);
});

// Data classes for parameters
class SignUpParams {
  final String email;
  final String password;

  SignUpParams({required this.email, required this.password});
}

class SignInParams {
  final String email;
  final String password;

  SignInParams({required this.email, required this.password});
}
