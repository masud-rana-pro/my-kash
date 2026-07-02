# Step 06b: Cross-Platform Plan And Structure Update

## 1. Step title

Step 06b-এর title: **SmartKash Flutter full cross-platform plan এবং structure normalize করা**।

এই step-এ project direction Android-first থেকে Flutter full cross-platform করা হয়েছে। Supported platforms এখন Android, iOS, Web, Windows, Linux, এবং macOS।

## 2. Why the project changed from Android-first to full Flutter cross-platform

আগে SmartKash পরিকল্পনায় Flutter Android-first app বলা ছিল। এখন লক্ষ্য হলো একই shared Flutter codebase দিয়ে একাধিক platform support করা:

- Android
- iOS
- Web
- Windows
- Linux
- macOS

এর ফলে Flutter architecture শেখা আরও বাস্তবসম্মত হয়। একই business flow, routing, state management, Firebase foundation, এবং backend API integration future-এ multiple platform থেকে ব্যবহার করা যাবে।

## 3. Why we did not manually recreate the project from scratch

Project restart করা হয়নি, কারণ আগের steps-এ গুরুত্বপূর্ণ কাজ already আছে:

- Root repo structure
- Flutter `lib/` feature-first structure
- Riverpod setup
- go_router setup
- Firebase foundation
- Spring Boot backend skeleton
- PostgreSQL/Flyway foundation
- Firebase Admin foundation
- Backend JWT foundation
- Git/GitHub workflow
- Bangla learning files

Manual restart করলে history হারিয়ে যেত এবং working code/config overwrite হওয়ার risk থাকত। তাই existing project preserve করে Flutter platform scaffolding normalize করা হয়েছে।

## 4. What planning docs were updated

Updated planning/workflow docs:

- `README.md`
- `docs/product-plan.md`
- `docs/feature-spec.md`
- `docs/ui-screen-plan.md`
- `docs/backend-api-plan.md`
- `docs/database-plan.md`
- `docs/security-plan.md`
- `docs/admin-plan.md`
- `docs/notification-plan.md`
- `docs/development-roadmap.md`
- `docs/test-checklist.md`
- `docs/architecture-plan.md`
- `docs/codex-instructions.md`
- `docs/codex-progress.md`

Docs এখন বলে SmartKash হলো Flutter full cross-platform app। Android Windows machine-এ primary local testing target, Web second local target।

## 5. What Flutter platform folders mean

```text
apps/mobile/android/
```

Android app shell। Android package/application ID `com.imran.smartkash` preserved।

```text
apps/mobile/ios/
```

iPhone/iPad build shell। Build করতে macOS এবং Xcode দরকার।

```text
apps/mobile/web/
```

Browser/PWA style web build shell। Windows machine-এ local build/test করা যায়।

```text
apps/mobile/windows/
```

Windows desktop build shell। Build করতে Visual Studio Desktop development with C++ workload দরকার।

```text
apps/mobile/linux/
```

Linux desktop build shell। Build করতে Linux environment দরকার।

```text
apps/mobile/macos/
```

macOS desktop build shell। Build করতে macOS এবং Xcode দরকার।

## 6. What was missing before this step

Step 06-এর পরে Flutter app-এ ছিল:

- `android/`
- `lib/`
- `test/`
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`

Missing ছিল:

- `ios/`
- `web/`
- `windows/`
- `linux/`
- `macos/`
- Flutter platform metadata
- Web manifest/index shell
- Desktop runner shells

Backend side-এ Windows Maven wrapper `mvnw.cmd` ছিল, কিন্তু Unix wrapper `mvnw` ছিল না।

## 7. What was added or normalized

Added/normalized:

- Flutter platform folders for Android, iOS, Web, Windows, Linux, macOS।
- Web metadata changed to `SmartKash`।
- iOS display name changed to `SmartKash`।
- macOS product name changed to `SmartKash`।
- Linux window title changed to `SmartKash`।
- Windows window/product display name changed to `SmartKash`।
- `apps/mobile/README.md` updated for cross-platform scope।
- `services/backend/mvnw` added for Unix-like environments।
- `.gitignore` updated for generated platform outputs।
- Android manifest updated with Flutter v2 embedding metadata।
- Android Gradle Plugin updated to `8.6.0` to satisfy the current Flutter tool minimum।
- Android build pinned to installed NDK `28.2.13676358` because local NDK `26.1.10909125` was malformed।

## 8. What was preserved from previous steps

Preserved:

- Existing Flutter `lib/` code।
- `ProviderScope` Riverpod setup।
- `go_router` app routing।
- `AppTheme` structure।
- Firebase bootstrap/config files।
- Auth service/provider foundation।
- Android package/application ID: `com.imran.smartkash`।
- Spring Boot root package: `com.smartkash`।
- PostgreSQL/Flyway foundation।
- Firebase Admin foundation।
- Backend JWT foundation।
- Bangla learning workflow।
- Git/GitHub workflow।

## 9. Platform limitations on Windows

Current Windows machine can verify:

- Android APK debug build, if Android SDK/Gradle environment is ready।
- Web build।
- Flutter analyze/test।

Limitations:

- iOS build requires macOS and Xcode।
- macOS build requires macOS and Xcode।
- Linux desktop build requires Linux environment।
- Windows desktop build requires Visual Studio Desktop development with C++ workload।

## 10. Important config/structure snippets

Flutter create command used:

```powershell
cd apps/mobile
flutter create --platforms=android,ios,web,windows,linux,macos --org com.imran .
```

Platform structure:

```text
apps/mobile/
├── android/
├── ios/
├── web/
├── windows/
├── linux/
├── macos/
├── lib/
├── test/
├── pubspec.yaml
├── pubspec.lock
└── analysis_options.yaml
```

Web title:

```html
<title>SmartKash</title>
```

Android identity:

```groovy
namespace 'com.imran.smartkash'
applicationId 'com.imran.smartkash'
```

Android v2 embedding metadata:

```xml
<meta-data
    android:name="flutterEmbedding"
    android:value="2" />
