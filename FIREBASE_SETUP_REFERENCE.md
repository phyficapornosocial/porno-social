# PornoSocial Firebase Setup — Complete Reference Guide

A comprehensive guide documenting all 7 phases of Firebase configuration for the PornoSocial Flutter app.

---

## Phase 1: Firebase Project Setup

### Overview
Initialize Firebase project, register Flutter apps (Android & Web), and configure Firebase CLI.

### Step 1.1: Create Firebase Project

**In Firebase Console:**
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **"Add project"**
3. Enter project name: `porno-social`
4. Choose location: **Europe (eur3)**
5. Accept terms and create

**Result:**
- Project ID: `pornosocial-c003d`
- Firebase domain: `pornosocial-c003d.firebaseapp.com`

### Step 1.2: Register Android App

**In Firebase Console → Project Settings:**
1. Click **"Add app"** → Select **Android**
2. Fill in:
   - **Package name:** `com.pornosocial.app`
   - **App nickname:** `PornoSocial Android`
   - **SHA-1 fingerprint:** (Add in next step)
3. Download `google-services.json`
4. Place file in: `android/app/google-services.json`

**SHA-1 Fingerprint for Google Sign-In:**
```bash
# Get SHA-1 from keystore
keytool -list -v -keystore android/app/pornosocial-release.jks -alias pornosocial_release -storepass qbshMgkvr4QV1lPRiGXWEU87 -keypass xPIejbyUARozuXJF48VH5ikd

# Output shows:
# SHA1: XX:XX:XX:XX:XX:XX:...
```

Add to Firebase Android app settings → SHA certificate fingerprints.

### Step 1.3: Register Web App

**In Firebase Console → Project Settings:**
1. Click **"Add app"** → Select **Web** (</> icon)
2. Enter app name: `PornoSocial Web`
3. Firebase provides config (copy for reference)
4. Continue

**Result:**
Web config is auto-generated later by `flutterfire configure`.

### Step 1.4: Install & Configure FlutterFire CLI

```bash
# Activate FlutterFire globally
dart pub global activate flutterfire_cli

# Verify installation
flutterfire --version
```

### Step 1.5: Run FlutterFire Configure

```bash
cd porno_social

# Interactive setup (required)
flutterfire configure

# Prompts:
# 1. Select platforms: Android, iOS, Web, Windows, macOS
# 2. Select Firebase project: pornosocial-c003d
# 3. Configure each platform
```

**Auto-generates:**
- `lib/firebase_options.dart` — Platform-specific Firebase configs
- Updates `android/build.gradle` with Google Services plugin
- Updates `ios/Podfile` with Firebase pods

---

## Phase 2: Flutter Dependencies

### Overview
Add Firebase packages to pubspec.yaml and initialize Firebase in main.dart.

### Step 2.1: Update pubspec.yaml

**Current dependencies (verified working):**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.0.0           # Core Firebase SDK
  firebase_auth: ^5.0.0           # Authentication
  cloud_firestore: ^5.0.0         # Database
  cloud_functions: ^5.0.0         # Backend functions
  firebase_storage: ^12.0.0       # File storage
  firebase_messaging: ^15.0.0     # Push notifications
  firebase_crashlytics: ^4.0.0    # Error tracking
  firebase_app_check: ^0.3.2+10   # Security verification
  
  # State management
  flutter_riverpod: ^2.5.0
  
  # Navigation
  go_router: ^13.0.0
  
  # Media
  video_player: ^2.8.0
  image_picker: ^1.0.0
  video_compress: ^3.1.3
  cached_network_image: ^3.3.0
  geoflutterfire_plus: ^0.0.22
  geocoding: ^3.0.0
  geolocator: ^14.0.1
  google_maps_flutter: ^2.12.0
  
  # UI
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  
  # Payments/Media
  webview_flutter: ^4.0.0
  agora_rtc_engine: ^6.3.0
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  
  # Utilities
  intl: ^0.20.0
  uuid: ^4.3.0
  timeago: ^3.6.0
  algolia_helper_flutter: ^1.6.0
  cupertino_icons: ^1.0.8
```

### Step 2.2: Run Flutter Pub Get

```bash
flutter pub get

# Verifies:
# - All packages downloaded
# - Android gradle dependencies resolved
# - iOS pods installed
# - Generated files created
```

### Step 2.3: Initialize Firebase in main.dart

**Code Structure:**

```dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (MUST be first)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Activate App Check (security)
  await _activateFirebaseAppCheck();
  
  // Initialize local cache
  await CacheService.init();

  // Setup error handling
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize notifications
  await NotificationService().init();
  
  // Run app
  runApp(const ProviderScope(child: PornoSocialApp()));
}

