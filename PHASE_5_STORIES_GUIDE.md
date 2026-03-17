# Phase 5 — Stories (Instagram-style) Implementation Guide

## Overview
This phase adds Instagram-style stories to your app. Stories are temporary media (images/videos) that expire after 24 hours and track viewer information.

## Files Created

### Models
- **[lib/models/story.dart](lib/models/story.dart)** — Story model with Firestore serialization

### Providers
- **[lib/providers/stories_providers.dart](lib/providers/stories_providers.dart)** — Riverpod providers and StoriesRepository

### Features
- **[lib/features/stories/stories_bar.dart](lib/features/stories/stories_bar.dart)** — Horizontal scrollable stories bar with gradient borders (unviewed) and grey (viewed)
- **[lib/features/stories/story_viewer.dart](lib/features/stories/story_viewer.dart)** — Full-screen story viewer with progress animation, video support, and view tracking
- **[lib/features/stories/create_story_button.dart](lib/features/stories/create_story_button.dart)** — FAB to create new stories from gallery or camera
- **[lib/features/stories/index.dart](lib/features/stories/index.dart)** — Barrel export file

## Firestore Structure

```
/stories/{storyId}
  ├── authorId: String
  ├── authorName: String
  ├── authorAvatar: String
  ├── mediaUrl: String
  ├── mediaType: String ('image' | 'video')
  ├── expiresAt: Timestamp (now + 24 hours)
  ├── viewerIds: List<String>
  └── createdAt: Timestamp
```

## Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Stories
    match /stories/{storyId} {
      // Anyone can read non-expired stories
      allow read: if resource.data.expiresAt > now;
      
      // Only authenticated users can create
      allow create: if request.auth != null && 
        request.resource.data.authorId == request.auth.uid &&
        request.resource.data.viewerIds == [] &&
        request.resource.data.expiresAt == request.time;
      
      // Only author can update
      allow update: if request.auth != null &&
        resource.data.authorId == request.auth.uid &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['viewerIds']);
      
      // Only author can delete (or auto-delete via cloud functions)
      allow delete: if request.auth != null &&
        resource.data.authorId == request.auth.uid;
    }
  }
}
```

## Integration Steps

### 1. Update pubspec.yaml
Ensure these packages are installed:
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^25.0.0
  cloud_firestore: ^4.0.0
  firebase_storage: ^11.0.0
  firebase_auth: ^4.20.0
  flutter_riverpod: ^2.4.0
  image_picker: ^1.0.0
  cached_network_image: ^3.3.0
  video_player: ^2.7.0
```

### 2. Add StoriesBar to Feed Screen
In your feed/home screen:

```dart
import 'package:porno_social/features/stories/index.dart';

// In your feed widget:
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      StoriesBar(),
      // ... rest of feed
    ],
  );
}
```

### 3. Add Story Upload FAB
Add CreateStoryButton to your home screen:

```dart
floatingActionButton: CreateStoryButton(),
```

### 4. Add Model to barrel exports
Update [lib/models/index.dart](if it exists) or just import directly:

```dart
export 'story.dart';
```

## Features Implemented

### StoriesBar Widget
- ✅ Displays horizontal scrollable list of stories
- ✅ Red gradient border for unviewed stories
- ✅ Grey border for viewed stories
- ✅ Taps open full-screen StoryViewer
- ✅ Automatic filtering of expired stories
- ✅ Loading and error states
- ✅ Cached avatar images

### StoryViewer Widget
- ✅ Full-screen immersive view
- ✅ Progress bar showing story duration (5s default, video length if video)
- ✅ Author info and timestamp
- ✅ Image and video support (via VideoPlayer)
- ✅ Automatic view tracking (adds user to viewerIds)
- ✅ Back button to dismiss

### CreateStoryButton Widget
- ✅ FAB to create stories
- ✅ Choose from gallery or take photo
- ✅ Automatic upload to Firebase Storage
- ✅ Auto-delete stories after 24 hours via Firestore TTL (optional Cloud Function)

### StoriesRepository
- ✅ `getStoriesStream()` — Real-time stream of non-expired stories
- ✅ `getStoryById()` — Fetch single story
- ✅ `addViewer()` — Track story views
- ✅ `uploadStory()` — Create new story
- ✅ `deleteExpiredStories()` — Manual cleanup (use Cloud Functions instead)

## Cloud Function for Auto-Delete (Optional)

For automatic story deletion after 24 hours, set up this Cloud Function:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.deleteExpiredStories = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const expiredStories = await admin.firestore()
      .collection('stories')
      .where('expiresAt', '<', now)
      .get();

    const batch = admin.firestore().batch();
    expiredStories.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    return batch.commit();
  });
```

Or use Firestore TTL:
1. Go to Firestore Console
2. Select `stories` collection
3. In Rules tab, set TTL on `expiresAt` field

## Testing the Feature

1. **Create a story:**
   - Tap the CreateStoryButton FAB
   - Select "Take a Photo" or "Pick from Gallery"
   - Story uploads and appears in StoriesBar

2. **View a story:**
   - Tap an avatar in StoriesBar
   - Progress bar animates over 5 seconds
   - Back button dismisses and returns to feed

3. **Track views:**
   - In Firestore Console, view story doc
   - `viewerIds` array contains user IDs who viewed it

## Customization

### Change story duration
In [lib/features/stories/story_viewer.dart](lib/features/stories/story_viewer.dart), line ~52:
```dart
_progressController = AnimationController(
  duration: const Duration(seconds: 10), // Change from 5 to 10
  vsync: this,
);
```

### Change story expiration
In [lib/providers/stories_providers.dart](lib/providers/stories_providers.dart), line ~84:
```dart
final expiresAt = DateTime.now().add(const Duration(hours: 48)); // Change from 24 to 48
```

### Change gradient colors
In [lib/features/stories/stories_bar.dart](lib/features/stories/stories_bar.dart), lines ~36-39:
```dart
gradient: LinearGradient(
  colors: story.isViewed
      ? [Colors.grey[400]!, Colors.grey[600]!]
      : [Colors.purple, Colors.pink], // Change colors here
),
```

## Next Steps

- Add story reactions (emojis, text comments)
- Implement story sharing
- Add story search/discovery
- Add story statistics for creators
- Implement story collections/highlights
- Add music/music selection for stories
- Add stickers and filters

## Troubleshooting

**Stories not appearing:**
- Check Firestore rules allow `read` access
- Verify `expiresAt` timestamp is in the future
- Check authorAvatar URLs are valid

**Video not playing:**
- Ensure video_player plugin is installed
- Check video URLs are publicly accessible

**View tracking not working:**
- Verify auth state is available
- Check Firestore write rules allow updating `viewerIds`
- Check browser console for errors

**Storage quota exceeded:**
- Set up Cloud Function to auto-delete expired stories
- Or implement manual cleanup mechanism
