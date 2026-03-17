import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthState {
  final firebase_auth.User? firebaseUser;
  final bool isLoading;
  final String? error;

  AuthState({this.firebaseUser, this.isLoading = false, this.error});

  bool get isAuthenticated => firebaseUser != null;

  AuthState copyWith({
    firebase_auth.User? firebaseUser,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
