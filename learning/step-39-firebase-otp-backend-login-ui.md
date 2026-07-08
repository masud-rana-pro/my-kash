# Step 39: Firebase OTP And Backend Login UI

## 1. Step title

এই ধাপে Login screen-কে Firebase Phone Auth test OTP flow এবং backend JWT login flow-এর সাথে connect করা হয়েছে।

## 2. What was implemented

- Login screen থেকে mobile number দিয়ে Firebase OTP request করা যায়।
- Firebase test OTP input দিয়ে Firebase sign-in করা যায়।
- Firebase sign-in success হলে Firebase ID token backend `/api/auth/firebase-login` API-তে পাঠানোর flow আছে।
- Backend JWT response secure storage-এ save করার existing repository ব্যবহার করা হয়েছে।
- Loading, info এবং error message UI যোগ করা হয়েছে।
- `google-services.json` local config support করার জন্য Android Google Services Gradle plugin যোগ করা হয়েছে।
- Backend Firebase Admin env এখনো ready না থাকলে user-friendly error দেখানোর ব্যবস্থা রাখা হয়েছে।

## 3. Why this step is needed

SmartKash app-এ শুধু UI থাকলে login real flow test করা যায় না। Firebase test OTP + backend JWT login connect করলে frontend, Firebase, backend auth API এবং secure token storage একসাথে কাজ শুরু করে।

## 4. Files created or changed

- `apps/mobile/android/settings.gradle`
- `apps/mobile/android/app/build.gradle`
- `apps/mobile/lib/app/config/firebase_config.dart`
- `apps/mobile/lib/app/config/firebase_bootstrap.dart`
- `apps/mobile/lib/features/auth/data/firebase_phone_auth_service.dart`
- `apps/mobile/lib/features/auth/domain/auth_session_status.dart`
- `apps/mobile/lib/features/auth/domain/auth_session_state.dart`
- `apps/mobile/lib/features/auth/providers/auth_controller.dart`
- `apps/mobile/lib/features/auth/presentation/login_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-39-firebase-otp-backend-login-ui.md`

## 5. Important code/config snippets

### Google Services plugin

```gradle
id "com.google.gms.google-services" version "4.4.2" apply false
```

```gradle
id 'com.google.gms.google-services'
```

### Bangla explanation

- প্রথম line root Android Gradle settings-এ Google Services plugin available করে।
- দ্বিতীয় line app module-এ plugin apply করে।
- এর ফলে local `google-services.json` থেকে Android Firebase resource generate হতে পারে।
- `google-services.json` `.gitignore`-এ আছে, তাই secret/client config repo-তে commit করা হয় না।

### Firebase bootstrap

```dart
await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
```

### Bangla explanation

- `FIREBASE_ENABLED=true` হলে app startup-এ Firebase initialize হবে।
- Dart define দিয়ে Firebase options দিলে সেটি ব্যবহার হবে।
- Dart define না দিলে Android native config path ব্যবহার করতে পারে, যেখানে `google-services.json` থেকে config আসে।

### OTP send service

```dart
await _auth.verifyPhoneNumber(
  phoneNumber: phoneNumber,
  verificationCompleted: (credential) async {
    await _auth.signInWithCredential(credential);
  },
  verificationFailed: (exception) {
    completer.completeError(exception);
  },
  codeSent: (verificationId, forceResendingToken) {
    completer.complete(
      PhoneOtpStartResult(
        verificationId: verificationId,
        autoVerified: false,
      ),
    );
  },
);
```

### Bangla explanation

- `verifyPhoneNumber` Firebase Phone Auth OTP flow start করে।
- `phoneNumber` E.164 format-এ যায়, যেমন `+8801575634380`।
- `verificationCompleted` Android auto-verification হলে sign-in করে।
- `verificationFailed` error হলে UI-তে message দেখানোর জন্য error পাঠায়।
- `codeSent` হলে Firebase একটি `verificationId` দেয়, যেটি পরে OTP verify করার জন্য লাগে।

### OTP verify service

```dart
final credential = PhoneAuthProvider.credential(
  verificationId: verificationId,
  smsCode: smsCode,
);

return _auth.signInWithCredential(credential);
```

### Bangla explanation

- `verificationId` Firebase-এর OTP session identify করে।
- `smsCode` হলো user-entered fixed test OTP।
- `PhoneAuthProvider.credential` দিয়ে Firebase credential বানানো হয়।
- `signInWithCredential` Firebase user sign-in complete করে।

### Backend session sync

```dart
await _firebasePhoneAuthService.signInWithSmsCode(
  verificationId: verificationId,
  smsCode: smsCode,
);
await syncBackendSession(forceRefresh: true);
```

### Bangla explanation

- প্রথমে Firebase OTP verify হয়।
- তারপর `syncBackendSession` Firebase ID token নিয়ে backend `/api/auth/firebase-login` API call করে।
- Backend valid হলে JWT দেয়।
- JWT secure storage-এ save হয়।

### Login screen action

```dart
final nextLabel = authState.isOtpSent ? 'Verify & Login' : 'Send OTP';
```

### Bangla explanation

- OTP send করার আগে button text `Send OTP`।
- OTP send হওয়ার পরে একই action bar `Verify & Login` হয়।
- এতে reference login UI-এর bottom action bar pattern বজায় থাকে।

## 6. How this connects to SmartKash flow

User login screen-এ phone number দেবে। Firebase test OTP verify হলে backend JWT তৈরি হবে। এই JWT পরে wallet, add money, send money, recharge, savings, transaction APIs call করার জন্য লাগবে।

## 7. Important setup notes

Firebase test phone:

```text
+8801575634380
```

Firebase test OTP:

```text
123456
```

Backend Firebase Admin env এখনো ready না থাকলে Firebase OTP verify হতে পারে, কিন্তু backend JWT login fail করবে। তখন expected error:

```text
Firebase OTP verified, but backend login failed. Check backend Firebase Admin env values.
```

## 8. Common mistakes and cautions

- `FIREBASE_ENABLED=true` ছাড়া Firebase OTP flow কাজ করবে না।
- `google-services.json` wrong path-এ থাকলে Android Firebase config fail করতে পারে।
- Test phone Firebase Console-এ exact E.164 format-এ add করতে হবে।
- Real SMS OTP ব্যবহার করা যাবে না; MVP-তে fixed test OTP only।
- Backend Firebase Admin env missing থাকলে backend JWT login fail করবে।
- PIN Flutter app-এ store করা যাবে না।

## 9. Manual verification commands

Backend:

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Flutter:

```bat
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run --dart-define=FIREBASE_ENABLED=true --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

## 10. Expected output

- Login screen open হবে।
- Phone field-এ `01575634380` দিলে bottom button `Send OTP` enabled হবে।
- `Send OTP` চাপলে Firebase test OTP flow start হবে।
- `Use Firebase test OTP code` চাপলে `123456` fill হবে।
- `Verify & Login` চাপলে Firebase verify হবে।
- Backend Firebase Admin env ready না থাকলে backend login error দেখাবে; ready থাকলে Home screen-এ return করবে।

## 11. Git commands used

```bat
git status --short --branch
git add <step-39-files>
git commit -m "step-39: wire Firebase OTP login UI"
git push
```

## 12. What I learned from this step

এই ধাপে শিখলাম কীভাবে Flutter UI থেকে Firebase test OTP request করা হয়, OTP verify করে Firebase user sign-in করা হয়, তারপর Firebase ID token backend-এ পাঠিয়ে SmartKash backend JWT নেওয়া হয়।
