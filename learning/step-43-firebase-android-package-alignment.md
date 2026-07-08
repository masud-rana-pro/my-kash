# Step 43: Firebase Android Package Alignment

## 1. Step title

এই step-এ SmartKash Flutter Android app-এর package/application ID Firebase Android client config-এর সাথে মিলিয়ে দেওয়া হয়েছে।

## 2. What was implemented

- Android `namespace` update করা হয়েছে।
- Android `applicationId` update করা হয়েছে।
- `MainActivity.kt` সঠিক Kotlin package path-এ নেওয়া হয়েছে।
- Backend local `.env` Firebase Admin JSON metadata-এর সাথে sync করা হয়েছে।
- Test checklist ও progress document update করা হয়েছে।

## 3. কেন এই step দরকার ছিল

`flutter run` করার সময় error এসেছিল:

```text
Execution failed for task ':app:processDebugGoogleServices'.
No matching client found for package name 'com.imran.smartkash'
```

এর মানে Flutter app যে Android package দিয়ে build হচ্ছে, Firebase-এর `google-services.json` সেই package-এর client খুঁজে পাচ্ছে না।

## 4. আসল mismatch কী ছিল

Flutter Android app আগে ব্যবহার করছিল:

```gradle
namespace 'com.imran.smartkash'
applicationId 'com.imran.smartkash'
```

কিন্তু provided Firebase Android config-এ package ছিল:

```json
"package_name": "com.smartkash.app"
```

তাই Gradle Firebase config process করতে পারছিল না।

## 5. Important snippets

### `android/app/build.gradle`

```gradle
android {
    namespace 'com.smartkash.app'

    defaultConfig {
        applicationId 'com.smartkash.app'
    }
}
```

Block-by-block ব্যাখ্যা:

- `namespace 'com.smartkash.app'`: Android resource/class namespace define করে।
- `applicationId 'com.smartkash.app'`: installed Android app-এর real package id। Firebase এই value দিয়েই `google-services.json`-এর client match করে।
- দুইটা value Firebase config-এর `package_name`-এর সাথে মিললে `processDebugGoogleServices` pass করবে।

### `MainActivity.kt`

```kotlin
package com.smartkash.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

Line-by-line ব্যাখ্যা:

- `package com.smartkash.app`: Kotlin class এখন Android app namespace-এর সাথে match করছে।
- `FlutterActivity`: Flutter engine Android activity হিসেবে app চালায়।
- `MainActivity`: Android launcher activity, যেখান থেকে Flutter UI open হয়।

## 6. কেন `google-services.json` manually edit করা হয়নি

`google-services.json` Firebase Console থেকে generated file। এর ভিতরে package name manually change করলে ভুল config তৈরি হতে পারে। তাই safer fix হলো Android app package Firebase config-এর সাথে align করা।

## 7. Backend `.env` নিয়ে কী করা হয়েছে

Firebase Admin service account JSON থেকে local `.env` metadata sync করা হয়েছে:

```properties
FIREBASE_PROJECT_ID=...
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY_ID=...
FIREBASE_CLIENT_ID=...
```

ব্যাখ্যা:

- এগুলো backend Firebase Admin SDK initialize করতে লাগে।
- `.env` ignored, তাই GitHub-এ যাবে না।
- private key secret, তাই learning file বা final output-এ private key লেখা যাবে না।

## 8. কী implement করা হয়নি

- নতুন login UI তৈরি করা হয়নি।
- wallet dashboard API integration করা হয়নি।
- money-changing API বা frontend flow add করা হয়নি।
- Firebase Admin service account JSON commit করা হয়নি।
- `google-services.json` commit করা হয়নি, কারণ project rule অনুযায়ী এটি local config হিসেবে ignored আছে।

## 9. SmartKash flow-এ এটা কীভাবে কাজ করবে

1. Flutter Android app `com.smartkash.app` package দিয়ে build হবে।
2. Gradle `android/app/google-services.json` পড়বে।
3. Firebase client config package match করবে।
4. Firebase Phone Auth test OTP flow app-এ কাজ করতে পারবে।
5. Flutter Firebase ID token backend-এ পাঠাবে।
6. Spring Boot Firebase Admin SDK token verify করবে।
7. Backend JWT issue করে user/profile/wallet flow চালাবে।

## 10. Common mistakes and cautions

- `google-services.json` ভুল path-এ রাখলে Gradle read করবে না। সঠিক path:

```text
apps/mobile/android/app/google-services.json
```

- Firebase Console package name আর Android `applicationId` mismatch হলে build fail করবে।
- Firebase Admin service account JSON কখনো repo-তে commit করা যাবে না।
- `.env` কখনো commit করা যাবে না।
- শুধু warning দেখে AGP/Kotlin upgrade করতে গিয়ে নতুন build issue introduce করা উচিত না; আগে blocking error fix করতে হবে।

## 11. Manual verification commands

Flutter app run:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter clean
flutter pub get
flutter run
```

Expected output:

```text
Running Gradle task 'assembleDebug'...
Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...
```

আর এই error আর আসবে না:

```text
No matching client found for package name
```

Backend চালাতে:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Expected backend output:

```text
Firebase Admin SDK initialized
Tomcat started on port 8080
```

## 12. Git commands used

```powershell
git status --short --branch
git add ...
git commit -m "step-43: align Firebase Android package"
git push
```

## 13. What I learned from this step

এই step থেকে শিখলাম Firebase Android client config এবং Android `applicationId` একই না হলে Flutter app build হবে না। `google-services.json` Firebase project/client-এর identity বহন করে, তাই app package change করলে Firebase Console config-ও match করতে হবে। SmartKash এখন provided Firebase Android config-এর সাথে aligned।
