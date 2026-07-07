# Step 36: Flutter Auth Flow Foundation

## 1. Step title

এই ধাপের নাম: Flutter Auth Flow Foundation.

## 2. What was implemented

এই ধাপে Flutter app-এ auth flow-এর non-visual foundation তৈরি করা হয়েছে।

যা যোগ করা হয়েছে:

- `AuthSessionStatus` enum
- `AuthSessionState` state class
- `AuthController`
- `authControllerProvider`
- Firebase sign-out method
- Firebase current user থেকে backend JWT sync করার foundation

এই ধাপে login screen, OTP screen, wallet screen, route guard, PIN UI, বা visual design করা হয়নি।

## 3. Why this step is needed

SmartKash auth flow দুই অংশে কাজ করে:

1. Firebase Phone Auth user-এর phone verify করে।
2. Spring Boot backend Firebase ID token verify করে backend JWT দেয়।

Flutter UI সরাসরি Firebase/Dio/secure storage handle করলে code messy হবে। তাই controller layer দরকার, যাতে future UI শুধু state watch করে এবং action call করে।

## 4. Files changed

Changed files:

- `apps/mobile/lib/features/auth/data/firebase_phone_auth_service.dart`
- `apps/mobile/lib/features/auth/domain/auth_session_status.dart`
- `apps/mobile/lib/features/auth/domain/auth_session_state.dart`
- `apps/mobile/lib/features/auth/providers/auth_controller.dart`
- `apps/mobile/lib/features/auth/providers/auth_providers.dart`
- `docs/architecture-plan.md`
- `docs/test-checklist.md`
- `docs/codex-progress.md`
- `learning/step-36-flutter-auth-flow-foundation.md`

## 5. Important code snippet: AuthSessionStatus

```dart
enum AuthSessionStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  failure,
}
```

ব্যাখ্যা:

- `initial`: app start হয়েছে, auth state এখনো decide করা হয়নি।
- `unauthenticated`: user login করা নেই।
- `authenticating`: backend login sync চলছে।
- `authenticated`: backend JWT পাওয়া গেছে।
- `failure`: auth sync fail করেছে।

## 6. Important code snippet: AuthSessionState

```dart
class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.backendToken,
    this.errorMessage,
  });

  final AuthSessionStatus status;
  final BackendAuthToken? backendToken;
  final String? errorMessage;
}
```

Block-by-block ব্যাখ্যা:

- `status` current auth state বোঝায়।
- `backendToken` authenticated হলে backend JWT metadata রাখে।
- `errorMessage` failure হলে error text রাখে।
- `BackendAuthToken?` nullable, কারণ unauthenticated অবস্থায় token থাকে না।

```dart
bool get isAuthenticated => status == AuthSessionStatus.authenticated;
bool get isLoading => status == AuthSessionStatus.authenticating;
```

ব্যাখ্যা:

- UI later `isAuthenticated` দিয়ে route বা screen decide করতে পারবে।
- `isLoading` দিয়ে loading indicator দেখানো যাবে।

## 7. Important code snippet: syncBackendSession

```dart
Future<void> syncBackendSession({bool forceRefresh = false}) async {
  state = state.copyWith(
    status: AuthSessionStatus.authenticating,
    clearError: true,
  );

  try {
    final firebaseIdToken = await _firebasePhoneAuthService.currentIdToken(
      forceRefresh: forceRefresh,
    );
```

ব্যাখ্যা:

- method শুরু হলে state `authenticating` করা হয়।
- `clearError: true` পুরোনো error clear করে।
- Firebase current user থেকে ID token নেওয়া হয়।
- `forceRefresh` true হলে Firebase token refresh করতে পারে।

```dart
if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
  state = state.copyWith(
    status: AuthSessionStatus.unauthenticated,
    clearBackendToken: true,
    errorMessage: 'Firebase user is not signed in.',
  );
  return;
}
```

ব্যাখ্যা:

- Firebase user না থাকলে backend login করা যাবে না।
- state `unauthenticated` করা হয়।
- backend token state থেকে clear করা হয়।
- function এখানেই থেমে যায়।

```dart
final backendToken = await _backendAuthRepository.loginWithFirebaseIdToken(
  firebaseIdToken,
);

state = AuthSessionState(
  status: AuthSessionStatus.authenticated,
  backendToken: backendToken,
);
```

