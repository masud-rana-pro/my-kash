# Step 47: Login Backend Retry Handling

## 1. Step title

এই step-এ SmartKash login flow-তে backend timeout হলে retry experience ঠিক করা হয়েছে।

## 2. What was implemented

- Flutter API connect timeout 15s থেকে 45s করা হয়েছে।
- receive timeout 20s থেকে 60s করা হয়েছে।
- Dio timeout/connection error হলে readable message দেখানো হয়েছে।
- App package constant `com.smartkash.app` করা হয়েছে।
- OTP session থাকলে backend timeout-এর পরেও button `Verify & Login` থাকবে।

## 3. কেন এই step দরকার ছিল

Screenshot-এ error ছিল:

```text
The request connection took longer than 0:00:15.000000 and it was aborted.
```

এর মানে Firebase OTP step শেষ হওয়ার পর app backend login API call করতে গিয়ে timeout করেছে। এটা Firebase captcha/OTP problem না, backend reach/response timeout problem।

## 4. Important code snippets

### API timeout config

```dart
static const apiConnectTimeout = Duration(seconds: 45);
static const apiReceiveTimeout = Duration(seconds: 60);
```

ব্যাখ্যা:

- `apiConnectTimeout`: backend-এর সাথে connection establish করার জন্য wait time।
- `apiReceiveTimeout`: request যাওয়ার পর response পাওয়ার জন্য wait time।
- Emulator + local Spring Boot কখনো slow হলে 15s খুব কম হতে পারে, তাই 45/60s করা হয়েছে।

### Backend timeout friendly message

```dart
if (error.type == DioExceptionType.connectionTimeout ||
    error.type == DioExceptionType.receiveTimeout ||
    error.type == DioExceptionType.sendTimeout) {
  return const ApiException(
    message:
        'Backend request timed out. Make sure Spring Boot is running on port 8080, then try Verify & Login again.',
  );
}
```

Block-by-block ব্যাখ্যা:

- `DioExceptionType.connectionTimeout`: backend connect হতে দেরি।
- `receiveTimeout`: backend response দিতে দেরি।
- `sendTimeout`: request send হতে দেরি।
- `ApiException`: UI-friendly error message বানানো হয়।
- message user-কে বলে backend running কিনা check করে আবার Verify & Login চাপতে।

### OTP retry state

```dart
bool get canVerifyOtp => verificationId != null && verificationId!.isNotEmpty;
```

ব্যাখ্যা:

- Firebase OTP session শুরু হলে `verificationId` থাকে।
- backend login fail হলেও `verificationId` থাকলে user আবার OTP verify/backend login retry করতে পারবে।

```dart
final canVerifyOtp = authState.isOtpSent || authState.canVerifyOtp;
final nextLabel = canVerifyOtp ? 'Verify & Login' : 'Send OTP';
```

ব্যাখ্যা:

- শুধু status `otpSent` না, `verificationId` থাকলেও button Verify mode-এ থাকবে।
- এতে backend timeout হলে user আবার Send OTP না করে Verify & Login retry করতে পারে।

## 5. SmartKash login flow এখন কেমন

1. User phone number দেয়।
2. Send OTP চাপলে Firebase OTP session তৈরি হয়।
3. User OTP `123456` দেয়।
4. Verify & Login চাপলে Firebase sign-in হয়।
5. Flutter Firebase ID token backend-এ পাঠায়।
6. Backend JWT issue করে।
7. Backend slow/timeout হলে UI clear message দেখায়।
8. User backend run check করে একই OTP দিয়ে Verify & Login retry করতে পারে।

## 6. কী implement করা হয়নি

- Firebase bypass করা হয়নি।
- mock login add করা হয়নি।
- backend auth rule change করা হয়নি।
- wallet/home feature API integration করা হয়নি।

## 7. Common mistakes

- Backend run না থাকলে Android emulator থেকে `10.0.2.2:8080` connect হবে না।
- Backend restart না করলে new `.env`/config apply হবে না।
- Chrome/Web দিয়ে Android Firebase OTP test করা যাবে না।
- OTP session না হলে Verify & Login কাজ করবে না।

## 8. Manual verification commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Health:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/actuator/health
```

Android:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter run --dart-define=FIREBASE_ENABLED=true --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Expected:

- First arrow: OTP session starts.
- Button becomes `Verify & Login`.
- OTP `123456`.
- Second arrow: backend login.
- If timeout happens, backend check করে same OTP দিয়ে retry.

## 9. Git commands used

```powershell
git status --short --branch
git add ...
git commit -m "step-47: improve login backend retry handling"
git push
```

## 10. What I learned

এই step থেকে শিখলাম login flow আসলে দুইটা stage: Firebase OTP verification এবং backend JWT login। OTP success হলেও backend timeout হতে পারে। তাই UI-তে retry state রাখা দরকার, যেন user আবার OTP পাঠাতে না গিয়ে backend login retry করতে পারে।
