# Firebase setup

The app talks to Firebase for two things only: **Auth** (email/password) and
**Cloud Firestore** (the `mindmaps` collection). Everything else is local.

Project in use: **`vipmind-7c4bb`** (see `android/app/google-services.json`).
If that project is no longer reachable, create a new one and redo the steps
below — nothing else in the repo hard-codes it except that file.

---

## 1. What already works: Android

| Piece | Where | Status |
|---|---|---|
| `google-services.json` | `android/app/google-services.json` | ✅ in repo, `package_name` = `com.vipmind` |
| `com.google.gms.google-services` Gradle plugin | `android/settings.gradle.kts` + `android/app/build.gradle.kts` | ✅ applied (it was **missing** — without it the JSON is never processed and `Firebase.initializeApp()` throws at runtime) |
| `applicationId` / `namespace` | `android/app/build.gradle.kts` | ✅ `com.vipmind`, matching the JSON |
| `minSdk` | `android/app/build.gradle.kts` | ✅ forced to ≥ 23 (Firebase requirement) |

So on Android: `flutter pub get && flutter run` is enough.

## 2. What is missing: iOS

`ios/Runner/GoogleService-Info.plist` is **not in the repository**, and the
Firebase project has no iOS app registered (the JSON contains only an Android
client). Until that exists, `FirebaseApp.configure()` in
`ios/Runner/AppDelegate.swift` logs a warning and returns nothing; the Dart side
catches it and the app runs with cloud features disabled.

## 3. Recommended: generate everything with FlutterFire CLI

This produces `lib/firebase_options.dart` **and** the platform config files for
every platform you select, and registers the apps in the Firebase project.

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=vipmind-7c4bb --platforms=android,ios
```

Then:

1. `ios/Runner/GoogleService-Info.plist` appears — add it to the Xcode project
   (`ios/Runner.xcodeproj`) as a member of the **Runner** target, otherwise it
   is not copied into the bundle. The CLI prints the exact `fileRef` lines if
   you prefer editing `project.pbxproj` by hand.
2. Switch `lib/main.dart` to the generated options:

   ```dart
   import 'firebase_options.dart';
   ...
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

   Both the import and the call are already present in `main.dart` as comments
   exactly where they belong.
3. `lib/firebase_options.dart` is git-ignored on purpose (it is tied to your
   Firebase login). If you would rather commit it, remove that line from
   `.gitignore` — it contains no secrets, only identifiers.

## 4. Firestore

### Indexes

`MindmapRepository.getMindmaps()` runs
`where('ownerId', isEqualTo: …).orderBy('updatedAt', descending: true)`.
Firestore refuses an inequality-plus-sort query without a **composite index**;
the first call fails with `failed-precondition` and a console URL.

The required index is declared in [`../firestore.indexes.json`](../firestore.indexes.json). Deploy with:

```bash
npm i -g firebase-tools
firebase login
firebase deploy --only firestore:indexes
```

(or paste the index manually in Console → Firestore → Indexes).

### Rules

[`../firestore.rules`](../firestore.rules) is the recommended starting point:
a signed-in user may read/write their own maps, maps they collaborate on, and
public maps. Deploy with:

```bash
firebase deploy --only firestore:rules
```

> The rules are written for the **top-level `mindmaps` collection**, which is
> what `MindmapRepository` actually uses. Note that
> `lib/core/services/firebase_service.dart` also exposes a
> `userMindmaps(userId)` subcollection helper that **nothing calls** — do not
> "fix" the rules for it without first deciding which shape the product keeps.

### Enable Email/Password

Console → Authentication → Sign-in method → **Email/Password** → Enable.
`register_screen.dart` / `login_screen.dart` use
`createUserWithEmailAndPassword` / `signInWithEmailAndPassword`.

## 5. Verify

```
flutter run            # Android device or emulator
```

Expected: splash → login → register an account → Home → create a mindmap →
editor. Kill and relaunch the app: the map must still be there. If loading the
list fails with `failed-precondition`, the composite index from step 4 is not
deployed.

## 6. Before publishing

* Android: replace the debug signing config in `android/app/build.gradle.kts`
  with a real keystore read from `android/key.properties` (never commit either).
* Remove `usesCleartextTraffic`, `requestLegacyExternalStorage` and `largeHeap`
  from the manifest — already done in this repo; do not re-add them.
* `google-services.json` is committed. That is normal practice for Android
  (it holds no secret), but confirm the Firebase project's API keys are
  restricted by app + package name in the console.
