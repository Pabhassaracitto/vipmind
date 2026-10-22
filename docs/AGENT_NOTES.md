# AGENT NOTES — VipMind

Short, opinionated notes for anyone (human or AI agent) working in this repo.
Read this before changing code. The audit that produced it:
[`bao-cao-tien-do-2026-10-22.md`](bao-cao-tien-do-2026-10-22.md).

## 1. Protected areas — think twice

* `lib/data/models/**` — these classes are the on-disk/Firestore shape. Changing
  a field means writing a migration path for documents already saved. Add a
  `fromJson` fallback rather than renaming a key.
* `lib/data/repositories/mindmap_repository.dart` — the only Firestore writer.
  Keep `FieldValue.serverTimestamp()` for `createdAt`/`updatedAt`, and keep
  models reading dates through `firestoreDateOr` (see §3).
* `lib/app/routes.dart` — see §2.
* `assets/templates/default_templates.json` — shipped data. `test/template_catalog_test.dart`
  validates it; a malformed entry breaks the Templates screen for every user.

## 2. Routes

* Every `AppRoutes` constant **must** have a `case` in `generateRoute`. Nine of
  fifteen were once commented out, so taps on Templates / AI / Flashcards / Zen /
  Settings silently returned the user to Home. `test/routes_test.dart` fails the
  build if a route stops resolving to its own screen.
* Screens live in `lib/features/**`. **Never** declare a widget inside
  `routes.dart` — that is how ten duplicate classes appeared
  (`routes.dart` had its own `SettingsScreen`, `ZenModeScreen`, …).
* Unknown routes render `UnknownRouteScreen` on purpose. Do not "improve" it into
  a silent redirect to Home: an unregistered route is a bug and should be loud.
* Arguments are read with `_arg` / `_requiredArg`, which never throw. A missing
  `mindmapId` yields `''` and the screen shows an empty state.

## 3. Firestore values are not the types you expect

The single most damaging bug in this repo: `saveMindmap()` writes
`FieldValue.serverTimestamp()`, so dates come back as `Timestamp`, while every
model read them with `DateTime.parse(...)` →
`type 'Timestamp' is not a subtype of type 'String'`. **Any saved mindmap could
never be reopened.**

Same family of traps:

| Firestore returns | Naive read | Use instead |
|---|---|---|
| `Timestamp` | `DateTime.parse(x)` | `firestoreDate` / `firestoreDateOr` |
| `int` for `3.0` | `Offset(json['x'], …)` | `firestoreDouble` |
| `double` for `4` | `int i = json['n']` | `firestoreInt` |
| `List<dynamic>` | `List<String>.from` is OK, `as List<String>` is not | `firestoreStringList` |
| nested `Map` | `as Map<String, dynamic>` | `firestoreMap` |

All of them live in `lib/core/utils/firestore_converters.dart`. New model code
**must** use them; `test/models_firestore_types_test.dart` pins the behaviour.

## 4. State

* `provider` + `ChangeNotifier`. Do not introduce Riverpod/Bloc "for one screen"
  (both were declared in `pubspec.yaml` without a single import).
* Providers own state and notifications. **Geometry lives in
  `lib/core/utils/mindmap_layout.dart`** (`MindmapLayoutEngine`) — pure static
  functions over `Map<String, NodeModel>`, so it is unit tested without
  Firestore. Undo/redo stays in `MindmapProvider`.
* `MindmapProvider` cannot be constructed in a test that touches Firestore
  (`MindmapRepository` grabs `FirebaseFirestore.instance` eagerly), so pure
  logic was moved out of it on purpose. Keep it that way.
* Small settings go through `StorageService` (SharedPreferences). It is
  null-safe before `init()`, and has `setInstanceForTesting` for widget tests.

## 5. Styling

* Fonts: `AppFonts` (bundled Inter, registered in `pubspec.yaml`). The project
  used `GoogleFonts.inter(...)`, which downloads fonts at runtime — a network
  dependency for a font that ships in the repo. `AppFonts.textTheme(base)` sets
  the family on every slot; `TextTheme().apply(fontFamily:)` silently does
  nothing because `apply` skips null styles.
