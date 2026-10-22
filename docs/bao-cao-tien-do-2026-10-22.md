# BÁO CÁO TIẾN ĐỘ DỰ ÁN — VipMind (NeuroMindmap)

**Ngày báo cáo:** 22/10/2026
**Kho mã nguồn:** `Pabhassaracitto/vipmind` (public, Flutter)
**Nhánh khảo sát:** `arena/39395bf9-vipmind` (từ `main` @ `b79f138`)
**Người lập:** Agent Arena — khảo sát bằng đọc mã nguồn + dữ liệu git/GitHub/Linear

> ⚠️ **Giới hạn của báo cáo:** trong môi trường này **không có Flutter/Dart SDK**, nên chưa chạy được
> `flutter pub get`, `flutter analyze`, `flutter test` hay build APK. Mọi kết luận "lỗi build" dưới đây là
> **suy ra từ bằng chứng trong mã nguồn** (đường dẫn, package, manifest, pubspec), có ghi rõ file + dòng.
> Cần một lần chạy thật trên máy có SDK để xác nhận trước khi sửa hàng loạt.

---

## 1. TÓM TẮT ĐIỀU HÀNH (30 giây)

| Hạng mục | Trạng thái |
|---|---|
| Tiến độ tổng thể (ước lượng theo mã nguồn) | **~25–30%** |
| Lõi tính năng (vẽ/sửa sơ đồ tư duy) | **~60–70%** code đã viết, **chưa kiểm chứng chạy được** |
| Các tính năng "hứa hẹn" (AI, Anki, Presentation, Zen, Templates, Settings, Export) | **0%** — chỉ có màn hình "Coming Soon" |
| Khả năng build & chạy | 🔴 **ĐỎ — đang có lỗi chặn build Android và iOS** |
| Kiểm thử tự động | 🔴 **0 test hợp lệ** (file test duy nhất tham chiếu package/class không tồn tại) |
| CI/CD | 🔴 **Không có** (`.github/` chỉ chứa `copilot-instructions.md`) |
| Lịch sử git | **1 commit duy nhất** (28/01/2026). GitHub `pushedAt` = 18/02/2026 → **~8 tháng không có hoạt động** |
| Quản lý công việc (Linear) | **Không có project/card nào cho VipMind** — Linear workspace hiện chỉ có `In4up` + `UIUX` (PaliNeti, VDP, Kiểm định 1.10.4 / 0.10.3) |

**Kết luận thẳng:** dự án đang ở trạng thái **"prototype lõi + khung app" bị bỏ dừng giữa chừng**, chưa phải
sản phẩm chạy được. Vấn đề lớn nhất **không phải thiếu tính năng**, mà là **xung đột danh tính project**
(3 tên gọi / 4 package id khác nhau) khiến **cả build Android lẫn iOS đều gãy**, và **entrypoint thật của
app đang nằm trong một file không có đuôi `.dart`**.

---

## 2. SỐ LIỆU MÃ NGUỒN

**54 file Dart — 8.845 dòng** trong `lib/`:

| Nhóm | Files | Dòng | Đánh giá |
|---|---:|---:|---|
| `features/mindmap` (editor, canvas, node, connection, minimap, zoom, toolbar) | 10 | 2.788 | 🟡 Code dày, có chiều sâu — chưa kiểm chứng |
| `data` (7 models, 4 providers, 1 repository) | 12 | 1.729 | 🟡 Khá đầy đủ cho phần lõi |
| `features/home` (screen + 4 widgets) | 5 | 1.331 | 🟢 UI hoàn chỉnh về mặt code |
| `core` (4 services, 2 utils, 2 widgets) | 8 | 941 | 🟡 Firebase/Storage/Haptic OK; Audio **sẽ crash** (xem §4.6) |
| `features/auth` (login, register) | 2 | 768 | 🟡 Có UI, thiếu xử lý lỗi/reset password |
| `app` (app.dart, routes.dart, theme) | 4 | 657 | 🔴 **routes.dart bị comment mất 9/15 route** |
| `features/splash` | 1 | 236 | 🟢 |
| `features/ai_engine` | 4 | **36** | 🔴 3 file "Coming Soon" 12 dòng + **1 file 0 dòng** |
| `features/anki` | 2 | 25 | 🔴 "Coming Soon" |
| `features/presentation` | 2 | 25 | 🔴 "Coming Soon" + file trùng tên sai class |
| `features/zen_mode` | 1 | 18 | 🔴 "Coming Soon" |
| `features/templates` | 1 | 12 | 🔴 "Coming Soon" |
| `features/settings` | 1 | 12 | 🔴 "Coming Soon" |

