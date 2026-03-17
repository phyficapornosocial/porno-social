## Porno Social - Architecture & Implementation Guide

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Main app widget & routing
├── firebase_options.dart     # Firebase configuration (auto-generated)
├── models/                   # Data models
│   ├── user.dart            # User public profile
│   ├── user_private.dart    # User private data
│   └── auth_state.dart      # Auth state model
├── services/                 # Core services
│   └── firebase_auth_service.dart  # Firebase auth wrapper
├── repositories/             # Data access layer
│   └── user_repository.dart  # User CRUD & queries
└── providers/               # Riverpod state management
    ├── auth_providers.dart  # Auth state providers
    └── user_providers.dart  # User data providers
```

---

## 1. Data Models

### User Model (`models/user.dart`)
Public profile data stored in `/users/{uid}`:
- `uid`: Unique identifier
- `username`: Display username (searchable)
- `displayName`: Full display name
- `bio`: User biography
- `avatarUrl`: Profile picture URL
- `isCreator`: Whether user is a content creator
- `isVerified`: Age verification status
- `subscriptionPrice`: Creator subscription cost
- `subscriberCount`: Number of subscribers
- `createdAt`: Account creation timestamp
- `location`: GeoPoint for geographic search
- `interests`: List of interest tags/kinks

**Key Methods:**
- `fromFirestore()`: Factory to deserialize from Firestore
- `toFirestore()`: Serialize to Firestore format
- `copyWith()`: Create modified copies for immutability

### UserPrivate Model (`models/user_private.dart`)
Secure private data stored in `/users/{uid}/private/{uid}`:
- `uid`: Reference to parent document
- `email`: Email address
- `dateOfBirth`: Age verification data
- `verificationStatus`: 'pending' | 'approved' | 'rejected'

**Security Note:** This subcollection should have Firestore security rules restricting access to the owner only.

### AuthState Model (`models/auth_state.dart`)
Wrapper for Firebase authentication state:
- `firebaseUser`: Current Firebase User object
- `isLoading`: Loading state during auth operations
- `error`: Error message if auth failed
- `isAuthenticated`: Computed property

---

## 2. Services

### FirebaseAuthService (`services/firebase_auth_service.dart`)
Wrapper around Firebase Authentication:

**User Registration:**
```dart
final result = await authService.signUpWithEmail(
  email: 'user@example.com',
  password: 'password123',
);
```

**User Login:**
```dart
await authService.signInWithEmail(
  email: 'user@example.com',
  password: 'password123',
);
```

**Account Management:**
- `signOut()`: Sign out current user
- `deleteUser()`: Permanently delete account
- `updateEmail()`: Change email address
- `updatePassword()`: Change password
- `sendPasswordResetEmail()`: Reset password via email

**Error Handling:**
Service maps Firebase error codes to user-friendly messages:
- `user-not-found` → "No user found with this email"
- `wrong-password` → "Incorrect password"
- `email-already-in-use` → "This email is already registered"
- `weak-password` → "Password is too weak"

---

## 3. Repositories

### UserRepository (`repositories/user_repository.dart`)
Business logic layer for user data operations:

**Profile Creation:**
```dart
final user = await userRepository.createUser(
  uid: 'user123',
  username: 'john_doe',
  displayName: 'John Doe',
  email: 'john@example.com',
  dateOfBirth: DateTime(1990, 1, 1),
);
```

**Profile Retrieval:**
```dart
final user = await userRepository.getUserById('user123');
final user = await userRepository.getUserByUsername('john_doe');
```

**Profile Updates:**
```dart
await userRepository.updateUserProfile(
  uid: 'user123',
  displayName: 'John Smith',
  bio: 'Content creator',
  interests: ['kink1', 'kink2'],
);
```

**Search & Discovery:**
```dart
// Username search (prefix match)
final results = await userRepository.searchUsersByUsername('joh');

// Search creators by interest tag
final creators = await userRepository.searchCreatorsByInterest('bondage');

// Find creators near location
final nearby = await userRepository.getNearbyCreators(
  center: GeoPoint(lat, lng),
  radiusInKm: 50,
);
```

**Creator Management:**
```dart
// Convert account to creator
await userRepository.becomeCreator('user123');

// Set subscription price
await userRepository.setSubscriptionPrice('user123', 9.99);

// Track subscribers
await userRepository.incrementSubscriberCount('user123');
await userRepository.decrementSubscriberCount('user123');
```

**Private Data:**
```dart
// Retrieve sensitive user data
final privateData = await userRepository.getUserPrivateData('user123');

// Update verification status
await userRepository.updateVerificationStatus('user123', 'approved');
```

---

## 4. Riverpod Providers

### Auth Providers (`providers/auth_providers.dart`)

**Stream Providers** (Real-time updates):
```dart
// Watch Firebase auth state
final authState = ref.watch(authStateProvider);  // Stream<User?>

// Watch comprehensive auth state with loading/error
final fullAuthState = ref.watch(authStateFullProvider);  // Stream<AuthState>
```

**Computed Providers:**
```dart
// Get current user ID
final userId = ref.watch(currentUserIdProvider);  // String?

// Check authentication status
final isAuth = ref.watch(isAuthenticatedProvider);  // bool
```

**Async Operation Providers** (One-time operations):
```dart
// Sign up
await ref.read(signUpProvider(
  SignUpParams(email: 'user@example.com', password: 'pass123')
).future);

