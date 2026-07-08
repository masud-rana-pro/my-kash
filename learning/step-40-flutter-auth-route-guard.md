# Step 40: Flutter Auth Route Guard And Logged-In Home State

## 1. Step title

এই ধাপে SmartKash Flutter app-এ auth route guard এবং logged-in Home state যোগ করা হয়েছে।

## 2. কী implement করা হয়েছে

- `GoRouter` এখন Riverpod auth state অনুযায়ী route সিদ্ধান্ত নেয়।
- User authenticated না হলে Home route থেকে Login route-এ redirect হয়।
- Firebase session থাকলে app startup-এ backend JWT sync করার চেষ্টা করে।
- Backend JWT login success হলে Home screen দেখায়।
- Home header-এ backend JWT থেকে phone number এবং role দেখানো হয়।
- Home header-এ logout action যোগ করা হয়েছে।

## 3. কেন এই step দরকার

আগে Home screen সরাসরি open হতো, user login করেছে কি না সেটা route level-এ check করা হতো না। Mobile banking type app-এ protected Home/dashboard screen authentication ছাড়া দেখা উচিত না। তাই Firebase OTP + backend JWT login success হওয়ার পরেই Home দেখানো দরকার।

## 4. কোন files changed হয়েছে

- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/app/smartkash_app.dart`
- `apps/mobile/lib/features/auth/providers/auth_controller.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-40-flutter-auth-route-guard.md`

## 5. Important code snippets

### Riverpod-backed router provider

```dart
final appRouterProvider = Provider<GoRouter>(
  (ref) {
    final refreshListenable = ValueNotifier<int>(0);
    ref.onDispose(refreshListenable.dispose);

    ref.listen(authControllerProvider, (previous, next) {
      refreshListenable.value++;
    });

    return GoRouter(
      initialLocation: HomeScreen.routePath,
      refreshListenable: refreshListenable,
      redirect: (context, state) {
        final authState = ref.read(authControllerProvider);
        final isLoginRoute = state.matchedLocation == LoginScreen.routePath;

        if (authState.isAuthenticated) {
          return isLoginRoute ? HomeScreen.routePath : null;
        }

        return isLoginRoute ? null : LoginScreen.routePath;
      },
      routes: [
        GoRoute(
          path: HomeScreen.routePath,
          name: HomeScreen.routeName,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: LoginScreen.routePath,
          name: LoginScreen.routeName,
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );
  },
);
```

### Block-by-block Bangla explanation

- `Provider<GoRouter>`: Router এখন Riverpod provider, তাই auth state read/listen করতে পারে।
- `ValueNotifier<int>`: GoRouter-কে refresh signal দেওয়ার জন্য lightweight listenable।
- `ref.onDispose(refreshListenable.dispose)`: Router provider dispose হলে notifier memory থেকে clean হবে।
- `ref.listen(authControllerProvider, ...)`: Auth state change হলেই router refresh হবে।
- `initialLocation: HomeScreen.routePath`: App technically Home দিয়ে start করে, কিন্তু guard unauthenticated হলে Login-এ পাঠায়।
- `authState.isAuthenticated`: Backend JWT পাওয়া গেলে true হয়।
- Authenticated user Login route-এ থাকলে Home route-এ redirect হয়।
- Unauthenticated user Home বা অন্য protected route-এ গেলে Login route-এ redirect হয়।

### App startup session restore

```dart
class _SmartKashAppState extends ConsumerState<SmartKashApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).restoreSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SmartKash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
```

### Block-by-block Bangla explanation

- `ConsumerStatefulWidget`: App root widget এখন Riverpod `ref` ব্যবহার করতে পারে।
- `initState`: App start হওয়ার সময় একবার session restore করার জায়গা।
- `Future.microtask`: Widget init শেষ হওয়ার পর controller call করা হয়, যাতে build lifecycle conflict না হয়।
- `restoreSession()`: Firebase current user থাকলে backend JWT sync করার চেষ্টা করে।
- `ref.watch(appRouterProvider)`: Router provider থেকে current router নেয়।
- `MaterialApp.router`: GoRouter দিয়ে app navigation চালায়।

### AuthController restoreSession

```dart
Future<void> restoreSession() async {
  if (!FirebaseConfig.enabled) {
    state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);
    return;
  }

  if (_firebasePhoneAuthService.currentUser == null) {
    state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);
    return;
  }

  await syncBackendSession();
}
```

### Block-by-block Bangla explanation

- `FirebaseConfig.enabled`: Firebase disabled থাকলে restore করা যাবে না, তাই unauthenticated state।
- `currentUser == null`: Firebase user signed in না থাকলে backend JWT sync করার কিছু নেই।
- `syncBackendSession()`: Firebase ID token নিয়ে backend `/api/auth/firebase-login` call করে backend JWT নেয়।
- Backend Firebase Admin env ready না থাকলে এই sync fail করবে, এবং Login screen error দেখাবে।

### Logged-in Home state

```dart
final authState = ref.watch(authControllerProvider);
final backendToken = authState.backendToken;
final accountLabel = backendToken == null || backendToken.phoneNumber.isEmpty
    ? 'SmartKash Account'
    : backendToken.phoneNumber;