**5 `TODO` chưa làm**, tất cả trong `mindmap_editor_screen.dart` (dòng 683–708):
AI suggestions, Voice recorder, Image picker, Share, Export — **đều là tính năng quảng bá của app**.

**Phụ thuộc khai báo vs thực dùng:** `pubspec.yaml` khai báo ~40 package, nhưng chỉ **11 package** thực sự
được `import` trong `lib/` (`flutter`, `firebase_auth`, `uuid`, `animate_do`, `provider`, `cloud_firestore`,
`google_fonts`, `shared_preferences`, `just_audio`, `intl`, `flutter_colorpicker`).
→ **29 package chết**: `hive`, `pdf`, `printing`, `screenshot`, `share_plus`, `speech_to_text`, `flutter_tts`,
`dio`, `flutter_riverpod`, `image_picker`, `lottie`, `shimmer`, `flutter_svg`, `perfect_freehand`,
`flutter_painter_v2`, `permission_handler`, `connectivity_plus`, `vibration`, `path_provider`,
`firebase_storage`, `firebase_analytics`, `iconsax`, `flutter_iconpicker`, `glassmorphism`,
`audio_waveforms`, `flutter_staggered_animations`, `vector_math`, `url_launcher`.
Mỗi package chết là một rủi ro build/native không cần thiết (đặc biệt nhóm native: `permission_handler`,
`speech_to_text`, `image_picker`, `just_audio`).

---

## 3. PHẦN ĐÃ LÀM ĐƯỢC (ghi nhận đúng công sức)

1. **Kiến trúc phân lớp rõ ràng, đúng chuẩn Flutter:** `app/` (shell + routes + theme) → `core/` (services,
   widgets dùng chung) → `data/` (models / providers / repository) → `features/` (UI theo tính năng).
   Dùng `provider` + `ChangeNotifier`, dữ liệu Firestore đi qua repository (`MindmapRepository`, 9 hàm CRUD
   + `getSharedMindmaps` + `searchMindmaps`). Đây là nền tốt, không phải code "vứt đi".
2. **Model nghiệp vụ khá chín:** `NodeModel` (214 dòng) có shape/type/icon/image/audioNote/childrenIds/
   parentId/depth/isExpanded + **nhóm trường Anki** (`isAnkiCard`, `ankiFront`, `ankiBack`, `ankiInterval`,
   `ankiNextReview`) → ý định làm flashcard từ node đã được thiết kế ở tầng dữ liệu.
3. **`MindmapProvider` (534 dòng) là tài sản giá trị nhất:** undo/redo stack, add/move/delete node,
   toggle expand, connections, canvas offset/scale, và **3 thuật toán auto-layout** (radial, tree, org-chart).
4. **Editor UI đầy đủ về mặt component:** `mindmap_canvas`, `node_widget`, `connection_painter`,
   `minimap_widget`, `zoom_controls`, `toolbar_widget`, `node_editor_panel` (437 dòng).
5. **Home + Auth + Splash** đã có UI hoàn chỉnh (header, drawer, quick actions, mindmap card, tab, search,
   animation `animate_do`, dark/light theme qua `ThemeProvider`).
6. **AndroidManifest khai báo quyền đầy đủ** cho lộ trình sản phẩm (INTERNET, RECORD_AUDIO, CAMERA, VIBRATE,
   media permissions Android 13+), có cấu hình splash theme + `flutterEmbedding v2`.