ব্যাখ্যা:

- Firebase ID token backend login API-তে পাঠানো হয়।
- backend valid হলে backend JWT দেয়।
- repository backend JWT secure storage-এ save করে।
- state `authenticated` হয়।

## 8. Important code snippet: signOut

```dart
Future<void> signOut() async {
  await _firebasePhoneAuthService.signOut();
  await _backendAuthRepository.signOutLocally();
  state = const AuthSessionState(
    status: AuthSessionStatus.unauthenticated,
  );
}
```

ব্যাখ্যা:

- প্রথমে Firebase session sign out হয়।
- তারপর backend JWT secure storage থেকে clear হয়।
- শেষে local state unauthenticated হয়।
- এতে future API request আর old token attach করবে না।

## 9. Riverpod provider snippet

```dart
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthSessionState>(
  (ref) => AuthController(
    firebasePhoneAuthService: ref.watch(firebasePhoneAuthServiceProvider),
    backendAuthRepository: ref.watch(backendAuthRepositoryProvider),
  ),
);
```

ব্যাখ্যা:

- `StateNotifierProvider` stateful controller expose করে।
- UI later `ref.watch(authControllerProvider)` দিয়ে state পড়বে।
- UI later `ref.read(authControllerProvider.notifier)` দিয়ে action call করবে।
- controller Firebase service এবং backend repository dependency পায়।

## 10. How this connects to SmartKash app flow

Future auth flow হবে:

1. User phone number দিয়ে Firebase test OTP login করবে।
2. Firebase user তৈরি/sign-in হবে।
3. UI `syncBackendSession()` call করবে।
4. Controller Firebase ID token নেবে।
5. Backend auth repository Spring Boot `/api/auth/firebase-login` call করবে।
6. Backend JWT secure storage-এ save হবে।
7. Auth state `authenticated` হবে।
8. Future wallet/home screens authenticated API call করতে পারবে।

## 11. Why no UI was added

User আগে বলেছেন UI design করার আগে sample image দেবেন। তাই এই step-এ কোনো login screen বা visual layout তৈরি করা হয়নি।

এই step শুধু logic foundation:

- state
- controller
- provider
- sync action
- sign-out action

## 12. Why PIN is not stored

এই step auth session নিয়ে কাজ করে, transaction PIN নিয়ে নয়।

PIN সম্পর্কে rule:

- Flutter PIN store করবে না।
- PIN শুধুমাত্র money-changing confirmation request-এ backend-এ যাবে।
- backend PIN verify করবে।

এই step-এ PIN model, PIN storage, PIN screen, PIN cache কিছুই নেই।

## 13. Common mistakes and cautions

- Firebase user signed in না থাকলে backend JWT sync হবে না।
- Backend request body field হতে হবে `firebaseIdToken`।
- JWT save হয় repository layer-এ; UI layer token manually handle করবে না।
- Sign-out করলে Firebase এবং backend token দুটোই clear করতে হবে।
- Auth state আর UI design এক জিনিস না; এই step state foundation মাত্র।
- Sample images ছাড়া visual login screen বানানো শুরু করা যাবে না।

## 14. Manual verification commands

Flutter:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter test
```

Run Android emulator:

```powershell
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Run Web:

```powershell
flutter run -d chrome --dart-define=SMARTKASH_API_BASE_URL=http://localhost:8080
```

Expected output:

- `flutter analyze`: no compile/analyzer errors
- `flutter test`: tests pass if default test exists
- app still opens existing placeholder screen
- no login UI appears yet
- no PIN storage is added

## 15. Git commands used

```powershell
git status --short --branch
dart format <changed auth files>
git diff --check
git add <step-36-files>
git commit -m "step-36: add Flutter auth flow foundation"
git push
git status --short --branch
```

## 16. What I learned from this step

এই step থেকে শিখলাম:

- Firebase login আর backend JWT login আলাদা layer।
- Controller UI থেকে business/auth orchestration আলাদা রাখে।
- Riverpod state future UI screen-কে clean রাখবে।
- Sign-out করার সময় Firebase session এবং backend JWT দুটোই clear করা দরকার।
- UI design শুরু করার আগে logic foundation তৈরি করলে পরে screen বানানো সহজ হয়।