final roleLabel = backendToken?.role ?? 'CUSTOMER';
```

### Block-by-block Bangla explanation

- `ref.watch(authControllerProvider)`: Home screen auth state observe করে।
- `backendToken`: Backend JWT response model।
- `phoneNumber`: Login করা account-এর phone number।
- `role`: Backend থেকে পাওয়া role, যেমন `CUSTOMER`, `MERCHANT`, `ADMIN`।
- Phone number missing হলে fallback হিসেবে `SmartKash Account` দেখানো হয়।

## 6. SmartKash app flow-তে কীভাবে কাজ করে

1. User app open করে।
2. Router Home route load করতে চায়।
3. Auth state authenticated না হলে router Login screen দেখায়।
4. User Firebase test OTP দিয়ে login করে।
5. Backend `/api/auth/firebase-login` success হলে backend JWT secure storage-এ save হয়।
6. Auth state `authenticated` হয়।
7. Router refresh হয়ে Home screen দেখায়।
8. Home header phone number এবং role দেখায়।
9. Logout চাপলে Firebase sign out + local backend JWT clear হয়।
10. Router আবার Login screen-এ পাঠায়।

## 7. কেন PIN setup UI এখন করা হয়নি

এই step শুধুমাত্র auth route guard। PIN setup UI আলাদা next step হওয়া উচিত, কারণ PIN setup-এর নিজস্ব screen, validation, backend `POST /api/auth/set-pin`, error handling, and learning explanation লাগবে। এক step-এ route guard + PIN UI করলে scope বড় হয়ে যাবে।

## 8. Common mistakes and cautions

- `GoRouter` global final থাকলে Riverpod auth state listen করা কঠিন হয়।
- Router redirect-এ async API call করা উচিত না; auth state আগে controller-এ update হবে, router শুধু decision নেবে।
- Firebase Admin env ready না থাকলে OTP verify হলেও backend JWT login fail করবে।
- `google-services.json` commit করা যাবে না।
- PIN Flutter app-এ store করা যাবে না।
- Logout করলে Firebase session এবং backend local token দুইটাই clear করতে হবে।

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

General:

```bat
cd /d D:\github\my-kash
git status
```

## 10. Expected output

- App open করলে unauthenticated অবস্থায় Login screen দেখা যাবে।
- Firebase test phone `01575634380` এবং OTP `123456` দিয়ে login try করা যাবে।
- Backend Firebase Admin env ready না থাকলে backend login error দেখা যাবে।
- Backend Firebase Admin env ready থাকলে login success-এর পর Home screen দেখা যাবে।
- Home header-এ phone number এবং `Logged in - CUSTOMER` type text দেখা যাবে।
- Logout icon চাপলে app আবার Login screen-এ ফিরবে।

## 11. Git commands used

```bat
git status --short --branch
git add <step-40-files>
git commit -m "step-40: add Flutter auth route guard"
git push
```

## 12. এই step থেকে কী শিখলাম

এই step-এ শিখলাম Flutter app-এ authentication শুধু button click না; route guard, startup session restore, backend JWT state, and logout flow একসাথে কাজ করতে হয়। Riverpod state change হলে GoRouter refresh করে protected screen control করা যায়।
