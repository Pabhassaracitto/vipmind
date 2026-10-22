# VipMind

> Your Brain, Amplified — a mindmap editor that saves your maps to Firebase.

Flutter app. Android is the reference platform; iOS/macOS/Windows/Linux/web
scaffolding exists but only Android is wired for Firebase today.

---

## Status — read this first

**This project is a working skeleton, not a finished product (~25–30%).**

| Area | State |
|---|---|
| Mindmap editor (canvas, nodes, connections, zoom, minimap, toolbar, undo/redo, 3 auto-layouts) | code complete, **not yet verified on a device** |
| Auth, Home, Splash, Settings, Zen Mode, Templates | implemented (small but real) |
| AI (text/voice/image → mindmap), Anki review, Presentation, Export/Share, Collaboration | **not implemented** — those screens say so explicitly |
| Tests | `flutter test` — unit tests for layout, models, SM-2, validators, templates, routes; widget tests for splash, settings, zen mode |
| CI | GitHub Actions: `flutter analyze` + `flutter test` on every push/PR |

Full picture, evidence and the reason for each change:
[`docs/bao-cao-tien-do-2026-10-22.md`](docs/bao-cao-tien-do-2026-10-22.md).
Conventions for agents and humans: [`docs/AGENT_NOTES.md`](docs/AGENT_NOTES.md).

---

## Run it

```bash
flutter pub get
flutter run
```

`lib/main.dart` is the real entry point: it initialises `StorageService`, then
Firebase, then registers the providers and runs `VipMindApp`.

There is no second entry point any more. (There used to be: a demo `main.dart`
plus the real app hiding in an extension-less file called
`lib/features/backupmain`. Both are gone.)

### Firebase is required for login and sync

`android/app/google-services.json` is in the repo (project `vipmind-7c4bb`,
package `com.vipmind`), and the `com.google.gms.google-services` Gradle plugin
is applied, so **Android works after `flutter pub get`**.

**iOS will not**: `ios/Runner/GoogleService-Info.plist` is missing. Generate it
(and `lib/firebase_options.dart`) with the FlutterFire CLI — see
[`docs/SETUP_FIREBASE.md`](docs/SETUP_FIREBASE.md).

If Firebase is not configured, the app still starts: `main()` catches the
failure, logs what is missing and keeps going with cloud features disabled, so
you can work on the UI offline.

### Firestore

The app reads and writes the top-level `mindmaps` collection. It needs one
composite index (`ownerId` + `updatedAt`), provided in
[`firestore.indexes.json`](firestore.indexes.json), and the rules in
[`firestore.rules`](firestore.rules) are the recommended starting point.
Neither is deployed automatically — see `docs/SETUP_FIREBASE.md`.

---

## Project layout

```
lib/
  main.dart                 entry point: storage → Firebase → providers → app
  app/                      app shell, route table, theme, fonts, colours
  core/
    services/               Firebase, SharedPreferences, audio, haptics
    utils/                  validators, extensions, layout engine, Firestore converters
    widgets/                shared widgets (buttons, fields, ComingSoon)
  data/
    models/                 mindmap, node, connection, template, anki card, user, audio note
    providers/              ChangeNotifier state (mindmap, theme, audio, collaboration)
    repositories/           the only place that talks to Firestore
  features/
    mindmap/                editor, canvas, node widget, connection painter, toolbar,
                            minimap, zoom, node editor panel, preview
    home/  auth/  splash/   implemented
    settings/  zen_mode/  templates/   implemented (small)
    ai_engine/  anki/  presentation/   not implemented — honest placeholders
test/                       unit + widget tests (no device, no Firebase needed)
assets/                     audio effects, Inter fonts, bundled template catalog
```

Architecture: `provider` + `ChangeNotifier` for state, repository pattern for
Firestore. Do not add a second state-management approach.

---

## Conventions that matter

* **Routes:** every constant in `AppRoutes` must have a `case` in
  `generateRoute`. Nine of them were once commented out, so half the UI quietly
  navigated back to Home. `test/routes_test.dart` fails if that happens again.
* **Screens live in `lib/features/**`.** Never declare a screen inside
  `routes.dart` — that produced duplicate classes for ten screens.
* **Firestore types:** never assume a value's runtime type. Dates come back as
  `Timestamp`, whole numbers as `int`, arrays as `List<dynamic>`. Use the
  helpers in `lib/core/utils/firestore_converters.dart`.
* **Layout algorithms are pure** (`MindmapLayoutEngine`) so they stay testable.
  Keep provider code free of geometry.
* **A package is added to `pubspec.yaml` in the commit that uses it.** 29
  declared-but-unused packages were removed; each one was build risk for nothing.

---

## Useful commands

```bash
flutter analyze          # must be clean (CI enforces it)
flutter test             # must pass (CI enforces it)
dart format .            # run before pushing; CI reports drift
flutter build apk        # Android
```