Future<void> _activateFirebaseAppCheck() async {
  const webRecaptchaSiteKey = String.fromEnvironment(
    'APP_CHECK_WEB_RECAPTCHA_SITE_KEY',
  );

  try {
    if (kIsWeb) {
      if (webRecaptchaSiteKey.isEmpty) {
        debugPrint('App Check skipped: missing WEB_RECAPTCHA_SITE_KEY');
        return;
      }
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(webRecaptchaSiteKey),
      );
      return;
    }
    
    // Android & iOS use default device verification
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidDeviceCheckProvider(),
      appleProvider: AppleDeviceCheckProvider(),
    );
  } catch (e) {
    debugPrint('App Check initialization failed: $e');
  }
}
```

---

## Phase 3: Authentication

### Overview
Enable Firebase authentication with Email/Password and Google Sign-In.

### Step 3.1: Enable Auth Providers

**In Firebase Console → Authentication:**
1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**
   - Allow password-less (email link)
   - Email enumeration protection: ON
3. Enable **Google**
   - Add OAuth client (auto-created)
4. Configure allowed redirect URIs for Web

### Step 3.2: Add Android SHA-1 Fingerprint

**Already configured in:**
- `android/app/key.properties` — Keystore path
- `android/app/build.gradle.kts` — Signing config

**Verify in Firebase Console:**
1. Android app settings → SHA certificate fingerprints
2. Should show: `XX:XX:XX:... (pornosocial_release)`

### Step 3.3: Add Google OAuth Consent Screen

**In Google Cloud Console:**
1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** (if not in production)
3. Fill required fields:
   - App name: `PornoSocial`
   - User support email: `support@porno-social.com`
   - Developer contact: `cbros@example.com`
4. Add scopes: `email`, `profile`, `openid`
5. Save and continue

### Step 3.4: Authentication Service Implementation

```dart
// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth state changes
  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Sign up with email
  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
  ) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with email
  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception("Google sign-in cancelled");

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;
}
```

---

## Phase 4: Firestore Database

### Overview
Create Firestore database with security rules and indexed collections.

### Step 4.1: Create Firestore Database

**In Firebase Console:**
1. Go to **Firestore Database**
2. Click **Create database**
3. Settings:
   - **Location:** `eur3` (Europe)
   - **Mode:** Production (not development)
4. Create

**Collections created:**
```
users/          — User profiles & metadata
feeds/          — Main feed posts
shorts/         — Short-form videos
stories/        — 24-hour stories
follows/        — Follow relationships
messages/       — Direct messages
notifications/  — Push notification log
```

### Step 4.2: Firestore Security Rules

**File:** `firestore.rules`

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isUser(uid) {
      return request.auth.uid == uid;
    }
    
    function isAdmin() {
      return request.auth.uid in get(/databases/$(database)/documents/admins/list).data.users;
    }

    // Users collection
    match /users/{userId} {
      // Read: Own profile + admin
      allow read: if isUser(userId) || isAdmin();
      
      // Write: Own profile + admin
      allow write: if isUser(userId) || isAdmin();
      
      // Subcollections
      match /{document=**} {
        allow read, write: if isUser(userId) || isAdmin();
      }
    }

    // Feeds collection
    match /feeds/{postId} {
      // Anyone (authenticated) can read
      allow read: if isAuthenticated();
      
      // Write own posts
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      
      allow update, delete: if isUser(resource.data.userId) || isAdmin();
    }

    // Shorts collection
    match /shorts/{shortId} {
      // Anyone can read
      allow read: if isAuthenticated();
      
      // Write own shorts
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      
      allow update, delete: if isUser(resource.data.userId) || isAdmin();
      
      // Comments subcollection
      match /comments/{comment} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
        allow delete: if isUser(resource.data.userId) || isAdmin();
      }
    }

    // Messages collection
    match /messages/{messageId} {
      // Read: Recipient or sender
      allow read: if isUser(resource.data.senderId) || isUser(resource.data.recipientId);
      
      // Write: Own messages
      allow create: if isAuthenticated() && request.resource.data.senderId == request.auth.uid;
    }

    // Default deny
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Deploy rules:**
```bash
firebase deploy --only firestore:rules
```

### Step 4.3: Create Firestore Indexes

**File:** `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionId": "feeds",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionId": "feeds",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "likes", "order": "DESCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionId": "shorts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "trending", "order": "DESCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionId": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "username", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Indexes are auto-created on first compound query.**

### Step 4.4: Data Model Examples

