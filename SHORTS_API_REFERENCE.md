# Shorts Feature - API Reference

## Quick Navigation
- [Models](#models)
- [Providers](#providers)
- [Widgets](#widgets)
- [Repository](#repository)

---

## Models

### Short

```dart
class Short {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String videoUrl;
  final String? caption;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final DateTime createdAt;
  final List<String> tags;
  final bool isSubscribersOnly;

  Short({/* parameters */});

  factory Short.fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toMap();
}
```

**Importing:**
```dart
import 'package:porno_social/models/short.dart';
```

**Creating an instance:**
```dart
final short = Short(
  id: 'short123',
  authorId: 'user456',
  authorName: 'John Doe',
  authorAvatar: 'https://example.com/avatar.jpg',
  videoUrl: 'https://example.com/video.mp4',
  caption: 'Check this out!',
  likeCount: 150,
  commentCount: 10,
  shareCount: 5,
  viewCount: 1000,
  createdAt: DateTime.now(),
  tags: ['funny', 'viral'],
  isSubscribersOnly: false,
);
```

---

## Providers

### shortsProvider

**Type:** `StreamProvider<List<Short>>`

**Description:** Watches all shorts ordered by creation date (newest first)

**Returns:** `AsyncValue<List<Short>>`

**Importing:**
```dart
import 'package:porno_social/providers/shorts_providers.dart';
```

**Usage:**
```dart
// In ConsumerWidget/ConsumerStatefulWidget
final shortsAsync = ref.watch(shortsProvider);

shortsAsync.when(
  loading: () => Center(child: CircularProgressIndicator()),
  error: (err, stack) => Text('Error: $err'),
  data: (shorts) => ListView(children: shorts.map((s) => ShortTile(s)).toList()),
);
```

**Stream updates:**
- Automatically updates when shorts are added/modified in Firestore
- Real-time synchronization

### shortByIdProvider

**Type:** `FutureProvider.family<Short?, String>`

**Description:** Fetches a specific short by ID

**Parameters:**
- `shortId` (String) - Document ID in Firestore

**Returns:** `AsyncValue<Short?>`

**Usage:**
```dart
final shortAsync = ref.watch(shortByIdProvider('short123'));

shortAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
  data: (short) => short != null ? ShortWidget(short) : Text('Not found'),
);
```

### shortsRepositoryProvider

**Type:** `Provider<ShortsRepository>`

**Description:** Provides instance of ShortsRepository for data operations

**Returns:** `ShortsRepository`

**Usage:**
```dart
final repository = ref.read(shortsRepositoryProvider);
await repository.likeShort('short123');
```

---

## Widgets

### ShortsScreen

**Type:** `ConsumerWidget`

**File:** `lib/features/shorts/shorts_screen.dart`

**Props:** None (accessed via route `'/shorts'`)

**Navigating to it:**
```dart
import 'package:go_router/go_router.dart';

// In any widget with context
context.go('/shorts');

// Or with GoRouter programmatically
GoRouter.of(context).go('/shorts');
```

**Displays:**
- Vertical PageView of videos
- Auto-play on page change
- Loading and error states

**Manages:**
- View count increments
- Page transitions

### ShortVideoPlayer

**Type:** `ConsumerStatefulWidget`

**File:** `lib/features/shorts/shorts_screen.dart`

**Props:**
```dart
ShortVideoPlayer({
  required Short short,
  required ShortsRepository shortsRepository,
})
```

**Example usage (internal only):**
```dart
// Usually created by ShortsScreen, but can be used standalone
ShortVideoPlayer(
  short: shortModel,
  shortsRepository: repositoryInstance,
)
```

**Features:**
- Video playback
- Play/pause control
- Mute toggle
- Like/unlike
- Share functionality
- Social stats display

**Callback Methods:**
- Tap video: Toggle play/pause
- Tap like: Toggle like state
- Tap comment: Placeholder (navigate to comments in future)
- Tap share: Increment share count
- Tap mute: Toggle mute state

---

## Repository

### ShortsRepository

**Type:** `class`

**File:** `lib/providers/shorts_providers.dart`

**Constructor:**
```dart
ShortsRepository(FirebaseFirestore firestore)
```

**Methods:**

#### getShortsStream()
```dart
Stream<List<Short>> getShortsStream()
```
**Returns:** Stream of all shorts ordered by creation date

**Example:**
```dart
final repository = ShortsRepository(FirebaseFirestore.instance);
final shortsStream = repository.getShortsStream();
shortsStream.listen((shorts) {
  print('Loaded ${shorts.length} shorts');
});
```

#### incrementViewCount()
```dart
Future<void> incrementViewCount(String shortId)
```
**Parameters:**
- `shortId` (String) - Document ID

**Throws:** `FirebaseException` on error

**Example:**
```dart
await repository.incrementViewCount('short123');
```

#### likeShort()
```dart
Future<void> likeShort(String shortId)
```
**Parameters:**
- `shortId` (String) - Document ID

**Effect:** Increments `likeCount` by 1 in Firestore

**Throws:** `FirebaseException` on error

**Example:**
```dart
await repository.likeShort('short123');
```

#### unlikeShort()
```dart
Future<void> unlikeShort(String shortId)
```
**Parameters:**
- `shortId` (String) - Document ID

**Effect:** Decrements `likeCount` by 1 in Firestore

**Throws:** `FirebaseException` on error

**Example:**
```dart
await repository.unlikeShort('short123');
```

#### shareShort()
```dart
Future<void> shareShort(String shortId)
```
**Parameters:**
- `shortId` (String) - Document ID

**Effect:** Increments `shareCount` by 1 in Firestore

**Throws:** `FirebaseException` on error

**Example:**
```dart
await repository.shareShort('short123');
```

---

## Common Patterns

### Subscribe to all shorts and rebuild on change

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsync = ref.watch(shortsProvider);
    
    return shortsAsync.when(
      loading: () => LoadingWidget(),
      error: (err, stack) => ErrorWidget(err),
      data: (shorts) => ShortsListWidget(shorts),
    );
  }
}
```

### Get specific short

```dart
final shortAsync = ref.watch(shortByIdProvider('short123'));
```

### Update engagement metrics

```dart
final repository = ref.read(shortsRepositoryProvider);

// Like it
await repository.likeShort(shortId);

// Share it
await repository.shareShort(shortId);

// Track view
await repository.incrementViewCount(shortId);
```

### Navigate and handle errors

```dart
try {
  await repository.likeShort(shortId);
  // Success - UI already updated via stream
} on FirebaseException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.message}')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Unexpected error: $e')),
  );
}
```

---

## Type Definitions

### AsyncValue (Riverpod)

```dart
// When watching a provider:
final async = ref.watch(someProvider);

