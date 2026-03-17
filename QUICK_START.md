## Quick Reference Guide

### 📁 File Structure
```
lib/
├── main.dart                           # App entry & Firebase init
├── app.dart                            # Router & screen definitions
├── models/
│   ├── user.dart                       # User public profile (searchable)
│   ├── user_private.dart               # User private data (email, DOB)
│   └── auth_state.dart                 # Auth state wrapper
├── services/
│   └── firebase_auth_service.dart      # Auth operations (sign up, login, etc)
├── repositories/
│   └── user_repository.dart            # User CRUD & search queries
└── providers/
    ├── auth_providers.dart             # Auth state & operations
    └── user_providers.dart             # User data & search state
```

---

## 🔐 Authentication Flow

### Sign Up
```dart
// 1. Create Firebase account
await ref.read(signUpProvider(
  SignUpParams(
    email: 'user@example.com',
    password: 'password123'
  ),
).future);

// 2. Get current user ID
final userId = ref.read(currentUserIdProvider);

// 3. Create Firestore profile + private data
final repository = ref.read(userRepositoryProvider);
await repository.createUser(
  uid: userId!,
  username: 'john_doe',
  displayName: 'John Doe',
  email: 'user@example.com',
  dateOfBirth: DateTime(1990, 1, 1),
);

// 4. Navigate to home
context.go('/home');
```

### Sign In
```dart
await ref.read(signInProvider(
  SignInParams(
    email: 'user@example.com',
    password: 'password123'
  ),
).future);
```

### Sign Out
```dart
await ref.read(signOutProvider.future);
```

---

## 👤 User Profile Management

### Watch Current User Profile
```dart
// In a ConsumerWidget:
final profile = ref.watch(currentUserProfileProvider);

profile.when(
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
  data: (user) => user == null 
      ? Text('No profile')
      : Text(user.displayName),
);
```

### Update Profile
```dart
await ref.read(updateUserProfileProvider(
  UpdateUserProfileParams(
    uid: 'user123',
    displayName: 'New Name',
    bio: 'New bio',
    avatarUrl: 'https://...',
    interests: ['kink1', 'kink2'],
    location: GeoPoint(37.7749, -122.4194),
  ),
).future);
```

### Get Any User's Profile
```dart
final userProfile = ref.watch(userProfileProvider('user123'));
// or by username
final user = ref.watch(userByUsernameProvider('john_doe'));
```

---

## 🔍 Search & Discovery

### Search Users by Username
```dart
final results = ref.watch(searchUsersByUsernameProvider('joh'));

results.when(
  loading: () => CircularProgressIndicator(),
  error: (err, _) => Text('Error'),
  data: (users) => ListView(
    children: users.map((user) => Text(user.username)).toList(),
  ),
);
```

### Search Creators by Interest/Kink
```dart
final creators = ref.watch(
  searchCreatorsByInterestProvider('bondage')
);
```

### Find Nearby Creators
```dart
final nearby = ref.watch(
  nearbyCreatorsProvider(GeoPoint(37.7749, -122.4194))
);
```

---

## 💰 Creator Features

### Become a Creator
```dart
await ref.read(becomeCreatorProvider('user123').future);
```

### Set Subscription Price
```dart
await ref.read(setSubscriptionPriceProvider(
  SetSubscriptionPriceParams(
    uid: 'user123',
    price: 9.99,
  ),
).future);
```

### Track Subscribers
```dart
// Increment when someone subscribes
await repository.incrementSubscriberCount('user123');

// Decrement when someone unsubscribes
await repository.decrementSubscriberCount('user123');
```

---

## 🔐 Auth State Checks

### Check if Authenticated
```dart
final isAuth = ref.watch(isAuthenticatedProvider);

if (isAuth) {
  // Show authenticated UI
} else {
  // Show login screen
}
```

### Get Current User ID
```dart
final userId = ref.watch(currentUserIdProvider);  // String?
```

### Watch Auth Changes
```dart
final authState = ref.watch(authStateProvider);  // Stream<User?>
```

---

## 📱 Authentication Errors

Service automatically maps Firebase errors to user-friendly messages:

| Error | Message |
|-------|---------|
| `user-not-found` | No user found with this email |
| `wrong-password` | Incorrect password |
| `email-already-in-use` | This email is already registered |
| `weak-password` | Password is too weak |
| `invalid-email` | Invalid email format |
| `too-many-requests` | Too many requests. Try again later |

---

## 🚀 Available Routes

| Route | Purpose |
|-------|---------|
| `/login` | Login screen |
| `/signup` | Registration |
| `/forgot-password` | Password reset |
| `/home` | Main feed/dashboard |
| `/profile/:userId` | View user profile |
| `/edit-profile` | Edit own profile |
| `/search` | Search & discovery |

---

## 🔗 Firestore Structure

### Public Data (`/users/{uid}`)
- `username` — Searchable display name
- `displayName` — Full name
- `bio` — User biography
- `avatarUrl` — Profile picture URL
- `isCreator` — Content creator flag
- `isVerified` — Age verification status
- `subscriptionPrice` — Creator subscription cost
- `subscriberCount` — Number of subscribers
- `createdAt` — Account creation time
- `location` — GeoPoint for geographic search
- `interests` — Array of interest tags/kinks

### Private Data (`/users/{uid}/private/{uid}`)
- `email` — Email address (encrypted at rest)
- `dateOfBirth` — Age verification
- `verificationStatus` — 'pending' | 'approved' | 'rejected'

**Security Note:** Private data can only be read/written by the account owner!

---

## ⚙️ Provider Patterns

### Watching Data
```dart
final data = ref.watch(someProvider);  // Auto-updates on changes
```

### Reading Data (One-time)
```dart
final data = ref.read(someProvider);  // Single read, no subscription
```

### Invalidating Cache
```dart
ref.invalidate(userProfileProvider('user123'));  // Refetch
ref.invalidate(currentUserProfileProvider);      // Clear cache
```

### Handling AsyncValue
```dart
data.when(
  loading: () => const Spinner(),
  error: (error, stack) => Text('$error'),
  data: (value) => Text('$value'),
);
```

---

## 🧪 Testing Setup

Basic widget test included. To add more:

```dart
testWidgets('Profile shows correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderContainer(
      child: MaterialApp(
        home: ProfileScreen(userId: 'test123'),
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

## 🛠️ Common Tasks

### Implement a Login Form
See [ARCHITECTURE.md](ARCHITECTURE.md#usage-examples) for full example

### Add a Custom Search Filter
Extend `UserRepository` with new query methods

### Create a Creator Onboarding
Use `becomeCreatorProvider` + `setSubscriptionPriceProvider`

### Display User Search Results
Combine `searchUsersByUsernameProvider` with ListView

---

## 📝 Notes

- **Firebase Rules Required**: See ARCHITECTURE.md for recommended Firestore security rules
- **No Backend Server**: Everything uses Firebase directly
- **Type-Safe**: Full null safety throughout
- **Reactive UI**: All data automatically updates via Riverpod
- **Error Handling**: All operations include try-catch with user-friendly messages
