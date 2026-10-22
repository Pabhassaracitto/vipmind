# PROMPT GIAO VIỆC — VipMind

Bốn prompt dưới đây **tự chứa** (self-contained): copy nguyên khối gửi cho một
agent Arena mới là agent đó đủ bối cảnh để làm, không cần đọc lại cuộc trò chuyện
này. Mỗi prompt tương ứng một card Linear.

| # | Prompt | Card | Cần gì ngoài agent |
|---|---|---|---|
| 1 | **Kiểm chứng bằng SDK thật** ← làm trước tiên | [IN4-125](https://linear.app/in4up/issue/IN4-125) / IN4-129, 130, 131 | Máy có Flutter SDK + Android SDK |
| 2 | Firebase iOS + rules + index | [IN4-126](https://linear.app/in4up/issue/IN4-126) / IN4-132, 133, 134 | Quyền Firebase console, máy Mac (để build iOS) |
| 3 | Anki/Flashcard UI *(mũi nhọn B — không cần quyết định bên ngoài)* | [IN4-136](https://linear.app/in4up/issue/IN4-136) | Không |
| 4 | Export PNG/PDF + Share *(mũi nhọn A — cần chủ dự án duyệt)* | [IN4-135](https://linear.app/in4up/issue/IN4-135) | Quyết định của chủ dự án |

> **Cập nhật 23/10/2026 — prompt 1 đã chạy xong một phần, trên CI thật:**
> `flutter pub get` ✅ · `flutter analyze` ✅ **No issues found!** · `flutter test` ✅
> **All tests passed (108)**. Run:
> <https://github.com/Pabhassaracitto/vipmind/actions/runs/39871205285> ·
> PR: <https://github.com/Pabhassaracitto/vipmind/pull/1>
>
> Phần **chưa** làm được vì cần thứ CI không có: `flutter build apk`, nghiệm thu
> trên thiết bị, `dart format .`, và commit `pubspec.lock` (CI đã sinh ra nó và để
> trong artifact `analyze-test-output`). Đó là nội dung prompt 1 bên dưới.
>
> Ba prompt sau chỉ nên giao khi prompt 1 xong hẳn: test xanh mới chứng minh được
> tầng logic, chưa chứng minh được app chạy trên máy thật.

---

## PROMPT 1 — VM-P0: kiểm chứng bằng Flutter SDK thật (IN4-125)

```
BẠN LÀM GÌ: kiểm chứng và làm xanh một nhánh Flutter vừa được viết lại toàn bộ
bởi một agent KHÔNG CÓ Flutter/Dart SDK trong môi trường của nó.

REPO: Pabhassaracitto/vipmind · NHÁNH: arena/39395bf9-vipmind · COMMIT: a56c7f7

BỐI CẢNH (đọc trong repo, đừng hỏi lại):
- docs/AGENT_NOTES.md            → quy tắc bắt buộc, §8 là "định nghĩa xong", §9 là những gì CHƯA làm
- docs/bao-cao-tien-do-2026-10-22.md → khảo sát gốc, có bằng chứng file:dòng cho từng lỗi
- docs/SETUP_FIREBASE.md          → trạng thái Firebase từng nền tảng
- .github/copilot-instructions.md → bản đồ repo rút gọn

TRẠNG THÁI: app là mindmap editor Flutter + Firebase (Auth + Firestore).
Đã sửa: thống nhất danh tính (VipMind / package `vipmind` / app id `com.vipmind`),
apply plugin com.google.gms.google-services, gộp entrypoint về lib/main.dart,
mở lại 15 route, vá 7 model để đọc đúng kiểu Firestore (Timestamp/int/double/List),
tách MindmapLayoutEngine thuần, cắt 29 package không dùng, đăng ký assets+fonts,
thêm 8 file test, thêm CI analyze+test.
CHƯA AI CHẠY: flutter pub get / analyze / test / build. pubspec.lock đã bị XOÁ
có chủ đích vì không resolve được với bộ dependency mới.

ĐÃ XONG TRÊN CI (đừng làm lại, chỉ xác nhận trên máy dev):
- `flutter pub get` resolve sạch với 10 package runtime.
- `flutter analyze` → "No issues found!" (0 error / 0 warning / 0 info).
- `flutter test` → "All tests passed!" (108 test).
CI tự đăng toàn bộ kết quả thành comment trên PR #1 mỗi lần chạy.

VIỆC CÒN LẠI, theo thứ tự, mỗi bước dán output thật vào báo cáo:
1. `flutter --version` — ghi lại và đối chiếu với pin `3.35.0` trong
   `.github/workflows/ci.yml`. Nếu máy dev khác bản đó thì nói rõ: kết quả
   `dart format` phụ thuộc phiên bản Dart, lệch nhau là CI đỏ.
2. `flutter pub get` rồi **commit `pubspec.lock`** (repo đang không có lockfile;
   CI sinh ra nó và để trong artifact `analyze-test-output`).
3. `flutter analyze` + `flutter test` — xác nhận xanh trên máy dev, không chỉ trên CI.
4. `dart format .` → commit → bỏ `continue-on-error: true` ở bước
   *Formatting check* trong `.github/workflows/ci.yml` (card IN4-131).
5. `flutter build apk --debug` — phép thử thật cho applicationId `com.vipmind`
   khớp `package_name` trong google-services.json, và cho plugin google-services.
   Nếu fail vì google-services: KHÔNG xoá plugin, hãy đối chiếu lại applicationId.
6. Chạy trên máy/emulator và đi hết luồng trong checklist của card IN4-130.
   Ba mục quan trọng nhất, đều là bug vừa sửa và CHỈ kiểm chứng được trên máy thật:
   - tạo mindmap → thoát app → mở lại → **map mở được**
     (bug `FieldValue.serverTimestamp()` / `DateTime.parse()`: trước khi sửa thì
     mọi map đã lưu đều mất trắng);
   - **xoá một node CÓ node con** (trước commit `485b928` là
     `ConcurrentModificationError` → crash);
   - **đổi tên mindmap rồi bấm Save** (trước đây nút Save là code chết).

NẾU CÓ TEST ĐỎ (tham khảo, CI đang xanh):
   - Test sai thật (assert sai giá trị mong đợi) → sửa test, giải thích tại sao.
   - Code sai → sửa code. KHÔNG được xoá test hay nới assertion cho dễ qua.
   - `test/models_firestore_types_test.dart` dùng `Timestamp.fromDate()` của
     cloud_firestore trên VM thuần; nếu nó cần native library thì thay fixture đó
     bằng ISO string/millis và ghi chú lại (các nhánh khác của converter vẫn phải
     được test).
HAI CÁI BẪY FLUTTER TEST ĐÃ TỐN NHIỀU VÒNG CI (đã ghi trong docs/AGENT_NOTES.md):
- `MaterialApp(initialRoute: '/anki')` KHÔNG CHỈ dựng `/anki`: Flutter tách route
  sâu thành từng đoạn và dựng cả route `/` — ở app này là SplashScreen, và timer
  3 giây của nó làm test fail với "A Timer is still pending even after the widget
  tree was disposed". Test phải pump với `home:` rồi điều hướng bằng
  `Navigator.pushNamed`.
- `Timestamp.toDate()` trả DateTime **múi giờ local** cho cùng một thời điểm, và
  so sánh DateTime của Dart nhạy với múi giờ. Test phải so
  `millisecondsSinceEpoch`. `firestoreDate()` nay chuẩn hoá mọi nhánh về UTC.

RÀNG BUỘC CỨNG:
- Không đổi danh tính (tên/package id) — vừa mất công thống nhất.
- Không thêm state framework thứ hai (đang là provider + ChangeNotifier).
- Không gọi thẳng FirebaseAuth.instance / FirebaseFirestore.instance trong
  build() hay initState() — phải qua FirebaseService (null-safe) và repository
  (resolve lazy). Đó là lỗi làm sập 5 màn hình trước đây.
- Model mới/sửa model: bắt buộc có test fromJson với dữ liệu DẠNG FIRESTORE
  (int thay vì double, Timestamp thay vì String, List<dynamic>).
- Mỗi package thêm vào phải được import trong CÙNG commit đó.
- Màn hình mới phải đăng ký trong AppRoutes.generateRoute (test/routes_test.dart
  sẽ fail nếu thiếu).

BÁO CÁO LẠI (dán vào comment của IN4-125):
- flutter --version
- output `flutter analyze` (số error/warning/info còn lại)
- output `flutter test` (số test pass)
- kết quả `flutter build apk --debug`
- checklist IN4-130: mục nào đạt, mục nào KHÔNG đạt + logcat
- danh sách file đã phải sửa để đạt được điều trên, và LÝ DO từng sửa đổi
- những gì bạn nghi ngờ nhưng chưa kiểm chứng được
```

---

## PROMPT 2 — VM-P1: Firebase iOS + rules + index (IN4-126)

```
BẠN LÀM GÌ: hoàn tất cấu hình Firebase cho VipMind — phần iOS đang thiếu, và
Firestore rules/indexes chưa được deploy.

REPO: Pabhassaracitto/vipmind · NHÁNH: arena/39395bf9-vipmind
ĐỌC TRƯỚC: docs/SETUP_FIREBASE.md (đã viết sẵn từng bước), docs/AGENT_NOTES.md §7

TRẠNG THÁI:
- Android: google-services.json (project vipmind-7c4bb, package com.vipmind) đã có,
  plugin com.google.gms.google-services đã apply → Android chạy được.
- iOS: KHÔNG có ios/Runner/GoogleService-Info.plist. AppDelegate.swift đã gọi
  FirebaseApp.configure() sau guard `FirebaseApp.app() == nil` nên không crash,
  chỉ log cảnh báo. lib/main.dart bắt lỗi Firebase.initializeApp() và chạy tiếp
  với cloud tắt.
- Firestore: repo đã có firestore.rules + firestore.indexes.json nhưng CHƯA deploy.
  MindmapRepository.getMindmaps() chạy where('ownerId').orderBy('updatedAt', desc)
  → KHÔNG có composite index thì lần load đầu fail với `failed-precondition`.
- lib/firebase_options.dart đang nằm trong .gitignore.

VIỆC:
1. Xác nhận với chủ dự án: Firebase project `vipmind-7c4bb` còn dùng không, ai
   giữ quyền console. Nếu bỏ → tạo project mới và thay google-services.json.
2. `dart pub global activate flutterfire_cli`
   `flutterfire configure --project=vipmind-7c4bb --platforms=android,ios`
3. Thêm GoogleService-Info.plist vào target Runner của ios/Runner.xcodeproj
   (PBXFileReference + PBXBuildFile + Resources build phase nếu sửa tay).
4. Bật phần đã để sẵn dạng COMMENT trong lib/main.dart:
   import 'firebase_options.dart';
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
5. Console → Authentication → Sign-in method → Email/Password → Enable.
6. Tạo firebase.json trỏ tới firestore.rules + firestore.indexes.json, rồi
   `firebase deploy --only firestore:rules,firestore:indexes`.
7. Thêm luồng "Quên mật khẩu" vào login_screen.dart —
   FirebaseService.resetPassword(email) ĐÃ VIẾT SẴN nhưng không có UI nào gọi.
8. Nếu có máy Mac: `flutter build ios --debug --no-codesign`.

RÀNG BUỘC CỨNG:
- firestore.rules viết cho collection `mindmaps` CẤP GỐC (đúng cái repository
  đang dùng). FirebaseService.userMindmaps(userId) là helper subcollection
  KHÔNG AI GỌI — đừng sửa rules theo nó trước khi chốt shape dữ liệu.
- Không hardcode Firebase config vào Dart ngoài file sinh bằng CLI.
- Không bỏ guard try/catch quanh Firebase.initializeApp() trong main.dart:
  nó là thứ giúp app vẫn khởi động được khi thiếu cấu hình.

NGHIỆM THU:
- iOS đăng nhập/đăng ký được; log không còn "[VipMind] GoogleService-Info.plist missing"
- Tạo map → kill app → mở lại → map còn đó (cả Android lẫn iOS)
- Load danh sách map KHÔNG báo failed-precondition (index đã Enabled)
- Thử 2 tài khoản: A không đọc được map của B
- Bấm "Quên mật khẩu" → nhận email → đổi được → login lại được
```

---

## PROMPT 3 — VM-P2.B: Anki/Flashcard UI (IN4-136)

```
BẠN LÀM GÌ: xây UI flashcard cho VipMind. Phần logic khó nhất ĐÃ XONG VÀ ĐÃ CÓ
TEST — bạn chỉ làm UI và nối dữ liệu.

REPO: Pabhassaracitto/vipmind · NHÁNH: arena/39395bf9-vipmind
ĐỌC TRƯỚC: docs/AGENT_NOTES.md (toàn bộ), rồi 4 file liệt kê dưới đây.

ĐÃ CÓ SẴN — KHÔNG VIẾT LẠI:
- lib/data/models/anki_card_model.dart → `review(int quality)` là SM-2 hoàn chỉnh
  (quality 0-2 = fail reset về interval 1; 3-5 = pass; repetitions 0→1 ngày,
  1→6 ngày, sau đó interval = round(interval * easeFactor); ease floor 1.3;
  nextReview = now + interval ngày). `isDue` trả true khi nextReview null.
- test/anki_sm2_test.dart → 10 test đang pin đúng hành vi trên.
- lib/data/models/node_model.dart → node đã có isAnkiCard, ankiFront, ankiBack,
  ankiInterval, ankiNextReview, và toJson/fromJson đã đọc được chúng.
- lib/app/routes.dart → AppRoutes.ankiDeck và AppRoutes.flashcardReview đã trỏ
  đúng màn, nhận arguments {'deckId': id}.
- lib/core/widgets/coming_soon.dart → hai màn đang là ComingSoonScreen; bạn thay
  bằng màn thật.
- lib/data/providers/mindmap_provider.dart → createMindmapFromModel(model),
  loadMindmap(id), currentMindmap, saveMindmap().

VIỆC:
1. node_editor_panel.dart: thêm công tắc "Biến node thành flashcard" + 2 ô
   Front/Back (mặc định Front = node.text, Back = node.description). Ghi qua
   MindmapProvider.updateNode(...) rồi saveMindmap().
2. AnkiDeckScreen: danh sách deck = danh sách mindmap của user (FirebaseService.currentUser
   → provider.loadMindmaps). Mỗi deck hiện: tên map, tổng số card (node có
   isAnkiCard), số card đến hạn (dựng AnkiCardModel từ node rồi đọc isDue).
   Tap → pushNamed(AppRoutes.flashcardReview, {'deckId': mindmapId}).
3. FlashcardReviewScreen: load mindmap theo deckId → lọc node isAnkiCard →
   hàng đợi card đến hạn trước, card mới sau. UI: mặt trước → tap lật →
   4 nút Again/Hard/Good/Easy (map sang quality 1/3/4/5) → card.review(quality) →
   GHI NGƯỢC ankiInterval + ankiNextReview vào node (đừng để mất tiến độ) →
   card tiếp → màn tổng kết (đã ôn, đúng, sai, lần tới).
4. Lưu: provider.saveMindmap() sau mỗi lần chấm (hoặc debounce 2s —
   MindmapController đã có mẫu debounce).

RÀNG BUỘC CỨNG:
- KHÔNG sửa AnkiCardModel.review(). Nếu muốn đổi thuật toán → mở card riêng,
  và sửa test trước, giải thích tại sao.
- Không tạo Firestore collection mới nếu chưa thật cần: card đang sống TRONG
  node. Nếu bạn quyết định tách ra collection riêng, phải nói rõ lý do + viết
  migration + sửa firestore.rules.
- Đọc dữ liệu Firestore qua core/utils/firestore_converters.dart (Timestamp/int/
  double/List) — không cast thô.
- Đọc user qua FirebaseService.currentUser (null-safe), không gọi
  FirebaseAuth.instance trong build()/initState().
- Màn mới phải đăng ký trong AppRoutes.generateRoute (đã có sẵn 2 route này).
- Thêm test: (a) dựng hàng đợi review từ một mindmap có node isAnkiCard,
  (b) map 4 nút → quality, (c) ghi ngược interval/nextReview vào node.
  Test phải chạy KHÔNG cần Firebase.

NGHIỆM THU:
- Đánh dấu 1 node là flashcard trong editor → thấy nó trong deck
- Review: lật thẻ, chấm, số card đến hạn giảm dần
- Kill app → mở lại → lịch review vẫn đúng
- `flutter test` xanh, `flutter analyze` sạch
```

---

## PROMPT 4 — VM-P2.A: Export PNG/PDF + Share (IN4-135)

> ⚠️ Chỉ giao sau khi chủ dự án chọn phương án A trong IN4-127.

```
BẠN LÀM GÌ: nối 2 hàm đang RỖNG trong editor thành tính năng export + share thật.

REPO: Pabhassaracitto/vipmind · NHÁNH: arena/39395bf9-vipmind
ĐỌC TRƯỚC: docs/AGENT_NOTES.md §5 (styling), §6 (dependencies), §8 (definition of done)

ĐIỂM BẮT ĐẦU:
lib/features/mindmap/screens/mindmap_editor_screen.dart đang có:
    void _showShareDialog()  { /* TODO: Implement share */ }
    void _showExportOptions(){ /* TODO: Implement export */ }
Cả hai đã được gọi từ menu của editor — chỉ thiếu thân hàm.

ĐÃ CÓ SẲN ĐỂ TÁI SỬ DỤNG:
- MindmapCanvas (render map) và ConnectionPainter (vẽ đường nối) — export phải
  render RIÊNG canvas, KHÔNG chụp cả màn hình (sẽ dính toolbar + minimap + FAB).
- MinimapWidget._calculateBounds() có sẵn logic tính bounding box của các node —
  tham khảo để crop ảnh export.
- _Outline trong lib/features/mindmap/screens/mindmap_preview_screen.dart render
  outline dạng cây thụt đầu dòng — tái sử dụng cho trang 2 của PDF.
- MindmapModel/NodeModel đã có toJson; màu node là Color ARGB.

PACKAGE CẦN THÊM LẠI (đã bị cắt vì không ai dùng — thêm trong CÙNG commit dùng nó):
screenshot (hoặc RepaintBoundary + toImage), pdf, printing, share_plus.
path_provider nếu cần ghi file tạm.

VIỆC:
1. Export PNG: render canvas offscreen theo bounding box + padding, scale 2-3x
   để chữ đọc được, nền theo theme (hoặc trắng cố định — quyết định và ghi rõ).
2. Export PDF: trang 1 = ảnh map (vừa trang, giữ tỉ lệ); trang 2+ = outline
   (tiêu đề, mô tả, cây node). Dùng package pdf, xem trước/in bằng printing.
3. Share: share_plus với file vừa tạo + tiêu đề map.
4. UI: bottom sheet chọn PNG / PDF, có progress, báo lỗi rõ khi thất bại
   (không để người dùng nhìn chuỗi exception thô).

RÀNG BUỘC CỨNG:
- Không export bằng cách chụp cả Scaffold.
- File tạm phải xoá sau khi share (đừng rò rỉ bộ nhớ).
- Thêm test cho phần PURE: dựng cấu trúc outline từ MindmapModel, tính bounding
  box, chọn scale. Phần cần rendering thật thì nghiệm thu bằng tay và ghi lại.
- Package mới → import trong cùng commit (quy tắc §6).

NGHIỆM THU:
- Export PNG: ảnh đúng nội dung, chữ đọc được, không cắt mất node nào,
  không dính toolbar/minimap
- Export PDF: mở được, ảnh + outline đúng thứ tự
- Share: mở sheet của OS, gửi được qua 1 app thật
- `flutter analyze` sạch, `flutter test` xanh
```

---

## Ghi chú cho người điều phối

* **Một agent = một prompt.** Đừng gộp prompt 1 với prompt 3: prompt 1 có thể
  phải sửa rất nhiều lỗi compile, còn prompt 3 cần một nền đã xanh.
* **Yêu cầu agent dán output thật.** Cả 4 prompt đều bắt buộc dán
  `flutter --version` / `analyze` / `test` vào báo cáo. Nếu agent nói "đã xong"
  mà không có output, coi như chưa làm.
* **Sau prompt 1**, gửi lại cho tôi (agent đang giữ nhánh này) output CI + danh
  sách lỗi còn lại, tôi sẽ tổng hợp và quyết định bước kế tiếp.
* Card IN4-127 đang chờ **quyết định của chủ dự án**: A / B / C. Nếu chưa muốn
  quyết, làm prompt 3 (Anki) là an toàn nhất vì không phụ thuộc bên ngoài và
  engine đã có test.