7. **Có tài liệu hướng dẫn agent** (`.github/copilot-instructions.md`, 62 dòng) mô tả kiến trúc và lệnh chạy.

---

## 4. 🔴 CÁC LỖI CHẶN (BLOCKER) — phải sửa trước khi nói tới tính năng

### 4.1 Xung đột danh tính project: 3 tên, 4 package id → **build Android FAIL**

| Nơi | Giá trị |
|---|---|
| `pubspec.yaml` → `name` | `neuromindmap` |
| `README.md` | `vipmind_new` |
| `lib/main.dart` → app title | `VipMind` |
| `android/app/build.gradle.kts` → `namespace` + `applicationId` | `com.example.vipmind_new` |
| `android/app/google-services.json` → `package_name` | **`com.vipmind`** (project_id `vipmind-7c4bb`) |
| `ios/Runner.xcodeproj` → `PRODUCT_BUNDLE_IDENTIFIER` | `com.example.vipmindNew` |

**Hậu quả 1 — Android build gãy:** plugin `google-services` đối chiếu `package_name` trong
`google-services.json` với `applicationId`. `com.vipmind` ≠ `com.example.vipmind_new`
→ lỗi dạng *"No matching client found for package name 'com.example.vipmind_new'"*.

**Hậu quả 2 — hai class `MainActivity` trùng tên:**
- `android/app/src/main/kotlin/com/example/vipmind_new/MainActivity.kt` → `package com.example.vipmind_new` ✅
- `android/app/src/main/kotlin/com/vipmind/MainActivity.kt` → nhưng bên trong khai báo
  **`package com.example.neuromindmap`** ❌ (sai cả thư mục lẫn package)

Cả hai file đều nằm trong source set `main` → Gradle/Kotlin compile cả hai. Manifest khai báo
`android:name=".MainActivity"`, tức `com.example.vipmind_new.MainActivity` — file thứ hai là rác gây
rối biên dịch và phải xoá.

**Hậu quả 3 — iOS Firebase chết:** **không có** `ios/Runner/GoogleService-Info.plist` trong repo, và
`AppDelegate.swift` là bản mặc định (không `@import Firebase`; không `FirebaseApp.configure()`).
→ `Firebase.initializeApp()` trên iOS sẽ ném lỗi ngay khi khởi động.

### 4.2 Entrypoint thật của app **không phải là file Dart**

- `lib/main.dart` (267 dòng) là **bản demo độc lập**: tự định nghĩa `VipMindApp`, `HomePage`, `MindmapScreen`,
  `MindNode` — **không import bất kỳ thứ gì** trong `lib/app`, `lib/data`, `lib/features`.
  → `flutter run` mặc định sẽ chạy **trang demo "App is running! 🎉"**, **không phải** app thật.
  Toàn bộ 8.500+ dòng còn lại **không được biên dịch tới** từ entrypoint này.
- App thật nằm ở **`lib/features/backupmain`** — **thiếu đuôi `.dart`**, đặt sai chỗ (trong `features/`),
  tên vô nghĩa ("backup main"). File này mới là nơi `Firebase.initializeApp()`, `StorageService.init()`,
  `MultiProvider` (Theme/Mindmap/Audio/Collaboration) và `NeuroMindmapApp` được khởi động.
- `.github/copilot-instructions.md` hướng dẫn `flutter run -t lib/features/backupmain` → **lệnh này không
  hoạt động**: `-t` yêu cầu một file `.dart`. Tài liệu đang hướng dẫn sai.

### 4.3 Hệ thống route **bị comment mất 9/15 route** → app thật chạy sẽ điều hướng sai

`lib/app/routes.dart` chỉ còn xử lý: `splash`, `login`, `register`, `home`, `mindmapEditor`,
`mindmapPreview`. Toàn bộ khối còn lại (`textToMindmap`, `voiceToMindmap`, `imageToMindmap`,
`templateGallery`, `presentation`, `ankiDeck`, `flashcardReview`, `zenMode`, `settings`) **nằm trong comment
khối `/* ... */`**, rơi thẳng xuống `default: return HomeScreen()`.