```dart
// models/user.dart
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final int followers;
  final int following;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      username: data['username'],
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt,
      'followers': followers,
      'following': following,
    };
  }
}

// models/feed_post.dart
class FeedPost {
  final String id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int likes;
  final int comments;

  factory FeedPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedPost(
      id: doc.id,
      userId: data['userId'],
      content: data['content'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
    );
  }
}
```

---

## Phase 5: Firebase Storage

### Overview
Configure cloud storage for photos, videos, and media with security rules.

### Step 5.1: Enable Firebase Storage

**In Firebase Console:**
1. Go to **Storage**
2. Click **Get started**
3. Settings:
   - Location: `eur3`
   - Rules: Custom (we'll set below)
4. Create

### Step 5.2: Storage Rules with Upload Limits

**File:** `storage.rules`

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isUser(userId) {
      return request.auth.uid == userId;
    }

    // User uploads (photos, videos)
    match /users/{userId}/{allPaths=**} {
      // Read: Public or own data
      allow read: if true; // Public CDN access

      // Write: Own files only
      allow write: if isUser(userId)
        && request.resource.size < 500 * 1024 * 1024  // 500MB max
        && request.resource.contentType.matches('image/.*|video/.*');
    }

    // Temp uploads
    match /temp/{fileId} {
      allow read, write: if isAuthenticated()
        && request.resource.size < 500 * 1024 * 1024;
    }

    // Public media (profile pictures)
    match /profiles/{userId}/avatar {
      allow read: if true;
      allow write: if isUser(userId)
        && request.resource.size < 5 * 1024 * 1024  // 5MB
        && request.resource.contentType.matches('image/.*');
    }

    // Default deny
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

**Deploy rules:**
```bash
firebase deploy --only storage
```

### Step 5.3: Upload Service Implementation

```dart
// services/storage_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload image
  Future<String> uploadImage({
    required String userId,
    required File imageFile,
    String? fileName,
  }) async {
    final name = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref('users/$userId/images/$name');
    
    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload video
  Future<String> uploadVideo({
    required String userId,
    required File videoFile,
  }) async {
    final ref = _storage.ref('users/$userId/videos/${DateTime.now().millisecondsSinceEpoch}');
    
    final uploadTask = ref.putFile(
      videoFile,
      SettableMetadata(contentType: 'video/mp4'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Delete file
  Future<void> deleteFile(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}
```

---

## Phase 6: Cloud Functions

### Overview
Deploy Node.js Cloud Functions for backend logic.

### Step 6.1: Initialize Cloud Functions

**In functions/ directory:**

```bash
firebase init functions

# Choices:
# - Language: TypeScript (or JavaScript)
# - Use ESLint: Yes
# - Install dependencies: Yes
```

**Structure:**
```
functions/
├── .eslintrc.js
├── .gitignore
├── package.json
├── tsconfig.json (if TypeScript)
└── src/
    └── index.ts
```

### Step 6.2: Example Cloud Functions

**File:** `functions/src/index.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Create user profile on auth registration
export const createUserProfile = functions.auth.user().onCreate(async (user) => {
  const userData = {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName || 'Anonymous',
    photoURL: user.photoURL,
    createdAt: new Date(),
    followers: 0,
    following: 0,
  };

  await admin.firestore().collection('users').doc(user.uid).set(userData);
});

// Delete user data on account deletion
export const deleteUserProfile = functions.auth.user().onDelete(async (user) => {
  const db = admin.firestore();
  
  // Delete user document
  await db.collection('users').doc(user.uid).delete();
  
  // Delete user storage
  await admin.storage().bucket().deleteFiles({
    prefix: `users/${user.uid}/`,
  });
  
  // Delete user posts
  const posts = await db.collection('feeds').where('userId', '==', user.uid).get();
  for (const doc of posts.docs) {
    await doc.ref.delete();
  }
});

// Process video on upload (thumbnail, compression)
export const processVideoUpload = functions.storage
  .object()
  .onFinalize(async (object) => {
    const bucket = admin.storage().bucket();
    const file = bucket.file(object.name!);
    
    // Limit to video files in user directories
    if (!object.name?.includes('/videos/')) return;
    
    // Here you'd call a video processing service
    // like ffmpeg to generate thumbnails or compress
    console.log(`Processing video: ${object.name}`);
  });

// Send notification on new follow
export const notifyNewFollower = functions.firestore
  .document('follows/{followId}')
  .onCreate(async (snap) => {
    const followData = snap.data();
    const followerUid = followData.followerUid;
    const followeeUid = followData.followeeUid;

    // Get follower info
    const followerDoc = await admin
      .firestore()
      .collection('users')
      .doc(followerUid)
      .get();

    const followerName = followerDoc.data()?.displayName || 'Someone';

    // Send notification to followee
    await admin.firestore().collection('notifications').add({
      type: 'follow',
      userId: followeeUid,
      fromUserId: followerUid,
      message: `${followerName} followed you!`,
      createdAt: new Date(),
      read: false,
    });
  });

// Count likes in real-time (batch operation)
export const countLikes = functions.firestore
  .document('feeds/{postId}/likes/{userId}')
  .onWrite(async (change, context) => {
    const postId = context.params.postId;
    const db = admin.firestore();

    // Count likes for this post
    const likeSnap = await db.collection('feeds').doc(postId).collection('likes').get();
    const likeCount = likeSnap.size;

    // Update post like count
    await db.collection('feeds').doc(postId).update({
      likeCount: likeCount,
    });
  });
```

### Step 6.3: Deploy Functions

```bash
# From project root
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:createUserProfile

# View logs
firebase functions:log

# Test locally (emulator)
firebase emulators:start --only functions
```

---

## Phase 7: Hosting & Deployment

### Overview
Build and deploy Flutter Web to Firebase Hosting + Android APK for distribution.

### Step 7.1: Build Flutter Web

```bash
# Clean build
flutter clean
flutter pub get

# Build production web
flutter build web --release

# Output: build/web/
# Size: ~50MB (pre-gzip)
```

**Web optimization:**
- Tree-shaking enabled (removes unused icons)
- Minification enabled
- All assets optimized

### Step 7.2: Configure Firebase Hosting

**File:** `firebase.json`

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "redirects": [
      {
        "source": "/old-path",
        "destination": "/new-path",
        "type": 301
      }
    ],
    "headers": [
      {
        "source": "/service-worker.js",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache"
          }
        ]
      }
    ]
  }
}
```

### Step 7.3: Deploy to Firebase Hosting

```bash
# One-time setup
firebase init hosting
# Select existing project: pornosocial-c003d