* Colours: `AppColors` only. No raw `Color(0xFF…)` in widgets.
* `withOpacity()` is deprecated → use `withValues(alpha: …)`.
* A feature that is not built shows `ComingSoon` / `ComingSoonScreen`
  (`lib/core/widgets/coming_soon.dart`) with an honest "Planned for this screen"
  list. Do not fake progress with a widget that looks finished but does nothing,
  and do not leave a bare `Text('Coming Soon')`.

## 6. Dependencies

29 declared packages were unused (`hive`, `pdf`, `printing`, `screenshot`,
`share_plus`, `speech_to_text`, `flutter_tts`, `dio`, `flutter_riverpod`,
`image_picker`, `lottie`, `shimmer`, `flutter_svg`, `perfect_freehand`,
`flutter_painter_v2`, `permission_handler`, `connectivity_plus`, `vibration`,
`path_provider`, `firebase_storage`, `firebase_analytics`, `iconsax`,
`flutter_iconpicker`, `glassmorphism`, `audio_waveforms`,
`flutter_staggered_animations`, `vector_math`, `url_launcher`, `google_fonts`).
They are listed in a comment at the bottom of `pubspec.yaml`.

**Add a dependency in the commit that first imports it.** Every unused package is
extra native build surface (and `pubspec.lock` churn) for zero benefit.
`pubspec.lock` is regenerated by `flutter pub get`; it was deleted together with
those dependencies because it could not be resolved without an SDK in the
environment that made the change.

## 7. Platform config

* App id everywhere: **`com.vipmind`** (Android `namespace`/`applicationId`,
  iOS/macOS bundle id, `google-services.json`). Dart package: **`vipmind`**.
  Product name: **VipMind**. It used to be four different identities
  (`com.example.vipmind_new`, `com.example.vipmindNew`, `com.vipmind`,
  `com.example.neuromindmap`) which is why Android could not build.
* `com.google.gms.google-services` must stay applied, or
  `google-services.json` is ignored and Firebase fails at runtime.
* There must be exactly **one** `MainActivity.kt`
  (`android/app/src/main/kotlin/com/vipmind/`), and its `package` must match its
  directory. A second copy with a mismatched package used to sit in the same
  source set.
* iOS: `AppDelegate.swift` calls `FirebaseApp.configure()` guarded by
  `FirebaseApp.app() == nil`. It needs `ios/Runner/GoogleService-Info.plist`,
  which is **not in the repo** — see `SETUP_FIREBASE.md`.
* Manifest flags removed on purpose, do not re-add: `usesCleartextTraffic`,
  `requestLegacyExternalStorage`, `largeHeap` (Play policy / masked perf issues).

## 8. Definition of done

1. `flutter analyze` clean (CI blocks on it).
2. `flutter test` green (CI blocks on it).
3. `dart format .` applied.
4. If you touched a model: a `fromJson` test with **Firestore-shaped** input
   (ints, `Timestamp`, `List<dynamic>`).
5. If you touched a route: `test/routes_test.dart` still maps it to its screen.
6. If you added a screen: it is registered in `AppRoutes.generateRoute`.
7. If you added a package: it is imported somewhere in the same commit.

## 9. Known gaps (honest list)

* **Nobody has run `flutter pub get` / `analyze` / `test` / `build` on this
  branch yet** — the changes were made without an SDK in the environment. The
  first CI run is the real verdict; expect a handful of small fixes.
* iOS Firebase config missing (`GoogleService-Info.plist`).
* No Android release keystore.
* `CollaborationProvider` is an in-memory stub: no Firestore stream, so
  real-time collaboration does not exist.
* `_toggleFavorite` in `home_screen.dart`, share and export in the editor are
  still empty.
* Editor is unverified on a device: gestures, minimap and 798 lines of UI have
  never been exercised by a test that renders the canvas.