Trong khi đó UI **gọi 15 lần** `Navigator.pushNamed` tới các route đã chết:
- `home_screen.dart:275,279,283,287` · `quick_actions.dart:21,27,33,39,45`
- `home_drawer.dart:85,93,101,110` · `mindmap_editor_screen.dart:677,712`

→ Bấm "Templates / Text-to-Mindmap / Voice / Image / Anki / Zen / Settings / Present" đều **quay về Home**.
Người dùng thật sẽ thấy app "bấm không ăn".

### 4.4 Duplicate class: 9 màn hình được định nghĩa **2 lần**, 1 file sai class hoàn toàn

`routes.dart` tự khai báo **placeholder** cho: `MindmapPreviewScreen`, `TextToMindmapScreen`,
`VoiceToMindmapScreen`, `ImageToMindmapScreen`, `TemplateGalleryScreen`, `PresentationScreen`,
`AnkiDeckScreen`, `FlashcardReviewScreen`, `ZenModeScreen`, `SettingsScreen` — trong khi các file thật cũng
tồn tại dưới `lib/features/**` với **cùng tên class**. Bất kỳ file nào import cả hai sẽ **không compile được**.

Nghiêm trọng hơn — **sai nội dung file:**
- `lib/features/presentation/screens/presentation_screen.dart` chứa class **`TemplateGalleryScreen`** (không
  phải `PresentationScreen`) → trùng lặp với `features/templates/`.
- `lib/features/ai_engine/screens/anki_deck_screen.dart` trùng class `AnkiDeckScreen` với
  `lib/features/anki/screens/anki_deck_screen.dart`.
- `lib/features/ai_engine/screens/text_to_mindmap_screen.dart` — **file 0 byte**.
- `lib/features/backupmain` — file Dart không đuôi (xem 4.2).

### 4.5 Test suite **hỏng 100%**

`test/widget_test.dart` là template counter mặc định, nhưng:
- `import 'package:vipmind_new/main.dart';` → package thật tên **`neuromindmap`** ⇒ lỗi import.
- `pumpWidget(const MyApp())` → **không có class `MyApp`** ở đâu trong repo (`main.dart` có `VipMindApp`).

→ `flutter test` fail ngay từ bước biên dịch. **Độ phủ test thực tế = 0.**

### 4.6 Assets **không được đăng ký** trong pubspec → audio crash lúc chạy

`pubspec.yaml` có toàn bộ khối `assets:` và `fonts:` **bị comment**. Nhưng `lib/core/services/audio_service.dart`
gọi `setAsset('assets/audio/click.mp3' | 'success.mp3' | 'ambient_rain|forest|cafe.mp3')` ở ~10 chỗ, và
theme dùng `google_fonts`.

→ Kho `assets/` có thật 10 file (5 audio, 2 font Inter, 2 ảnh, `default_templates.json`) nhưng **không được
đóng gói**. Mọi hiệu ứng âm thanh / haptic-audio sẽ ném exception khi chạy; template JSON cũng không đọc được.

### 4.7 Ràng buộc SDK chưa được kiểm chứng

`pubspec.lock` chốt `dart: >=3.10.3 <4.0.0`, `flutter: >=3.38.4`, trong khi `pubspec.yaml` chỉ khai báo
`sdk: '>=3.0.0 <4.0.0'`. Không có CI nào xác nhận phiên bản SDK build được ⇒ mỗi dev một kết quả.

### 4.8 Không có quy trình kỹ thuật tối thiểu

- Không workflow GitHub Actions (chỉ có `copilot-instructions.md`).
- Không PR, không issue trên GitHub (`gh issue list` / `gh pr list` = rỗng).
- Không có card nào trong Linear cho VipMind ⇒ **tiến độ hiện không được theo dõi ở đâu cả**, ngoài repo.

