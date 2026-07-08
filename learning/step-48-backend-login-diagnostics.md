# Step 48: Backend Login Diagnostics

## 1. Step title

এই step-এ Firebase OTP success হওয়ার পর backend login fail করলে exact reason দেখার ব্যবস্থা করা হয়েছে।

## 2. What was implemented

- Flutter login error message আর generic `Check backend Firebase Admin env values` দেখাবে না।
- Flutter এখন backend-এর actual error message দেখাবে।
- Backend Firebase ID token verify fail করলে terminal log-এ safe diagnostic code/message দেখাবে।
- Raw Firebase ID token log করা হয়নি।

## 3. কেন এই step দরকার ছিল

Login screen-এ দেখা যাচ্ছিল:

```text
Firebase OTP verified, but backend login failed.
Check backend Firebase Admin env values.
```

এই message খুব generic। Backend env ঠিক থাকলেও একই message দেখাচ্ছিল। তাই actual backend reason দেখতে না পেলে শুধু আন্দাজ করতে হচ্ছিল।

## 4. Important Flutter snippet

```dart
if (error.path == '/api/auth/firebase-login') {
  return 'Firebase OTP verified, but backend login failed: ${error.message}';
}
```

ব্যাখ্যা:

- `/api/auth/firebase-login`: Firebase OTP success হওয়ার পর backend JWT login endpoint।
- `error.message`: backend যে exact message পাঠিয়েছে, সেটাই UI-তে দেখাবে।
- এতে generic env blame না দেখিয়ে real reason দেখা যাবে, যেমন `Invalid Firebase ID token.`

## 5. Important backend snippet

```java
} catch (FirebaseAuthException exception) {
    log.warn(
            "Firebase ID token verification failed. code={}, message={}",
            exception.getErrorCode(),
            exception.getMessage()
    );
    throw new AuthException("Invalid Firebase ID token.", exception);
}
```

Block-by-block ব্যাখ্যা:

- `FirebaseAuthException`: Firebase Admin SDK token verify করতে না পারলে এই exception আসে।
- `exception.getErrorCode()`: Firebase error code দেয়।
- `exception.getMessage()`: error-এর readable details দেয়।
- `log.warn(...)`: backend terminal-এ diagnostic message দেখায়।
- raw ID token log করা হয়নি, কারণ token sensitive।
- client-কে safe message `Invalid Firebase ID token.` পাঠানো হয়।

## 6. SmartKash login flow-এ এটা কীভাবে সাহায্য করবে

1. Flutter Firebase OTP verify করে।
2. Flutter Firebase ID token backend-এ পাঠায়।
3. Backend Firebase Admin দিয়ে token verify করে।
4. Verify fail হলে backend terminal এখন code/message দেখাবে।
5. Flutter UI backend-এর actual error দেখাবে।
6. এরপর exact cause দেখে fix করা যাবে।

## 7. Common causes যদি backend বলে Invalid Firebase ID token

- Android app এখনও পুরোনো `google-services.json` দিয়ে build হয়েছে।
- App clean rebuild করা হয়নি।
- Backend পুরোনো process চলছে; restart করা হয়নি।
- Firebase project mismatch।
- Emulator/device clock badly wrong।
- Firebase ID token stale; app sign-out/clean install দরকার।

## 8. Manual verification commands

Backend restart:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Flutter clean run:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter clean
flutter pub get
flutter run --dart-define=FIREBASE_ENABLED=true --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

If still fails, collect:

```text
Backend terminal line containing:
Firebase ID token verification failed. code=..., message=...
```

## 9. Git commands used

```powershell
git status --short --branch
git add ...
git commit -m "step-48: improve backend login diagnostics"
git push
```

## 10. What I learned

এই step থেকে শিখলাম generic error message developer time নষ্ট করে। Login flow debug করতে হলে frontend এবং backend দু জায়গাতেই safe diagnostic message থাকা দরকার, কিন্তু sensitive token কখনো log করা যাবে না।
