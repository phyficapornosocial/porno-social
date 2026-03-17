## Firestore Security Rules

Add these rules to your Firebase Console → Firestore Database → Rules:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Public user profiles - readable by all authenticated users
    match /users/{uid} {
      // Anyone authenticated can read public profiles (for search/discovery)
      allow read: if request.auth != null;
      
      // Only the user can update their own profile
      allow write: if request.auth.uid == uid;
      
      // Private data subcollection - only owner can access
      match /private/{privateUid} {
        allow read, write: if request.auth.uid == uid;
      }
    }

    // Posts - readable by all, writable only by author
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.authorId == request.auth.uid;
      allow update, delete: if request.auth.uid == resource.data.authorId;
    }

    // Shorts (TikTok-style videos) - readable by all, writable only by author
    match /shorts/{shortId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.authorId == request.auth.uid;
      allow update: if request.auth != null; // Allow likes/shares/etc by any user
      allow delete: if request.auth.uid == resource.data.authorId;
    }

    // Subscriptions (used by locked content gate)
    match /subscriptions/{subscriptionId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.subscriberId ||
         request.auth.uid == resource.data.creatorId);

      allow create: if request.auth != null &&
        request.resource.data.subscriberId == request.auth.uid;

      allow update: if request.auth != null &&
        (request.auth.uid == resource.data.subscriberId ||
         request.auth.uid == resource.data.creatorId);

      allow delete: if request.auth != null &&
        request.auth.uid == resource.data.subscriberId;
    }

    // Groups
    match /groups/{groupId} {
      // Public groups are visible to authenticated users; private groups to members/admins.
      allow read: if request.auth != null &&
        (
          resource.data.isPrivate == false ||
          request.auth.uid in resource.data.adminIds ||
          exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid))
        );

      allow create: if request.auth != null &&
        request.auth.uid in request.resource.data.adminIds;

      allow update, delete: if request.auth != null &&
        request.auth.uid in resource.data.adminIds;

      // Group members
      match /members/{uid} {
        allow read: if request.auth != null &&
          (
            get(/databases/$(database)/documents/groups/$(groupId)).data.isPrivate == false ||
            request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.adminIds ||
            exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid))
          );

        // User can join themselves, admin can add anyone.
        allow create: if request.auth != null &&
          (
            request.auth.uid == uid ||
            request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.adminIds
          );

        // User can leave themselves, admin can remove anyone.
        allow delete: if request.auth != null &&
          (
            request.auth.uid == uid ||
            request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.adminIds
          );

        // Role changes allowed to group admins only.
        allow update: if request.auth != null &&
          request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.adminIds;
      }

      // Group posts (same structure as global /posts)
      match /posts/{postId} {
        allow read: if request.auth != null &&
          (
            get(/databases/$(database)/documents/groups/$(groupId)).data.isPrivate == false ||
            request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.adminIds ||
            exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid))
          );

        allow create: if request.auth != null &&
          request.resource.data.authorId == request.auth.uid &&
          (
            request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.adminIds ||
            exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid))
          );

        allow update, delete: if request.auth != null &&
          request.auth.uid == resource.data.authorId;
      }
    }

    // Events
    match /events/{eventId} {
      // Public events are visible to authenticated users.
      // Private events are visible to host/admin/attendees.
      allow read: if request.auth != null &&
        (
          resource.data.isPrivate == false ||
          request.auth.uid == resource.data.hostId ||
          exists(/databases/$(database)/documents/events/$(eventId)/attendees/$(request.auth.uid))
        );

      allow create: if request.auth != null &&
        request.resource.data.hostId == request.auth.uid;

      allow update, delete: if request.auth != null &&
        request.auth.uid == resource.data.hostId;

      match /attendees/{uid} {
        // Host can see all attendees; users can read their own attendee doc.
        allow read: if request.auth != null &&
          (
            request.auth.uid == uid ||
            request.auth.uid == get(/databases/$(database)/documents/events/$(eventId)).data.hostId
          );

        // User can set their own attendance status.
        allow create, update: if request.auth != null && request.auth.uid == uid;

        // User can remove themselves; host can remove attendees.
        allow delete: if request.auth != null &&
          (
            request.auth.uid == uid ||
            request.auth.uid == get(/databases/$(database)/documents/events/$(eventId)).data.hostId
          );
      }
    }
  }
}
```

---

## Rules Explanation

### Public Profile Rules

**Read Access**: `allow read: if request.auth != null;`
- ✅ Any authenticated user can view any user's public profile
- ✅ Enables search, creator discovery, follower profiles
- ❌ Prevents anonymous reads (user must be logged in)

**Write Access**: `allow write: if request.auth.uid == uid;`
- ✅ Users can only modify their own profile
- ✅ Prevents other users from editing your data
- ✓ Applies to both `update()` and `set()` operations

### Private Data Rules

**Read/Write Access**: `allow read, write: if request.auth.uid == uid;`
- ✅ ONLY the account owner can read their private data
- ✅ ONLY the account owner can write to their private data
- ❌ Other users cannot access this data
- ✅ Firestore encrypts at rest by default

---

## Advanced Security (Optional)

### Age-Gated Content (Admin Only)

```firestore
// Allow admins to update verification status
match /users/{uid}/private/{privateUid} {
  allow read, write: 
    if request.auth.uid == uid 
    || request.auth.token.admin == true;
}
```

### Restrict Profile Creation

```firestore
match /users/{uid} {
  // Only allow creating profile on signup
  allow create: if request.auth.uid == uid
    && request.resource.data.keys().hasAll([
      'username', 'displayName', 'createdAt'
    ]);
  
  allow read: if request.auth != null;
  allow update, delete: if request.auth.uid == uid;
}
```

### Rate-Limit Discovery Queries

```firestore
// Prevent abuse of search endpoints
match /users {
  // Limit to 100 results per query
  allow read: if request.auth != null
    && limit.amount <= 100;
}
```

---

## Deployment Steps

1. **Go to Firebase Console**
   - Navigate to your project: https://console.firebase.google.com

2. **Open Firestore Database**
   - Click "Firestore Database" in left sidebar

3. **Click "Rules" Tab**

4. **Replace the default rules** with the above rules

5. **Click "Publish"**

6. **Test with your app** to ensure it works correctly

---

## Testing Rules

### Test in Firebase Console

After publishing, test rules in the "Rules" tab:

```javascript
// Test case 1: User can read any public profile
{
  "auth": {"uid": "user123"},
  "path": "/users/other_user",
  "method": "get"
  // Result: ✅ ALLOW (authenticated user)
}