---

## 5. CHI TIẾT TIẾN ĐỘ THEO TÍNH NĂNG

| Tính năng | Code | Chạy được? | Ghi chú |
|---|:--:|:--:|---|
| Khởi động app + Firebase + Providers | 🟡 70% | 🔴 | Entrypoint sai chỗ (4.2), iOS thiếu plist (4.1) |
| Splash + điều hướng theo phiên đăng nhập | 🟢 90% | 🟡 | Logic `FirebaseAuth.currentUser` OK, phụ thuộc route |
| Đăng nhập / Đăng ký | 🟡 60% | 🟡 | Có UI + gọi Firebase; thiếu reset password, thiếu test luồng lỗi |
| Home (danh sách, tab, search, favorite, drawer) | 🟡 70% | 🟡 | `_toggleFavorite` bỏ trống; search gọi repository nhưng chưa kiểm chứng |
| **Editor sơ đồ tư duy** (canvas, node, connection, zoom, minimap, toolbar, panel) | 🟡 65% | 🟡 | Phần giá trị nhất; **tự viết Taylor sin/cos thay vì `dart:math`** (`mindmap_provider.dart:488–534`) → rủi ro sai số, cần thay |
| Undo / Redo + 3 auto-layout (radial/tree/org-chart) | 🟡 60% | ❓ | Đã viết, **chưa có test nào** kiểm chứng |
| Lưu Firestore (CRUD, shared, search) | 🟡 65% | ❓ | Repository đầy đủ; chưa có Firestore rules trong repo |
| AI: text → mindmap | 🔴 0% | 🔴 | File 0 byte + placeholder |
| AI: voice → mindmap | 🔴 0% | 🔴 | Placeholder; `speech_to_text` khai báo nhưng không dùng |
| AI: image → mindmap | 🔴 0% | 🔴 | Placeholder; `image_picker`/ML kit đã bị comment trong pubspec |
| Anki / Flashcard | 🔴 5% | 🔴 | Chỉ có **model** (`anki_card_model.dart`, trường Anki trong `NodeModel`) + 2 màn "Coming Soon" |
| Presentation mode | 🔴 0% | 🔴 | 2 file placeholder, 1 file sai class |
| Zen mode | 🔴 0% | 🔴 | 18 dòng chữ "Zen Mode" |
| Templates gallery | 🔴 0% | 🔴 | Asset `default_templates.json` có sẵn nhưng chưa đăng ký + chưa đọc |
| Settings | 🔴 0% | 🔴 | 12 dòng |
| Collaboration (realtime nhiều người) | 🔴 5% | 🔴 | `CollaborationProvider` chỉ là stub in-memory, **không có stream Firestore** |
| Export (PDF/PNG) & Share | 🔴 0% | 🔴 | `_showExportOptions()` / `_showShareDialog()` rỗng; `pdf`/`printing`/`screenshot`/`share_plus` không được import |
| Âm thanh / haptic | 🟡 50% | 🔴 | `HapticService` OK; `AudioService` sẽ crash vì assets (4.6) |
| Kiểm thử | 🔴 0% | 🔴 | 1 file test hỏng |
| CI/CD | 🔴 0% | 🔴 | Không có |

---

## 6. RỦI RO & NỢ KỸ THUẬT (ngoài blocker)

1. **29 package chết** trong `pubspec.yaml` → tăng thời gian build, tăng xác suất xung đột native,
   che mất phụ thuộc thật. Nên cắt còn đúng những gì dùng.
2. **Tự cài sin/cos bằng chuỗi Taylor** trong `MindmapProvider` thay vì `dart:math` → vừa chậm vừa sai số,
   ảnh hưởng trực tiếp chất lượng auto-layout (tính năng lõi).
3. **Không có Firestore security rules / `firebase.json`** trong repo → dữ liệu người dùng đang phụ thuộc
   cấu hình console thủ công, không tái lập được, không review được.
