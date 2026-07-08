# Step 38: Flutter Generated Brand Assets

## 1. Step title

এই ধাপে SmartKash app-এর জন্য generated logo এবং home screen image assets যোগ করা হয়েছে।

## 2. What was implemented

- SmartKash-এর জন্য original logo concept generate করা হয়েছে।
- App/UI-তে ব্যবহার করার জন্য icon-only logo mark generate করা হয়েছে।
- Home dashboard header-এর জন্য original fintech illustration generate করা হয়েছে।
- Home promo carousel/card-এর জন্য original promotional banner generate করা হয়েছে।
- Generated images `apps/mobile/assets/images/` folder-এ রাখা হয়েছে।
- `pubspec.yaml`-এ Flutter assets folder register করা হয়েছে।
- Home screen header, promo banner এবং profile/logo mark-এ generated assets ব্যবহার করা হয়েছে।
- Login screen-এর SmartKash logo mark-এ generated asset ব্যবহার করা হয়েছে।

## 3. Why this step is needed

Reference screenshots থেকে layout idea নেওয়া হয়েছে, কিন্তু SmartKash-এর visual identity নিজস্ব হওয়া দরকার। তাই bKash-এর logo, pink color, bird mark, promotional artwork বা exact brand style copy না করে SmartKash-এর জন্য নতুন teal/blue based logo এবং banner তৈরি করা হয়েছে।

## 4. Files/folders created or changed

- `apps/mobile/assets/images/smartkash-logo-concept.png`
- `apps/mobile/assets/images/smartkash-logo-mark.png`
- `apps/mobile/assets/images/smartkash-header.png`
- `apps/mobile/assets/images/smartkash-promo.png`
- `apps/mobile/lib/core/constants/app_assets.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `apps/mobile/lib/features/auth/presentation/login_screen.dart`
- `apps/mobile/pubspec.yaml`
- `docs/codex-progress.md`
- `learning/step-38-flutter-generated-brand-assets.md`

## 5. Important code/config snippets

### Asset registration in pubspec

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

### Bangla explanation

- `uses-material-design: true` Flutter Material icons/features enable রাখে।
- `assets:` section Flutter-কে বলে app bundle-এ কোন static files include করতে হবে।
- `assets/images/` দিলে ওই folder-এর images app runtime-এ `Image.asset(...)` দিয়ে load করা যায়।

### Asset constants

```dart
class AppAssets {
  const AppAssets._();

