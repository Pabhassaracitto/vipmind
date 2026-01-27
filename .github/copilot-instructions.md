Repository-specific Copilot instructions for vipmind_new

Purpose
- Short: help an AI coding agent become productive quickly in this Flutter codebase.

Big picture (what to know first)
- App roots: there are two app entry points. The demo entry is [lib/main.dart](lib/main.dart). The full app entry that initializes Firebase, providers, and storage is [lib/features/backupmain](lib/features/backupmain).
- App shell: the main MaterialApp is implemented in [lib/app/app.dart](lib/app/app.dart) and routes are in [lib/app/routes.dart](lib/app/routes.dart).
- Domain layout: core services live under [lib/core](lib/core) (e.g., `firebase_service.dart`, `storage_service.dart`); app state and business logic live under [lib/data] (providers, repositories, models); UI features live under [lib/features].

State & architecture patterns
- Primary state management uses `provider` and `ChangeNotifier` (see [lib/data/providers/*.dart](lib/data/providers)). Prefer following the ChangeNotifier/provider pattern when adding stateful features.
- Data access follows repository pattern. Firestore access is centralized in repositories under [lib/data/repositories](lib/data/repositories) (example: `MindmapRepository`).
- Long-lived services: use `StorageService.init()` and `Firebase.initializeApp()` early (see [lib/features/backupmain](lib/features/backupmain)).

Important code patterns to follow
- Undo/redo and canvas layout logic live in `MindmapProvider` ([lib/data/providers/mindmap_provider.dart](lib/data/providers/mindmap_provider.dart)). Avoid breaking its state shape; add migrations if you change model fields.
- Routes use `AppRoutes.generateRoute` with named constants (see [lib/app/routes.dart](lib/app/routes.dart)). Add screens by registering them here.
- Firestore collections and helpers are in [lib/core/services/firebase_service.dart](lib/core/services/firebase_service.dart). Use those helpers rather than creating ad-hoc collection paths.

Build / run / developer workflows
- Standard Flutter commands apply: `flutter pub get`, `flutter run`, `flutter build`.
- To run the full app (with Firebase + SharedPreferences initialization) use:

```bash
flutter run -t lib/features/backupmain
```

- If you need the simple demo entrypoint use:

```bash
flutter run -t lib/main.dart
```

- Code generation: Hive models use `hive_generator`. Regenerate with:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Project-specific conventions
- Prefer `ChangeNotifier` + `Provider` for new UI-level state unless a compelling reason to use `flutter_riverpod` exists; the codebase currently uses `provider` extensively.
- Persisted small settings use `StorageService` (SharedPreferences wrapper) — call `StorageService.init()` during app startup.
- Firestore timestamps use `FieldValue.serverTimestamp()` inside repository save methods — keep this pattern for `createdAt`/`updatedAt`.

Integration points & external deps
- Firebase: auth, firestore, storage, analytics (see `pubspec.yaml`). Use `FirebaseService` helpers.
- Local persistence: `shared_preferences` via `StorageService` and `hive` for models (check `dev_dependencies` for generators).
- Audio and AI helpers: `just_audio`, `flutter_tts`, `dio`/`http` — inspect `lib/core/services` or `lib/features/ai_engine` for existing usage.

What to avoid/change carefully
- Don't change the mindmap model shape without adding a migration path — `MindmapProvider` keeps in-memory maps keyed by node id and relies on specific fields (positions, childrenIds, size).
- Avoid adding global singletons that bypass `Provider` (makes testing and state tracing harder).

Where to look first when editing
- Start with these files when making cross-cutting changes: [lib/features/backupmain](lib/features/backupmain), [lib/app/app.dart](lib/app/app.dart), [lib/core/services/firebase_service.dart](lib/core/services/firebase_service.dart), [lib/data/providers/mindmap_provider.dart](lib/data/providers/mindmap_provider.dart), [lib/data/repositories/mindmap_repository.dart](lib/data/repositories/mindmap_repository.dart).

If something is unclear
- Ask the maintainer which entrypoint they consider canonical (demo vs full). Also confirm if `provider` remains the preferred state approach.

Feedback
- I added repo-specific examples and run commands. Tell me which sections feel incomplete or need more examples and I will iterate.