4. **`google-services.json` nằm trong git** (project `vipmind-7c4bb`) → nên xác nhận project Firebase này còn
   dùng không, và cân nhắc chuyển sang `--dart-define`/`firebase_options.dart` sinh bằng FlutterFire CLI.
5. **`usesCleartextTraffic="true"` + `requestLegacyExternalStorage="true"`** trong manifest → sẽ bị từ chối
   khi đưa lên Google Play (target API cao).
6. **`android:largeHeap="true"`** thường là dấu hiệu che vấn đề hiệu năng canvas.
7. **Tài liệu agent đang hướng dẫn sai** (`flutter run -t lib/features/backupmain`) → agent/dev mới sẽ đi lạc
   ngay bước đầu tiên.
8. **Không có `.github/workflows`** → mọi hồi quy chỉ phát hiện bằng tay.

---

## 7. KẾ HOẠCH ĐỀ XUẤT

### Giai đoạn 0 — "Làm cho nó chạy" (ưu tiên tuyệt đối, ~2–3 ngày công)
1. **Chốt một danh tính duy nhất** (đề xuất: `VipMind`, package `com.vipmind`, Dart package `vipmind`):
   sửa `pubspec.yaml`, `README.md`, `build.gradle.kts` (`namespace` + `applicationId`), `MainActivity.kt`,
   `PRODUCT_BUNDLE_IDENTIFIER` iOS, và đảm bảo `google-services.json` khớp `com.vipmind`.
2. **Xoá** `android/app/src/main/kotlin/com/vipmind/MainActivity.kt` (package sai `com.example.neuromindmap`).
3. **Biến `lib/features/backupmain` thành `lib/main.dart` thật** (gộp/ghi đè bản demo), xoá bản demo hoặc
   chuyển thành `example/` nếu muốn giữ làm tham chiếu.
4. **Bỏ comment khối `assets:` + `fonts:`** trong `pubspec.yaml`.
5. **Sinh lại cấu hình Firebase bằng FlutterFire CLI** → có `firebase_options.dart` cho cả Android + iOS,
   thêm `GoogleService-Info.plist`, gọi `Firebase.initializeApp(options: ...)` (an toàn cho cả web/desktop).
6. **Sửa `test/widget_test.dart`** (đúng package + đúng class) để `flutter test` xanh trở lại — dù chỉ 1 smoke test.
7. Chạy thật `flutter pub get && flutter analyze && flutter test` và **ghi lại kết quả** vào báo cáo kế tiếp.

### Giai đoạn 1 — "App liền mạch" (~3–5 ngày công)
8. Mở lại 9 route bị comment; **xoá toàn bộ placeholder class trong `routes.dart`** và import file thật.
9. Xoá file trùng/sai: `features/presentation/screens/presentation_screen.dart` (sai class),
   `features/ai_engine/screens/anki_deck_screen.dart` (trùng), `features/ai_engine/screens/text_to_mindmap_screen.dart` (0 byte).
10. Cắt `pubspec.yaml` còn ~12 package thực dùng (thêm lại theo từng tính năng khi thật sự cần).
11. Thay sin/cos Taylor bằng `dart:math`; viết **unit test cho 3 thuật toán layout + undo/redo**
    (đây là phần dễ test nhất và giá trị nhất).
12. Dựng **GitHub Actions tối thiểu**: `analyze` + `test` trên mọi push/PR.

### Giai đoạn 2 — "Chọn MỘT mũi nhọn" (cần quyết định của chủ dự án)
Đừng làm dàn hàng ngang 7 tính năng trống. Đề xuất thứ tự theo giá trị/người dùng:
- **Phương án A (khuyên dùng):** hoàn thiện **Editor + Templates + Export PNG/PDF** → có sản phẩm dùng được
  ngay, không phụ thuộc AI/API, `default_templates.json` đã có sẵn.