  static const smartKashHeader = 'assets/images/smartkash-header.png';
  static const smartKashLogoConcept =
      'assets/images/smartkash-logo-concept.png';
  static const smartKashLogoMark = 'assets/images/smartkash-logo-mark.png';
  static const smartKashPromo = 'assets/images/smartkash-promo.png';
}
```

### Bangla explanation

- `AppAssets` class asset path centralize করে।
- একই string path বারবার screen file-এ লিখতে হয় না।
- কোনো asset rename করলে শুধু এই file update করলেই হবে।
- `_()` private constructor, তাই এই class object বানানোর জন্য নয়; শুধু constants রাখার জন্য।

### Home header image

```dart
Positioned.fill(
  child: Image.asset(
    AppAssets.smartKashHeader,
    fit: BoxFit.cover,
    opacity: const AlwaysStoppedAnimation(0.72),
  ),
),
```

### Bangla explanation

- `Positioned.fill` image-কে পুরো header area জুড়ে দেয়।
- `Image.asset` local bundled image load করে।
- `fit: BoxFit.cover` image-কে crop/scale করে area fill করে।
- `opacity` header image একটু transparent করে, যাতে text/button readable থাকে।

### Promo banner image

```dart
Image.asset(AppAssets.smartKashPromo, fit: BoxFit.cover),
```

### Bangla explanation

- Promo card-এ generated promotional banner load করা হয়েছে।
- `BoxFit.cover` দিয়ে card-এর size অনুযায়ী image fit হয়।
- এর উপর gradient overlay দেওয়া হয়েছে, যাতে left-side text readable থাকে।

### Login logo mark

```dart
Image.asset(
  AppAssets.smartKashLogoMark,
  width: 72,
  height: 72,
  fit: BoxFit.cover,
),
```

### Bangla explanation

- Login screen-এর logo জায়গায় icon-only SmartKash mark ব্যবহার করা হয়েছে।
- `width` এবং `height` fixed রাখায় layout stable থাকে।
- `fit: BoxFit.cover` square image square box-এর মধ্যে cleanভাবে বসায়।

## 6. How this works in the SmartKash app flow

Home screen এখন শুধু code-drawn shapes নয়, বরং generated original visual assets ব্যবহার করছে। এতে dashboard বেশি polished দেখাবে। Login screen-এও SmartKash logo mark আছে, ফলে user app branding পরিষ্কারভাবে বুঝতে পারবে।

## 7. Common mistakes and cautions

- `pubspec.yaml` update করার পর `flutter pub get` না চালালে asset load error হতে পারে।
- Wrong path দিলে runtime-এ `Unable to load asset` error আসবে।
- Generated asset খুব বড় হলে app size বাড়ে; পরে final optimization step-এ resize/compress করা যাবে।
- bKash বা অন্য brand-এর exact logo/color/artwork ব্যবহার করা যাবে না।
- Text-heavy generated image avoid করা ভালো, কারণ image generator text ভুল করতে পারে।

## 8. Manual verification commands

```bat
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run
```

Optional:

```bat
flutter build apk --debug
flutter build web
```

## 9. Expected manual output

- Home screen top header-এ SmartKash-style teal/blue generated background দেখা যাবে।
- Home profile/avatar জায়গায় SmartKash logo mark দেখা যাবে।
- Promo card-এ generated fintech banner image দেখা যাবে।
- Login screen-এ SmartKash icon-only logo mark দেখা যাবে।
- Terminal-এ `Unable to load asset` error আসবে না।

## 10. Git commands used

```bat
git status --short --branch
git add <step-38-files>
git commit -m "step-38: add generated Flutter brand assets"
git push
```

## 11. What I learned from this step

এই ধাপে শিখলাম Flutter app-এ generated image assets কীভাবে project folder-এ রাখা হয়, `pubspec.yaml`-এ register করা হয়, central constants class দিয়ে path manage করা হয়, এবং `Image.asset` দিয়ে UI screen-এ ব্যবহার করা হয়।

## 12. Step 38b gap fix: launcher and web icons

Audit করার পরে দেখা গেল Step 38 UI-এর ভিতরে generated assets ব্যবহার করলেও Android launcher icon এবং Web favicon/PWA icon এখনো default Flutter icon ছিল। তাই Step 38b-তে এই gap fix করা হয়েছে।

### What was fixed

- Android `mipmap-*` launcher icons generated SmartKash logo mark দিয়ে replace করা হয়েছে।
- Android manifest-এ explicit app icon reference যোগ করা হয়েছে।
- Web `favicon.png` replace করা হয়েছে।
- Web `icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png` replace করা হয়েছে।
- Web manifest-এর `theme_color` SmartKash teal করা হয়েছে।

### Important snippet

```xml
<application
    android:icon="@mipmap/ic_launcher"
    android:label="SmartKash"
    android:theme="@style/LaunchTheme">
```

### Bangla explanation

- `android:icon="@mipmap/ic_launcher"` Android-কে বলে launcher/home screen-এ কোন icon দেখাবে।
- `@mipmap/ic_launcher` path Android density-specific icon folder থেকে correct size pick করে।
- `android:label="SmartKash"` installed app-এর name দেখায়।
- `android:theme="@style/LaunchTheme"` app launch হওয়ার সময় initial theme ব্যবহার করে।

### Web manifest snippet

```json
"background_color": "#F5F7FA",
"theme_color": "#008F7A"
```

### Bangla explanation

- `background_color` PWA launch/loading background color control করে।
- `theme_color` browser/app shell-এর theme tint control করে।
- `#008F7A` SmartKash-এর teal brand color।

### Manual verification

```bat
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run
flutter build web
```

Expected:

- Android emulator/device launcher বা recent apps-এ SmartKash logo mark দেখা যাবে।
- Browser tab/PWA manifest icon SmartKash mark use করবে।
- App UI-তে Home/Login generated assets আগের মতো load হবে।
