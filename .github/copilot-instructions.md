# Repository-specific instructions for AI coding agents — VipMind

## Purpose

Get an AI coding agent productive in this Flutter repo in one read, and keep it
from repeating the mistakes that were already made here.

**Read [`docs/AGENT_NOTES.md`](docs/AGENT_NOTES.md) first** — it has the rules,
the protected areas and the definition of done. This file is the short map.

## Big picture

* **One entry point:** [`lib/main.dart`](lib/main.dart). It initialises
  `StorageService`, then Firebase (failure-tolerant), then registers the
  providers and runs `VipMindApp`.
  *There used to be two* — a demo `main.dart` and the real app in an
  extension-less `lib/features/backupmain`. Both are gone; do not recreate that
  split.
* **App shell:** [`lib/app/app.dart`](lib/app/app.dart) (`VipMindApp`).
* **Routes:** [`lib/app/routes.dart`](lib/app/routes.dart) — named constants plus
  `generateRoute`. Every constant must have a `case`; screens are imported from
  `lib/features/**`, never declared in this file.
* **Identity:** product `VipMind`, Dart package `vipmind`, app id `com.vipmind`
  on every platform. Keep them consistent — mismatched ids are why Android could
  not build.

## Layering

```
lib/app        shell, routes, theme (AppTheme), fonts (AppFonts), colours (AppColors)
lib/core       services (Firebase, SharedPreferences, audio, haptic),
               utils (validators, extensions, MindmapLayoutEngine, firestore_converters),
               shared widgets (CustomButton, CustomTextField, ComingSoon)
lib/data       models · providers (ChangeNotifier) · repositories (the only Firestore code)
lib/features   UI per feature
```

## Patterns to follow

* **State:** `provider` + `ChangeNotifier`. No second state framework.
* **Data access:** repository pattern; `MindmapRepository` is the only class
  that touches Firestore collections. Keep
  `FieldValue.serverTimestamp()` for `createdAt`/`updatedAt`.
* **Firestore reads:** always through
  [`lib/core/utils/firestore_converters.dart`](lib/core/utils/firestore_converters.dart)
  (`firestoreDateOr`, `firestoreDouble`, `firestoreInt`, `firestoreStringList`,
  `firestoreMap`, `firestoreEnum`, `firestoreColorValue`). Dates come back as
  `Timestamp`, whole numbers as `int`, arrays as `List<dynamic>`; naive casts
  threw at runtime and made saved mindmaps unreadable.
* **Geometry:** pure functions in `MindmapLayoutEngine` (radial / tree /
  org-chart), unit tested without Firebase. Providers hold state, not math.
  Use `dart:math`, never a hand-rolled series expansion.
* **Fonts:** `AppFonts` (bundled Inter). Not `google_fonts` — that downloads at
  runtime.
* **Unimplemented feature:** `ComingSoonScreen` from
  [`lib/core/widgets/coming_soon.dart`](lib/core/widgets/coming_soon.dart) with an
  honest "Planned for this screen" list.

## Dependencies

Only what is imported is declared (11 packages). `pubspec.yaml` carries a
comment listing the 29 that were removed as unused. **Add a package in the
commit that first uses it.**

## Build / run / test

```bash
flutter pub get
flutter run                       # lib/main.dart is the entry point
flutter analyze                   # CI blocks on this
flutter test                      # CI blocks on this
dart format .                     # run before pushing
```

CI: [`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs analyze + test on
every push and PR.

Firebase (Android works out of the box; iOS needs
`GoogleService-Info.plist`): [`docs/SETUP_FIREBASE.md`](docs/SETUP_FIREBASE.md).
Firestore composite index: [`firestore.indexes.json`](firestore.indexes.json).
Rules: [`firestore.rules`](firestore.rules).

## Change carefully

* `lib/data/models/**` — the persisted shape. Changing a field needs a migration
  path and a `fromJson` test with Firestore-shaped input.
* `MindmapProvider` keeps undo/redo stacks and in-memory maps keyed by node id;
  it relies on `position`, `childrenIds`, `parentId`, `depth`, `size`.
* `android/app/build.gradle.kts` + `android/settings.gradle.kts` — the
  `com.google.gms.google-services` plugin must stay applied, and `applicationId`
  must equal `package_name` in `google-services.json`.
* Exactly one `MainActivity.kt`, in `kotlin/com/vipmind/`, package matching the
  directory.

## Definition of done

`flutter analyze` clean · `flutter test` green · `dart format .` applied · new
screen registered in `AppRoutes` · new model field covered by a `fromJson` test ·
new package imported in the same commit. Full list in `docs/AGENT_NOTES.md` §8.

## When something is unclear

* Which features are real vs. placeholders → `docs/AGENT_NOTES.md` §9 and the
  progress report [`docs/bao-cao-tien-do-2026-10-22.md`](docs/bao-cao-tien-do-2026-10-22.md).
* Product decisions still open (iOS support, AI provider, Anki vs. export
  priority) → ask the maintainer; do not pick one silently.