- **Phương án B:** làm **Anki/Flashcard** → model đã thiết kế xong 80%, chỉ thiếu UI + thuật toán lặp ngắt quãng.
- **Phương án C:** làm **AI text→mindmap** → hấp dẫn nhất nhưng cần chốt nhà cung cấp API, chi phí, và xử lý
  lỗi mạng; rủi ro cao nhất.

### Việc quản lý (nên làm ngay, 30 phút)
13. **Tạo project "VipMind" trong Linear** (hiện chưa có) + các card theo đúng 12 mục Giai đoạn 0/1 ở trên,
    để tiến độ được theo dõi thay vì chỉ nằm trong repo.
14. Đặt **milestone "Bản chạy được đầu tiên"** với tiêu chí nghiệm thu rõ:
    *build Android + iOS thành công · đăng nhập được · tạo/sửa/lưu được 1 sơ đồ · `flutter test` xanh.*

---

## 8. CÂU HỎI CẦN CHỦ DỰ ÁN QUYẾT ĐỊNH

1. **Tên & package chính thức** là gì: `VipMind` / `com.vipmind`, hay `NeuroMindmap`? (đang lẫn cả ba)
2. **Entrypoint chuẩn** là bản demo `main.dart` hay bản đầy đủ trong `backupmain`? (đề xuất: bản đầy đủ)
3. **Firebase project `vipmind-7c4bb`** còn dùng không? Ai giữ quyền truy cập console?
4. **Mục tiêu nền tảng**: chỉ Android, hay Android + iOS + Web? (Web hiện chưa được tính tới; `web/` chỉ là scaffold)
5. **Mũi nhọn Giai đoạn 2**: A (Editor/Templates/Export), B (Anki) hay C (AI)?
6. Có muốn **agent tạo project + card Linear và/hoặc mở PR sửa Giai đoạn 0** ngay không?

---

### Phụ lục — Bằng chứng nhanh (file:dòng)

- `lib/main.dart:1-21` — entrypoint demo, không nối app thật.
- `lib/features/backupmain:1-46` — entrypoint thật, thiếu đuôi `.dart`.
- `lib/app/routes.dart:170-215` — 9 route nằm trong `/* ... */`, `default` trả `HomeScreen`.
- `android/app/build.gradle.kts:8,20` — `namespace`/`applicationId` = `com.example.vipmind_new`.
- `android/app/google-services.json:12` — `package_name` = `com.vipmind`; dòng 4 `project_id` = `vipmind-7c4bb`.
- `android/app/src/main/kotlin/com/vipmind/MainActivity.kt:1` — `package com.example.neuromindmap`.
- `ios/Runner/AppDelegate.swift` — bản mặc định, không `FirebaseApp.configure()`; không có `GoogleService-Info.plist`.
- `pubspec.yaml:73-90` — khối `assets:`/`fonts:` bị comment.
- `lib/core/services/audio_service.dart:11-78` — 10 lần `setAsset('assets/audio/...')`.
- `test/widget_test.dart:12,17` — `package:vipmind_new/main.dart`, `const MyApp()`.
- `lib/data/providers/mindmap_provider.dart:488-534` — `_cos/_sin/_taylorCos/_taylorSin`.
- `lib/features/mindmap/screens/mindmap_editor_screen.dart:683-708` — 5 `TODO` (AI, voice, image, share, export).
- `lib/features/presentation/screens/presentation_screen.dart:3` — khai báo `class TemplateGalleryScreen`.
- `.github/` — chỉ có `copilot-instructions.md`; không có `workflows/`.
- Git: `git log --all --oneline` → 1 commit `b79f138` (28/01/2026). GitHub API `pushedAt` = 18/02/2026.
- Linear: không có project/issue nào khớp "vipmind" hoặc "mindmap".

---

## HẬU KỲ (23/10/2026) — Phase 0 + Phase 1 đã thực thi và **đã được compiler xác nhận**

Phần trên là báo cáo khảo sát. Phần này ghi lại kết quả sau khi làm thật.

### Trạng thái CI (bằng chứng, không phải suy đoán)

