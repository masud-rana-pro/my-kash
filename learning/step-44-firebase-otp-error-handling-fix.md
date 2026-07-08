# Step 44: Firebase OTP Error Handling Fix

## 1. Step title

এই step-এ Flutter login screen-এর Firebase OTP error message fix করা হয়েছে।

## 2. What was implemented

- Firebase phone verification failure raw exception সরাসরি UI state-এ পাঠানো বন্ধ করা হয়েছে।
- `FirebasePhoneAuthException` নামে ছোট local exception model যোগ করা হয়েছে।
- `AuthController` এখন Firebase OTP error code অনুযায়ী readable message দেখায়।
- Progress doc ও test checklist update করা হয়েছে।

## 3. কেন এই step দরকার ছিল

Login screen-এ `Send OTP` চাপার পর UI-তে এমন error দেখাচ্ছিল:

```text
TypeError: Instance of 'FirebaseException': type 'FirebaseException' is not a subtype of type 'JavaScriptObject'
```

এই message user-friendly না। এটা সাধারণত Firebase/Flutter platform bridge থেকে raw exception UI-তে চলে এলে দেখা যায়। User যেন বুঝতে পারে আসল সমস্যা কী, তাই exception mapping দরকার।

## 4. Important code snippets

### `firebase_phone_auth_service.dart`

```dart
verificationFailed: (exception) {
  if (!completer.isCompleted) {
    completer.completeError(
      FirebasePhoneAuthException.fromFirebase(exception),
      StackTrace.current,
    );
  }
},
```

Block-by-block ব্যাখ্যা:

- `verificationFailed`: Firebase phone verification fail হলে এই callback চলে।
- `exception`: Firebase-এর raw `FirebaseAuthException`।
- `FirebasePhoneAuthException.fromFirebase(exception)`: raw exception থেকে শুধু safe `code` এবং `message` নেওয়া হয়।
- `completeError(...)`: future fail করে, কিন্তু এবার app-safe exception দিয়ে।
- `StackTrace.current`: debugging-এর জন্য stack trace রাখা হয়।

### Local exception model

```dart
class FirebasePhoneAuthException implements Exception {
  const FirebasePhoneAuthException({
    required this.code,
    required this.message,
  });

  factory FirebasePhoneAuthException.fromFirebase(
    FirebaseAuthException exception,
  ) {
    return FirebasePhoneAuthException(
      code: exception.code,
      message: exception.message ?? exception.code,
    );
  }
}
```

Line-by-line ব্যাখ্যা:

- `implements Exception`: Dart exception হিসেবে ব্যবহার করা যাবে।
- `code`: Firebase error code, যেমন `invalid-phone-number`, `too-many-requests`।
- `message`: Firebase-এর readable message।
- `fromFirebase`: Firebase exception থেকে SmartKash-friendly exception বানায়।
- `exception.message ?? exception.code`: message না থাকলে code fallback হিসেবে থাকে।

### `auth_controller.dart`

```dart
if (error is FirebasePhoneAuthException) {
  return _firebasePhoneAuthMessage(error);
}
```

ব্যাখ্যা:

- Controller আগে check করে error Firebase phone auth related কিনা।
- হলে `_firebasePhoneAuthMessage` দিয়ে user-friendly text বানায়।
- এতে raw platform error UI-তে যায় না।

```dart
case 'app-not-authorized':
  return 'This Android app is not authorized in Firebase. Check package name and google-services.json.';
```

ব্যাখ্যা:

- যদি Firebase বলে Android app authorized না, তাহলে user/developer বুঝবে package name বা `google-services.json` check করতে হবে।

## 5. SmartKash flow-এ এটা কীভাবে কাজ করবে

1. User login screen-এ mobile number দেয়।
2. `Send OTP` চাপলে Flutter Firebase Phone Auth call করে।
3. Firebase fail করলে service raw exception wrap করে।
4. Controller readable message বানায়।
5. UI error box-এ clear message দেখায়।
6. Firebase success হলে আগের মতো OTP verify করে backend login flow চলবে।

## 6. কী implement করা হয়নি

- Firebase verification bypass করা হয়নি।
- fake login add করা হয়নি।
- backend auth logic change করা হয়নি।
- wallet dashboard বা money feature UI add করা হয়নি।

## 7. Common mistakes and cautions

- Raw exception সরাসরি UI-তে দেখালে user বুঝবে না কী করতে হবে।
- Firebase Phone Auth disabled থাকলে code fix করলেও OTP যাবে না; Firebase Console-এ Phone provider enable থাকতে হবে।
- Android app package এবং `google-services.json` mismatch হলে OTP flow fail করতে পারে।
- Test OTP ব্যবহার করলেও Firebase Console-এ test phone number ঠিকভাবে configured থাকতে হবে।

## 8. Manual verification commands

Backend চালু করো:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Flutter app চালু করো:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter run
```

Login test:

```text
Phone: 01575634380
OTP: 123456
```

Expected output:

- `Send OTP` চাপলে raw `TypeError ... JavaScriptObject` আর দেখা যাবে না।
- যদি Firebase config issue থাকে, readable Firebase message দেখাবে।
- OTP success হলে backend login হবে।
- PIN set না থাকলে PIN setup screen দেখাবে।

## 9. Git commands used

```powershell
git status --short --branch
git add ...
git commit -m "step-44: fix Firebase OTP error handling"
git push
```

## 10. What I learned from this step

এই step থেকে শিখলাম platform/Firebase exception সরাসরি UI-তে দেখানো ভালো না। Service layer exception wrap করলে controller সহজে user-friendly message বানাতে পারে, আর user বুঝতে পারে কোন setup/config ঠিক করতে হবে।
