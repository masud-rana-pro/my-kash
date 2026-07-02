# Step 02: Flutter App Skeleton

## 1. Step title

Step 02: SmartKash Flutter app skeleton তৈরি। এই step-এ শুরুতে Android-focused skeleton ছিল; Step 06b-এ project full cross-platform Flutter structure-এ normalize করা হয়েছে।

## 2. কী implement করা হয়েছে

এই step-এ `apps/mobile/` folder-এর ভিতরে SmartKash Flutter skeleton তৈরি করা হয়েছে। App name রাখা হয়েছে `SmartKash`, Flutter package/project name রাখা হয়েছে `smartkash`, এবং Android application ID রাখা হয়েছে `com.imran.smartkash`।

এই step-এ তৈরি হয়েছে:

- Flutter `pubspec.yaml`
- Flutter lint config `analysis_options.yaml`
- `lib/main.dart`
- `SmartKashApp` root widget
- `go_router` ভিত্তিক base router
- base Material 3 theme
- app config file
- placeholder home screen
- feature-first folder structure
- Android package/application ID skeleton
- widget test

এই step-এ তৈরি হয়নি:

- Firebase Auth
- wallet feature
- transaction feature
- API integration
- QR scan logic
- real login screen
- real business feature
- backend integration

Flutter generator command চেষ্টা করা হয়েছিল:

```powershell
flutter create --org com.imran --project-name smartkash --platforms=android .
```

Sandboxed execution-এ command timeout করায় generated files পাওয়া যায়নি। তাই Step 02 scope বজায় রেখে minimal Flutter skeleton manually তৈরি করা হয়েছে এবং পরে `flutter pub get`, `flutter analyze`, `flutter test` দিয়ে verify করা হয়েছে।

## 3. কেন এই step দরকার

SmartKash-এর mobile app future-এ অনেক feature রাখবে: Auth, Home, Wallet, Add Money, Send Money, Payment, Transactions, Savings, Loan, Recharge, Notification, Profile, QR। তাই শুরুতেই Flutter app skeleton এবং feature-first structure তৈরি করা দরকার।

এই structure future implementation সহজ করবে:

- Riverpod দিয়ে state management হবে।
- `go_router` দিয়ে route management হবে।
- UI widgets clean থাকবে।
- API call widgets-এর ভিতরে না গিয়ে future repository/service layer-এ যাবে।
- QR scan logic future `features/qr/` module-এ থাকবে।
- Firebase Auth future `features/auth/` বা core service layer-এ থাকবে।

## 4. Final folder structure

```text
apps/mobile/
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/com/imran/smartkash/MainActivity.kt
│   │       └── res/values/styles.xml
│   ├── build.gradle
│   └── settings.gradle
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── smartkash_app.dart
│   │   ├── config/app_config.dart
│   │   ├── router/app_router.dart
│   │   └── theme/app_theme.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── network/
│   │   ├── security/
│   │   ├── storage/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── wallet/
│   │   ├── add_money/
│   │   ├── send_money/
│   │   ├── payment/
│   │   ├── transactions/
│   │   ├── savings/
│   │   ├── loan/
│   │   ├── recharge/
│   │   ├── notification/
│   │   ├── profile/
│   │   └── qr/
│   └── shared/
│       ├── models/
│       ├── services/
│       └── widgets/
├── test/widget_test.dart
├── analysis_options.yaml
├── pubspec.lock
└── pubspec.yaml
```

## 5. Files/folders created or changed

Created:

- `apps/mobile/pubspec.yaml`
- `apps/mobile/pubspec.lock`
- `apps/mobile/analysis_options.yaml`
- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/app/smartkash_app.dart`
- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/app/theme/app_theme.dart`
- `apps/mobile/lib/app/config/app_config.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `apps/mobile/test/widget_test.dart`
- `apps/mobile/android/settings.gradle`
- `apps/mobile/android/build.gradle`
- `apps/mobile/android/app/build.gradle`
- `apps/mobile/android/app/src/main/AndroidManifest.xml`
- `apps/mobile/android/app/src/main/kotlin/com/imran/smartkash/MainActivity.kt`
- `apps/mobile/android/app/src/main/res/values/styles.xml`
- feature-first placeholder folders with `.gitkeep`

Changed:

- `docs/codex-progress.md`

Removed:

- `apps/mobile/.gitkeep`, because the folder now has real project files.

## 6. Important code/config snippets

### Flutter dependencies in `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.7
```

### App boot in `lib/main.dart`

```dart
void main() {
  runApp(const ProviderScope(child: SmartKashApp()));
}
```

### Root widget in `smartkash_app.dart`

```dart
return MaterialApp.router(
  title: 'SmartKash',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  routerConfig: appRouter,
);
```

### Router in `app_router.dart`

```dart
final GoRouter appRouter = GoRouter(
  initialLocation: HomeScreen.routePath,
  routes: [
    GoRoute(
      path: HomeScreen.routePath,
      name: HomeScreen.routeName,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
```

### Theme in `app_theme.dart`

```dart
final colorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFE2136E),
  brightness: Brightness.light,
);
```

### App config in `app_config.dart`

```dart
static const appName = 'SmartKash';
static const packageName = 'com.imran.smartkash';
```

### Android application ID in `android/app/build.gradle`

```gradle
id 'dev.flutter.flutter-gradle-plugin'

namespace 'com.imran.smartkash'

defaultConfig {
    applicationId 'com.imran.smartkash'
}
```

### Flutter creation command

```powershell
flutter create --org com.imran --project-name smartkash --platforms=android .
```

## 7. Line-by-line বা block-by-block Bangla explanation

### `pubspec.yaml` dependencies

```yaml
flutter:
  sdk: flutter
```

এটা Flutter SDK dependency। Flutter widget, Material UI, test integration এগুলো ব্যবহার করতে লাগে।

```yaml
flutter_riverpod: ^2.5.1
```

এটা Riverpod dependency। SmartKash app-এ future auth state, wallet state, transaction list, loading/error state manage করার জন্য Riverpod ব্যবহার হবে।

```yaml
go_router: ^14.2.7
```

এটা routing dependency। Future login, home, send money, payment, transaction receipt screen ইত্যাদিতে clean navigation করতে `go_router` ব্যবহার হবে।

### Flutter creation command explanation

```powershell
flutter create
```

নতুন Flutter project template তৈরি করার command।

```powershell
--org com.imran
```

Android package/application ID-এর base organization set করে। Project name `smartkash` হওয়ায় expected package ID হয় `com.imran.smartkash`।

```powershell
--project-name smartkash
```

Flutter/Dart package name set করে। Dart package name lowercase হতে হয়, তাই `SmartKash` নয়, `smartkash` ব্যবহার করা হয়েছে।

```powershell
--platforms=android
```

এই step-এ শুধু Android platform skeleton generate করা হয়েছিল। Step 06b থেকে SmartKash Android, iOS, Web, Windows, Linux, এবং macOS support করার জন্য cross-platform structure পেয়েছে।

```powershell
.
```

Current folder অর্থাৎ `apps/mobile/`-এর ভিতর project তৈরি করতে বলা হয়। ভুল folder থেকে command চালালে project ভুল জায়গায় তৈরি হয়ে যাবে।

### `main.dart`

```dart
void main() {
```

Flutter app এখান থেকে শুরু হয়।

```dart
runApp(const ProviderScope(child: SmartKashApp()));
```

`ProviderScope` Riverpod provider system চালু করে। `SmartKashApp` পুরো app-এর root widget। Future providers এই scope-এর ভিতরে কাজ করবে।

### `MaterialApp.router`

```dart
title: 'SmartKash',
```

App-এর display/debug title।

```dart
debugShowCheckedModeBanner: false,
```

Debug banner hide করে, যাতে placeholder UI clean দেখায়।

```dart
theme: AppTheme.light,
```

Central theme file থেকে app theme নেয়।

```dart
routerConfig: appRouter,
```

Route management `app_router.dart` থেকে নেয়। এতে route config root widget-এ গুলিয়ে যায় না।

### `app_router.dart`

```dart
initialLocation: HomeScreen.routePath,
```

App প্রথমে home route `/` খুলবে।

```dart
GoRoute(...)
```

একটি route define করা হয়েছে। এখন শুধু placeholder home আছে; future step-এ auth/payment/send money route যোগ হবে।

### `app_theme.dart`

```dart
ColorScheme.fromSeed(...)
```

একটি seed color থেকে Material 3 color scheme তৈরি করে। SmartKash-এর primary visual tone এখান থেকে control হবে।

### `app_config.dart`

```dart
static const appName = 'SmartKash';
```

App name এক জায়গায় রাখা হয়েছে, যাতে UI বা config-এ বারবার hardcode করতে না হয়।

```dart
static const packageName = 'com.imran.smartkash';
```

Android package/application ID reference হিসেবে রাখা হয়েছে।

### Android config

```gradle
id 'dev.flutter.flutter-gradle-plugin'
```

এই plugin Android Gradle project-কে Flutter project-এর সাথে connect করে। Future `flutter build apk` বা Android run করার সময় Flutter assets/code build process-এ যুক্ত হবে।

```gradle
namespace 'com.imran.smartkash'
applicationId 'com.imran.smartkash'
```

Android app-এর unique identifier। Play Store বা Android install identity future-এ এই ID দিয়ে চিনবে।

## 8. SmartKash flow-তে এই step কীভাবে connect করে

এই skeleton future SmartKash app flow-এর mobile foundation:

1. User app খুলবে `main.dart` থেকে।
2. `ProviderScope` future auth/wallet state manage করবে।
3. `SmartKashApp` app theme ও router connect করবে।
4. `go_router` future login, home, send money, QR, payment, savings route manage করবে।
5. `features/` folder future feature module রাখবে।
6. `core/network` future Spring Boot API client রাখবে।
7. `core/storage` future JWT/token secure storage abstraction রাখবে।
8. `core/security` future PIN/security helper রাখবে।
9. `features/qr` future QR receiver selection logic রাখবে।
10. `features/home` এখন placeholder home দেখাচ্ছে।

## 9. Common mistakes and cautions

- ভুল path-এ Flutter app create করলে repo structure নষ্ট হয়। App অবশ্যই `apps/mobile/`-এ থাকবে।
- Package/application ID ভুল হলে Android app future-এ mismatch হবে। এখানে `com.imran.smartkash` রাখা হয়েছে।
- `google-services.json` এখন add করা হয়নি, কারণ Firebase Auth/FCM setup এই step-এর scope নয়।
- Flutter build output `build/` commit করা যাবে না।
- `.dart_tool/` commit করা যাবে না।
- `GeneratedPluginRegistrant.java` Flutter tool generate করতে পারে; এটি manually edit বা commit করা যাবে না।
- API call widget-এর ভিতরে লেখা যাবে না; future repository/service layer ব্যবহার করতে হবে।
- PIN Flutter app-এ store করা যাবে না।
- Riverpod ছাড়া local mutable global state দিয়ে auth/wallet state manage করা যাবে না।
- `flutter create` sandbox-এ timeout করেছিল, তাই skeleton manually তৈরি হয়েছে; future full platform files দরকার হলে focused step-এ generator rerun বা adjust করা যাবে।
- Android SDK missing বা `ANDROID_HOME` ভুল হলে future Android build/run fail করতে পারে। এই step-এ `flutter analyze` এবং `flutter test` pass করেছে, কিন্তু Android device build আলাদা future verification হতে পারে।
- `local.properties` commit করা যাবে না, কারণ সেখানে local Flutter/Android SDK path থাকে।

## 10. কীভাবে test বা verify করতে হবে

Commands:

```powershell
flutter pub get
```

Dependencies resolve করে এবং `pubspec.lock` তৈরি/updated করে।

```powershell
flutter analyze
```

Dart/Flutter static analysis চালায়। এই step-এ result ছিল: `No issues found!`

```powershell
flutter test
```

Widget test চালায়। এই step-এ placeholder home screen boot test pass করেছে।

```powershell
git status --short
```

কোন files changed আছে দেখা যায়।

```powershell
rg "com.imran.smartkash|flutter_riverpod|go_router|SmartKash" apps/mobile
```

App name, package ID, Riverpod, router references আছে কিনা verify করা যায়।

## 11. Git commands used in this step

```powershell
git status --short
git add apps/mobile docs/codex-progress.md learning/step-02-flutter-app-skeleton.md
git commit -m "step-02: add Flutter app skeleton"
git push
git log -1 --oneline
```

এছাড়া verification-এর জন্য Flutter commands চালানো হয়েছে:

```powershell
flutter pub get
flutter analyze
flutter test
flutter create --org com.imran --project-name smartkash --platforms=android .
```

## 12. What I learned from this step

এই step থেকে শিখলাম কীভাবে একটি Flutter app skeleton clean architecture দিয়ে শুরু করতে হয়। `ProviderScope` Riverpod চালু করে, `MaterialApp.router` routing support দেয়, `go_router` route define করে, আর feature-first folder structure future বড় app maintainable রাখে। SmartKash-এর real feature এখনো তৈরি হয়নি, কিন্তু app boot, theme, routing, folder structure, Android package ID, এবং test foundation তৈরি হয়েছে।