// AsyncValue has three states:
async.when(
  loading: () => { /* Loading widget */ },
  error: (error, stackTrace) => { /* Error widget */ },
  data: (data) => { /* Success widget */ },
);

// Or pattern match:
if (async is AsyncLoading) { }
else if (async is AsyncError) { }
else if (async is AsyncData) { }
```

---

## Error Handling

### Firebase Exceptions

```dart
import 'package:firebase_core/firebase_core.dart';

try {
  await repository.likeShort(shortId);
} on FirebaseException catch (e) {
  // Firebase error codes:
  // - 'permission-denied': User lacks permission
  // - 'not-found': Document not found
  // - 'aborted': Transaction aborted
  // - 'unavailable': Service unavailable
  
  print('Firebase error: ${e.code}');
  print('Message: ${e.message}');
}
```

### Video Loading Errors

Video player controller errors are handled in `ShortVideoPlayer`:
```dart
_controller = VideoPlayerController.networkUrl(Uri.parse(url))
  ..initialize().catchError((error) {
    // Error displayed via SnackBar
  });
```

---

## Constants & Configuration

### Firestore Collection Name
```dart
const String SHORTS_COLLECTION = 'shorts';
```

### Default Query Limits
```dart
const int SHORTS_INITIAL_LOAD = 20;  // Load 20 shorts at a time
const int SHORTS_TAGS_DISPLAY = 3;   // Show max 3 tags
```

### UI Constants
```dart
const double AUTHOR_AVATAR_RADIUS = 20.0;
const double CONTROL_BUTTON_SIZE = 24.0;
const double CONTROL_BUTTON_PADDING = 12.0;
```

---

## Imports Reference

### Core imports
```dart
// For using ShortsScreen
import 'package:porno_social/features/shorts/shorts_screen.dart';

// For data model
import 'package:porno_social/models/short.dart';

// For providers
import 'package:porno_social/providers/shorts_providers.dart';

// For state management
import 'package:flutter_riverpod/flutter_riverpod.dart';

// For routing
import 'package:go_router/go_router.dart';
```

---

## Version Information

- **video_player:** ^2.8.0
- **flutter_riverpod:** ^2.5.0
- **cloud_firestore:** ^5.0.0
- **go_router:** ^13.0.0
- **Flutter SDK:** ^3.10.8

---

## Related Documentation

- [PHASE_4_SHORTS_GUIDE.md](./PHASE_4_SHORTS_GUIDE.md) - Feature overview
- [SHORTS_QUICK_START.md](./SHORTS_QUICK_START.md) - Testing guide
- [SHORTS_DEVELOPER_GUIDE.md](./SHORTS_DEVELOPER_GUIDE.md) - Architecture details
- [FIRESTORE_RULES.md](./FIRESTORE_RULES.md) - Security rules
