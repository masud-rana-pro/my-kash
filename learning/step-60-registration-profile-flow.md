# Step 60: Registration And Profile Flow

## 1. Step title

Step 60-এ SmartKash app-এ registration/profile completion flow এবং Account screen polish করা হয়েছে।

## 2. কী implement করা হয়েছে

- Login screen text `Log in or register` করা হয়েছে।
- Firebase OTP login-এর পর user profile complete কিনা auth state-এ track করা হয়েছে।
- New/minimal user হলে PIN setup-এর পরে profile completion screen দেখানো হয়েছে।
- Profile completion screen-এ full name, email, profile image URL input যোগ করা হয়েছে।
- Account screen যোগ করা হয়েছে।
- Bottom navigation-এর Account item এখন Account screen খুলে।
- Flutter API client `/api/auth/firebase-login` call-এ old backend JWT পাঠায় না।
- Backend JWT filter public auth/health/docs endpoints skip করে।

## 3. কেন এই step দরকার

আগে Firebase OTP login করলে backend minimal user তৈরি করত, কিন্তু user registration/profile completion flow পরিষ্কার ছিল না। এখন user যদি already registered হয় তাহলে login করে Home-এ যাবে, আর নতুন user হলে PIN এবং profile complete করে তারপর Home-এ যাবে।

## 4. কোন files/folders change হয়েছে

- `apps/mobile/lib/features/auth/domain/current_user_summary.dart`
- `apps/mobile/lib/features/auth/domain/auth_session_state.dart`
- `apps/mobile/lib/features/auth/data/backend_auth_repository.dart`
- `apps/mobile/lib/features/auth/providers/auth_controller.dart`
- `apps/mobile/lib/features/auth/presentation/login_screen.dart`
- `apps/mobile/lib/features/auth/presentation/pin_setup_screen.dart`
- `apps/mobile/lib/features/profile/presentation/profile_completion_screen.dart`
- `apps/mobile/lib/features/profile/presentation/account_screen.dart`
- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `apps/mobile/lib/core/network/api_client.dart`
- `services/backend/src/main/java/com/smartkash/security/JwtAuthenticationFilter.java`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-60-registration-profile-flow.md`

## 5. Important code snippets

```dart
bool get needsProfileCompletion =>
    isAuthenticated && !needsPinSetup && profileComplete != true;
```

Block-by-block ব্যাখ্যা:

- `isAuthenticated`: backend JWT session আছে কিনা check করে।
- `!needsPinSetup`: PIN setup আগে শেষ হতে হবে।
- `profileComplete != true`: profile incomplete হলে profile completion screen দরকার।

```dart
Future<CurrentUserSummary> updateProfile({
  required String fullName,
  String? email,
  String? avatarUrl,
}) async {
  final response = await _apiClient.put<Map<String, dynamic>>(
    '/api/users/me/profile',
    data: {
      'fullName': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
    },
  );

  return CurrentUserSummary.fromJson(response.data ?? const {});
}
```

ব্যাখ্যা:

- `PUT /api/users/me/profile`: current authenticated user-এর profile update করে।
- `fullName`: registration/profile completion-এর মূল required field।
- `email`: optional।
- `avatarUrl`: profile image URL; paid image upload storage ব্যবহার করা হয়নি।
- Response আবার `CurrentUserSummary` model-এ convert হয়।

```dart
if (authState.needsProfileCompletion) {
  return isProfileCompletionRoute
      ? null
      : ProfileCompletionScreen.routePath;
}
```

ব্যাখ্যা:

- Router guard authenticated user-এর profile incomplete হলে Home-এ যেতে দেয় না।
- User already profile completion screen-এ থাকলে redirect করে না।
- Profile complete হলে Home route allow হয়।

```dart
if (options.path != '/api/auth/firebase-login') {
  final token = await _tokenStorage.readAccessToken();
  if (token != null && token.isNotEmpty) {
    final tokenType = await _tokenStorage.readTokenType();
    options.headers['Authorization'] = '$tokenType $token';
  }
}
```

ব্যাখ্যা:

- সাধারণ protected API call-এ backend JWT attach হয়।
- কিন্তু Firebase login endpoint public; এখানে stale/expired backend JWT পাঠালে login/register flow block হতে পারে।
- তাই `/api/auth/firebase-login` call-এ old token attach করা হয় না।

```java
@Override
protected boolean shouldNotFilter(HttpServletRequest request) throws ServletException {
    String path = request.getRequestURI();
    return path.equals("/api/auth/firebase-login")
            || path.startsWith("/actuator/")
            || path.startsWith("/v3/api-docs")
            || path.startsWith("/swagger-ui");
}
```

ব্যাখ্যা:

- Backend JWT filter public auth endpoint skip করে।
- Health/docs endpoints-ও skip হয়।
- এতে stale token থাকলেও Firebase login/register endpoint block হয় না।

## 6. SmartKash flow-তে কীভাবে কাজ করে

Existing user:

1. App open করবে।
2. OTP দিয়ে login করবে।
3. Backend JWT sync হবে।
4. PIN set এবং profile complete থাকলে Home যাবে।

New/minimal user:

1. App open করবে।
2. OTP দিয়ে login/register করবে।
3. Backend minimal user তৈরি করবে।
4. PIN setup screen দেখাবে।
5. Profile completion screen দেখাবে।
6. Full name/profile info save করলে Home যাবে।

## 7. Profile image কীভাবে কাজ করে

MVP zero-budget হওয়ায় image upload storage যোগ করা হয়নি। User profile image URL দিতে পারবে। URL খালি থাকলে app name-এর প্রথম অক্ষর দিয়ে fallback avatar দেখাবে।

## 8. Common mistakes and cautions

- Firebase login endpoint-এ stale backend JWT পাঠানো যাবে না।
- Profile image upload করতে paid storage/service যোগ করা যাবে না।
- Raw PIN Flutter app-এ store করা যাবে না।
- Profile complete না হলে user Home-এ যাওয়ার আগে registration/profile screen দেখবে।
- `application-local.yml`, `.env`, Firebase Admin JSON commit করা যাবে না।

## 9. Manual verification commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Flutter:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter pub get
flutter analyze
flutter run --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

Database check:

```sql
SELECT id, mobile_number, pin_hash IS NOT NULL AS pin_set FROM users ORDER BY id DESC LIMIT 10;
SELECT user_id, full_name, email, avatar_url FROM user_profiles ORDER BY id DESC LIMIT 10;
```

Expected output:

- Existing complete user login করলে Home খুলবে।
- New/minimal user login করলে PIN setup তারপর profile completion আসবে।
- Profile save করলে Home খুলবে।
- Account tab চাপলে profile/account details দেখা যাবে।
- Profile image URL দিলে avatar image দেখা যাবে, না দিলে initial fallback দেখা যাবে।

## 10. Git commands used

```powershell
git status --short --branch
dart format <step-60-dart-files>
git diff --check
git add <step-60-files>
git commit -m "step-60: add registration profile flow"
git push
```

## 11. কী শিখলাম

Registration শুধু OTP login না। Minimal backend user তৈরি হওয়ার পরে PIN setup, profile completion, route guard, account display, এবং stale-token-safe login flow একসাথে কাজ করলেই user app-এর Home screen-এ নিরাপদে যেতে পারে।