```

Android build tool settings:

```groovy
ndkVersion '28.2.13676358'
```

Backend Unix wrapper:

```sh
#!/bin/sh

BASE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
WRAPPER_JAR="$BASE_DIR/.mvn/wrapper/maven-wrapper.jar"

if [ ! -f "$WRAPPER_JAR" ]; then
  echo "Maven Wrapper jar not found: $WRAPPER_JAR" >&2
  exit 1
fi

exec java -classpath "$WRAPPER_JAR" org.apache.maven.wrapper.MavenWrapperMain "$@"
```

## 11. Line-by-line or block-by-block Bangla explanation

### Flutter create command

```powershell
flutter create
```

Existing Flutter project-এ missing platform scaffolding generate করে।

```powershell
--platforms=android,ios,web,windows,linux,macos
```

সব target platform folder তৈরি করতে বলে।

```powershell
--org com.imran
```

Android/iOS/macOS bundle/application identifier-এর organization prefix।

```powershell
.
```

Current folder `apps/mobile/`-এর মধ্যে project normalize করে। নতুন project folder তৈরি করে না।

### Web title

```html
<title>SmartKash</title>
```

Browser tab/title-এ app name `SmartKash` দেখাবে।

### Android identity

```groovy
namespace 'com.imran.smartkash'
```

Android code namespace।

```groovy
applicationId 'com.imran.smartkash'
```

Android package/application ID। Firebase Android app config-এর সাথেও এটি match করতে হবে।

### Android v2 embedding metadata

```xml
<meta-data
    android:name="flutterEmbedding"
    android:value="2" />
```

Flutter Android app-কে modern v2 embedding use করতে বলে। এটি না থাকলে Flutter build `deleted Android v1 embedding` error দিতে পারে।

### Android NDK pin

```groovy
ndkVersion '28.2.13676358'
```

Local machine-এ NDK `26.1.10909125` malformed ছিল, তাই installed healthy NDK `28.2.13676358` use করা হয়েছে। এতে Android debug APK build pass করেছে।

### Backend Unix wrapper

```sh
BASE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
```

Script যে folder-এ আছে সেটি বের করে।

```sh
WRAPPER_JAR="$BASE_DIR/.mvn/wrapper/maven-wrapper.jar"
```

Maven Wrapper jar-এর path define করে।

```sh
if [ ! -f "$WRAPPER_JAR" ]; then
```

Wrapper jar আছে কিনা check করে।

```sh
exec java -classpath "$WRAPPER_JAR" org.apache.maven.wrapper.MavenWrapperMain "$@"
```

Java দিয়ে Maven Wrapper চালায় এবং user-provided Maven arguments pass করে।

## 12. How to verify Android and Web locally

Android:

```powershell
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Web:

```powershell
cd apps/mobile
flutter build web
```

Device/platform list:

```powershell
flutter devices
```

## 13. Why iOS/macOS require macOS/Xcode

iOS এবং macOS build Apple toolchain-এর উপর নির্ভর করে। Xcode, Apple SDK, signing tools, এবং simulator tools শুধু macOS-এ officially available। তাই Windows থেকে iOS/macOS build করা যাবে না।

## 14. Why Windows desktop build requires Visual Studio C++ workload

Flutter Windows desktop runner native C++ project হিসেবে build হয়। তাই Visual Studio Build Tools এবং Desktop development with C++ workload দরকার। এগুলো না থাকলে Windows desktop build fail করা expected limitation।

## 15. Common mistakes and cautions

- Existing `lib/` overwrite করা যাবে না।
- Riverpod/go_router/Firebase foundation remove করা যাবে না।
- Android package ID বদলানো যাবে না।
- `google-services.json` commit করা যাবে না।
- Firebase Admin service account JSON commit করা যাবে না।
- iOS/macOS build Windows-এ fail করলে সেটি bug নয়, platform limitation।
- Windows desktop build Visual Studio C++ workload ছাড়া fail করলে সেটি expected।
- Android manifest-এ Flutter v2 embedding metadata না থাকলে APK build fail করতে পারে।
- Local Android SDK-এর NDK corrupt/malformed হলে build fail করতে পারে; healthy installed NDK pin করা যায়।
- Current Flutter tool AGP/Kotlin future-compatibility warning দিয়েছে; future maintenance step-এ AGP/Kotlin upgrade করা ভালো।
- Platform scaffolding step-এ business feature UI add করা যাবে না।
- Backend business schema বা API add করা যাবে না।

## 16. Git commands used

```powershell
git status --short
flutter create --platforms=android,ios,web,windows,linux,macos --org com.imran .
git add .gitignore README.md docs apps/mobile services/backend/mvnw learning/step-06b-cross-platform-plan-and-structure-update.md
git diff --cached --stat
git commit -m "step-06b: update plan for Flutter cross-platform"
git push
git status --short
```

## 17. What I learned from this step

এই step থেকে শিখলাম Flutter project restart না করেও existing project-এ missing platform folders add করা যায়। Shared `lib/` code preserve করলে একই app architecture Android, iOS, Web, Windows, Linux, এবং macOS-এ ব্যবহার করা যায়। তবে সব platform একই machine-এ build করা যায় না; Windows machine-এ Android/Web local verification practical, iOS/macOS-এর জন্য Mac দরকার, Linux-এর জন্য Linux দরকার, আর Windows desktop-এর জন্য Visual Studio C++ workload দরকার।