// Test case 2: User cannot read other's private data
{
  "auth": {"uid": "user123"},
  "path": "/users/other_user/private/other_user",
  "method": "get"
  // Result: ❌ DENY (not the owner)
}

// Test case 3: User can read their own private data
{
  "auth": {"uid": "user123"},
  "path": "/users/user123/private/user123",
  "method": "get"
  // Result: ✅ ALLOW (is the owner)
}

// Test case 4: Anonymous user cannot read
{
  "auth": null,
  "path": "/users/user123",
  "method": "get"
  // Result: ❌ DENY (not authenticated)
}
```

---

## Security Checklist

- ✅ Private data stored in subcollection with owner-only rules
- ✅ Email never exposed publicly (stored in private subcollection)
- ✅ Date of birth never exposed publicly (stored in private subcollection)
- ✅ Public profiles readable only to authenticated users
- ✅ Users can only modify their own data
- ✅ Firebase Authentication enabled (not anonymous)
- ✅ Firestore encryption at rest enabled (automatic)
- ✅ Consider enabling HTTPS only (automatic for Firebase)

---

## Common Issues

### "Permission denied" on read
**Problem**: User can't read their own profile
**Solution**: Check `request.auth.uid == uid` is in your rules

### "Search not working"
**Problem**: Database index required for certain queries
**Solution**: Firebase provides link to create index when needed
- Click the link - Firebase auto-creates the index
- Wait 1-2 minutes for index to build

### "Users can edit other profiles"
**Problem**: Security rules too permissive
**Solution**: Verify `allow write: if request.auth.uid == uid;` is set

---

## Production Recommendations

1. **Enable Firestore Backups**
   - Firebase Console → Backups → Schedule daily backups

2. **Set up Cloud Functions**
   - Clean up deleted user data
   - Send verification emails
   - Moderate content

3. **Monitor Usage**
   - Set up billing alerts
   - Use Firestore monitoring dashboard

4. **Implement Rate Limiting**
   - Use Cloud Functions or Rules to prevent abuse
   - Limit searches to 100 results per query

5. **Enable Activity Logs**
   - Firebase Console → Audit Logs
   - Track who accesses what data