| Bước | Kết quả |
|---|---|
| `flutter pub get` | ✅ resolve sạch với 10 package runtime |
| `flutter analyze` | ✅ **"No issues found!"** — 0 error / 0 warning / 0 info |
| `flutter test` | ✅ **"All tests passed!" — 108 test** (từ 1 file test hỏng ban đầu) |
| `dart format --set-exit-if-changed` | ⚠️ đỏ (đang để `continue-on-error`) → card IN4-131 |
| Build APK / chạy máy thật | ⏳ chưa — cần Android SDK + thiết bị (IN4-130) |

PR: https://github.com/Pabhassaracitto/vipmind/pull/1 ·
Mỗi lần CI chạy đều **tự đăng comment** lên PR với toàn bộ lỗi (`.github/workflows/ci.yml`,
bước "Report results on the PR"). Lý do: log thô và artifact của GitHub Actions nằm ở
blob host không đọc được từ môi trường agent, còn API annotation thì **giới hạn 10 dòng**.

### 4 bug THẬT mà chỉ compiler/test mới lộ ra (không có trong khảo sát ban đầu)

1. **`MindmapModel.removeNode()` ném `ConcurrentModificationError`** — hàm lặp qua
   `node.childrenIds` trong khi lời gọi đệ quy xoá phần tử khỏi chính list đó
   (`parent.childrenIds.remove(nodeId)`). Nghĩa là **bấm xoá một node có con là crash app**.
   Test `removeNode also removes descendants` bắt được; diagnostic in ra
   `REMOVENODE before:` mà không có `after:` → xác định được chỗ ném.
2. **`firestoreDate(millis)` trả DateTime local** trong khi các nhánh khác trả UTC →
   cùng một thời điểm nhưng so sánh không bằng nhau trên máy không ở múi giờ UTC.
   Đã chuẩn hoá **mọi nhánh về UTC**.
3. **Nút "Save" trong dialog đổi tên map là code chết** — `final updated = mindmap.copyWith(...)`
   rồi `context.read<MindmapProvider>().updateNode;` (tham chiếu hàm, **không gọi**).
   Đã thêm `MindmapProvider.renameTitle()` dùng `MindmapRepository.updateTitle()` có sẵn.
4. **`case AppRoutes.settings:` không compile** (constant pattern không được là
   prefixed identifier). Đổi tên tham số thành `routeSettings` thì `case settings:`
   lại biến thành **variable pattern** — nó *bind* thay vì so sánh, nên sẽ nuốt mọi
   route còn lại (mọi route lạ đều mở Settings). Đã đổi hằng thành
   `AppRoutes.settingsRoute`.

Ngoài ra: `Color.value` deprecated → `toARGB32()`; `WidgetsBinding.instance.window`
deprecated → `PlatformDispatcher.instance.views.first`; `AppFonts.textTheme()` phải
set `fontFamily` **từng slot** vì `TextTheme().apply(fontFamily:)` bỏ qua slot null
(nên font Inter bundled trước đó không hề được áp dụng).

### Hai bài học về test (đã ghi vào `docs/AGENT_NOTES.md`)

* `MaterialApp(initialRoute: '/anki')` **không chỉ** dựng `/anki`: Flutter tách route
  sâu thành từng đoạn và dựng cả route `/` — ở app này là SplashScreen, và timer 3s
  của nó làm test fail với "A Timer is still pending". Test phải pump với `home:` rồi
  điều hướng bằng `Navigator.pushNamed`.
* `Timestamp.toDate()` trả DateTime **múi giờ local** cho cùng một thời điểm, và
  so sánh DateTime của Dart nhạy với múi giờ → test phải so `millisecondsSinceEpoch`.

### Việc còn lại (không đổi so với kế hoạch)

IN4-130 build APK + nghiệm thu trên máy thật · IN4-131 `dart format` + bật blocking ·
IN4-126/132/133/134 Firebase iOS + rules/indexes + Email-Password ·
IN4-127 chọn mũi nhọn A/B/C · IN4-128 sẵn sàng phát hành.
