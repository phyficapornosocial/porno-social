# Firebase Hosting Multi-Site Plan

This repo currently deploys a single Firebase Hosting site from [firebase.json](firebase.json).

Current verified state:

- `www.porno-social.com` is serving from Firebase Hosting.
- `porno-social.com` also serves successfully, but the move to `www` is only done in browser JavaScript from [web/index.html](web/index.html).
- A real HTTP redirect from apex to `www` requires a separate Hosting site for the apex domain.

## Goal

Serve the application on `www.porno-social.com` and issue a real permanent redirect:

- `https://porno-social.com/*` -> `https://www.porno-social.com`

## Recommended Site Layout

Keep the existing site for the app:

- app site id: `pornosocial-c003d`
- target name: `www`

Create one new Hosting site for the redirect-only apex domain:

- redirect site id: `pornosocial-c003d-apex`
- target name: `apex`

## Firebase Console Steps

1. Open Firebase Console.
2. Select project `pornosocial-c003d`.
3. Open `Hosting`.
4. Keep the existing site `pornosocial-c003d` attached to `www.porno-social.com`.
5. Create a second Hosting site named `pornosocial-c003d-apex`.
6. Attach `porno-social.com` to `pornosocial-c003d-apex`.
7. Leave `www.porno-social.com` attached to `pornosocial-c003d`.

## `.firebaserc` Targets

After the second site exists, update [ .firebaserc ](.firebaserc) to include Hosting targets like this:

```json
{
  "projects": {
    "default": "pornosocial-c003d"
  },
  "targets": {
    "pornosocial-c003d": {
      "hosting": {
        "www": [
          "pornosocial-c003d"
        ],
        "apex": [
          "pornosocial-c003d-apex"
        ]
      }
    }
  },
  "etags": {}
}
```

## `firebase.json` Multi-Site Config

Replace the single `hosting` object in [firebase.json](firebase.json) with a two-site Hosting array:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": {
    "source": "functions",
    "runtime": "nodejs20"
  },
  "hosting": [
    {
      "target": "www",
      "public": "build/web",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        { "source": "**", "destination": "/index.html" }
      ],
      "headers": [
        {
          "source": "**",
          "headers": [
            { "key": "X-Content-Type-Options", "value": "nosniff" },
            { "key": "X-Frame-Options", "value": "DENY" },
            { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
            {
              "key": "Content-Security-Policy",
              "value": "default-src 'self'; base-uri 'self'; object-src 'none'; frame-ancestors 'none'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.firebaseapp.com https://*.gstatic.com https://*.googleapis.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data: blob: https:; font-src 'self' https://fonts.gstatic.com data:; connect-src 'self' https://*.googleapis.com https://*.firebaseio.com https://*.firebasedatabase.app https://*.firebaseapp.com https://identitytoolkit.googleapis.com https://securetoken.googleapis.com https://firestore.googleapis.com https://firebaseinstallations.googleapis.com https://fcmregistrations.googleapis.com https://*.cloudfunctions.net https://maps.googleapis.com https://maps.gstatic.com wss://*.firebaseio.com wss://*.firestore.googleapis.com; worker-src 'self' blob:; manifest-src 'self'; media-src 'self' blob: https:; frame-src 'self' https://*.firebaseapp.com"
            }
          ]
        }
      ]
    },
    {
      "target": "apex",
      "public": "build/web",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "redirects": [
        {
          "source": "/**",
          "destination": "https://www.porno-social.com",
          "type": 301
        }
      ]
    }
  ]
}
```

This version intentionally prefers a reliable canonical-host redirect over path preservation. If you later want to preserve the full path and query string, test that separately against Firebase Hosting's capture syntax before switching production traffic.

## Why This CSP Is The Minimum Safe Explicit Version

The application currently uses:

- Firebase Core/Auth/Firestore from [lib/main.dart](lib/main.dart)
- Firebase Messaging from [lib/services/notification_service.dart](lib/services/notification_service.dart)
- a Firebase Messaging service worker from [web/firebase-messaging-sw.js](web/firebase-messaging-sw.js)
- Google Maps from [lib/features/events/widgets/event_form.dart](lib/features/events/widgets/event_form.dart)

That is why the CSP above explicitly allows:

- `script-src` for Firebase and Google script origins
- `connect-src` for Auth, Firestore, Realtime Database, FCM, Functions, and Maps calls
- `worker-src 'self' blob:` for Flutter web and service worker behavior
- `img-src`, `media-src`, and `font-src` broad enough for Flutter assets, remote images, and maps tiles
- `frame-src https://*.firebaseapp.com` for Firebase Auth hosted flows when needed

## Deploy Commands After Multi-Site Is Configured

Build once:

```powershell
flutter build web --release --base-href /
```

Deploy both sites:

```powershell
firebase deploy --only hosting
```

Or deploy them independently:

```powershell
firebase deploy --only hosting:www
firebase deploy --only hosting:apex
```

## Verification Checklist

1. `https://www.porno-social.com` returns `200`.
2. `https://porno-social.com` returns `301` to `https://www.porno-social.com`.
3. Auth works on both custom domains listed in Firebase Authentication authorized domains.
4. Firestore, Messaging, and Google Maps still work under the explicit CSP.