# Deploy web
firebase deploy --only hosting --project pornosocial-c003d

# Live at: https://porno-social.com
```

### Step 7.4: Build Android Release APK

```bash
# Clean and build
flutter clean
flutter pub get

# Build signed release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
# Size: 241.9 MB (pre-optimization)
```

**Signing Configuration:**

Configured in `android/app/build.gradle.kts`:

```kotlin
signingConfigs {
    create("release") {
        if (hasReleaseSigning) {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}

buildTypes {
    release {
        signingConfig = if (hasReleaseSigning) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
    }
}
```

### Step 7.5: Publish to Play Store

1. **Create Google Play account** (one-time)
   - Go to [play.google.com/console](https://play.google.com/console)
   - Create new app
   - Fill app details (name, description, screenshots)

2. **Upload APK**
   - Navigation: **Release** → **Production**
   - Upload `app-release.apk`
   - Set version name & number

3. **Complete store listing**
   - Privacy policy
   - Content rating
   - Permissions justification

4. **Review & publish**
   - Submit for review
   - Takes 1-2 hours typically

---

## Quick Reference Commands

### Development
```bash
flutter run              # Debug on connected device
flutter run -d chrome   # Web development
flutter run --profile   # Profile mode
```

### Building
```bash
flutter build web --release     # Web production
flutter build apk --release     # Android APK
flutter build app-bundle       # Android App Bundle (Play Store)
```

### Firebase
```bash
firebase init              # Initialize project
firebase deploy            # Deploy all (hosting, functions, rules)
firebase deploy --only hosting
firebase deploy --only functions
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase emulators:start   # Local emulation
```

### Scripts
```bash
./scripts/build-and-deploy.ps1 -target all
./scripts/deploy-web.ps1
./scripts/manage-version.ps1 -bump patch
```

---

## Troubleshooting

### Web deployment fails
```bash
# Clear build cache
flutter clean
rm -rf build/
flutter pub get

# Rebuild
flutter build web --release
firebase deploy --only hosting
```

### Android APK not signing
```bash
# Verify keystore
keytool -list -v -keystore android/app/pornosocial-release.jks

# Regenerate if needed
keytool -genkey -v -keystore android/app/pornosocial-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias pornosocial_release
```

### Firestore rules blocking access
- Check user is authenticated
- Verify user UID matches rule conditions
- Check browser console for detailed error
- Test rules in Firebase Console Simulator

### Functions not deploying
```bash
# Check errors
firebase deploy --only functions --debug

# Verify code syntax
npm run lint

# Check Node.js version requirement
node --version  # Should match package.json
```

---

**Last Updated:** March 2026
**Maintained By:** Development Team
