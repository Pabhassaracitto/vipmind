import Flutter
import UIKit

// Firebase is initialised natively so the whole plugin stack (Auth, Firestore)
// is ready before the first Dart frame. `import Firebase` resolves through the
// firebase_core plugin's iOS pod, which depends on Firebase/Core.
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Requires ios/Runner/GoogleService-Info.plist — that file is NOT in the
    // repository yet. Generate it with `flutterfire configure`
    // (see docs/SETUP_FIREBASE.md). Until then the guard below keeps the app
    // booting instead of crashing, and lib/main.dart degrades gracefully.
    if FirebaseApp.app() == nil {
      if let app = FirebaseApp.configure() {
        print("[VipMind] Firebase configured: \(app.name)")
      } else {
        print("[VipMind] GoogleService-Info.plist missing — cloud features disabled.")
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