// Sign in
await ref.read(signInProvider(
  SignInParams(email: 'user@example.com', password: 'pass123')
).future);

// Sign out
await ref.read(signOutProvider.future);

// Reset password
await ref.read(passwordResetProvider('user@example.com').future);
```

### User Providers (`providers/user_providers.dart`)

**Current User Data:**
```dart
// Watch current user's public profile
final profile = ref.watch(currentUserProfileProvider);  // AsyncValue<User?>

// Watch current user's private data
final privateData = ref.watch(currentUserPrivateDataProvider);  // AsyncValue<UserPrivate?>
```

**User Lookup:**
```dart
// Get any user's profile by ID
final userProfile = ref.watch(userProfileProvider('user123'));

// Get user by username
final user = ref.watch(userByUsernameProvider('john_doe'));
```

**Profile Management:**
```dart
// Update profile (auto-invalidates cache)
await ref.read(updateUserProfileProvider(
  UpdateUserProfileParams(
    uid: 'user123',
    displayName: 'New Name',
    bio: 'New bio',
    interests: ['tag1', 'tag2'],
  ),
).future);

// Become a creator
await ref.read(becomeCreatorProvider('user123').future);

// Set subscription price
await ref.read(setSubscriptionPriceProvider(
  SetSubscriptionPriceParams(uid: 'user123', price: 9.99),
).future);
```

**Search Providers:**
```dart
// Search by username (live search)
final results = ref.watch(searchUsersByUsernameProvider('joh'));

// Search creators by interest
final creators = ref.watch(searchCreatorsByInterestProvider('bondage'));

// Get nearby creators
final nearby = ref.watch(nearbyCreatorsProvider(geoPoint));
```

---

## 5. Navigation & Routing

### App Router (`app.dart`)
Uses `go_router` for declarative routing:

**Routes:**
- `/login` - Login screen
- `/signup` - Registration screen
- `/forgot-password` - Password reset
- `/home` - Main feed/dashboard
- `/profile/:userId` - User profile view
- `/edit-profile` - Edit own profile
- `/search` - Search & discovery

**Auto Redirect:**
- Unauthenticated users → Login page
- Authenticated users → Home page

---

## 6. Security Considerations

### Firestore Security Rules (Recommended)

```firestore rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Public user profiles - readable by all
    match /users/{uid} {
      allow read: if true;
      allow write: if request.auth.uid == uid;
    }
    
    // Private user data - only owner can read
    match /users/{uid}/private/{privateUid} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```

### Best Practices
1. **Never store sensitive data in public profile** (email, phone, etc.)
2. **Use subcollections for private data** with strict Firestore rules
3. **Validate age on backend** (cloud functions) before marking verified
4. **Hash sensitive identifiers** if sharing user references in URLs
5. **Rate-limit authentication endpoints** to prevent brute force

---

## 7. Usage Examples

### Complete Sign-Up Flow
```dart
Future<void> signUpFlow(WidgetRef ref) async {
  // 1. Create Firebase auth account
  await ref.read(signUpProvider(
    SignUpParams(email: 'user@example.com', password: 'pass123'),
  ).future);

  // 2. Get current user ID
  final userId = ref.read(currentUserIdProvider);

  // 3. Create Firestore profile + private data
  final userRepository = ref.read(userRepositoryProvider);
  await userRepository.createUser(
    uid: userId!,
    username: 'username',
    displayName: 'Full Name',
    email: 'user@example.com',
    dateOfBirth: DateTime(1990, 1, 1),
  );

  // 3. Navigate to home
  context.go('/home');
}
```

### Watch User Profile in Widget
```dart
class UserProfileWidget extends ConsumerWidget {
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(userId));

    return profile.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (user) => user == null
          ? Text('User not found')
          : Column(
              children: [
                Text(user.displayName),
                Text('@${user.username}'),
                Text(user.bio),
              ],
            ),
    );
  }
}
```

### Search Feature
```dart
class SearchWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final results = ref.watch(searchUsersByUsernameProvider(searchQuery.value));

    return results.when(
      loading: () => CircularProgressIndicator(),
      error: (err, _) => Text('Error: $err'),
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            title: Text(user.displayName),
            subtitle: Text('@${user.username}'),
          );
        },
      ),
    );
  }
}
```

---

## 8. Next Steps

1. **Implement UI Screens:**
   - Replace placeholder screens in `app.dart`
   - Build login/signup forms
   - Create profile views and edit forms

2. **Add Features:**
   - Manage subscriptions
   - Video upload and streaming
   - Comments and interactions
   - Payment processing

3. **Optimize:**
   - Add pagination to search results
   - Implement infinite scroll for feeds
   - Cache frequently accessed data
   - Use Firestore indexing for complex queries

4. **Testing:**
   - Unit tests for repositories
   - Widget tests for UI
   - Integration tests with Firebase Emulator

---

## Architecture Benefits

✅ **Clean Separation of Concerns**: Models → Services → Repositories → Providers → UI
✅ **Type-Safe**: Strong typing throughout, especially with Firestore models
✅ **Reactive**: Automatic UI updates via Riverpod streams
✅ **Testable**: Mock services and repositories easily
✅ **Scalable**: Easy to add new features without affecting existing code
✅ **Secure**: Private data properly isolated with Firestore rules
