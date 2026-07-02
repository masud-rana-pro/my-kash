# Step 08: Firebase Login User Persistence

## 1. Step title

Step 08 - Firebase login-ke persisted `users` table-er sathe link kora.

## 2. কী implement করা হয়েছে

এই step-এ `POST /api/auth/firebase-login` flow update করা হয়েছে:

- Firebase ID token verify করার পর backend এখন `users` table-এ user খুঁজে।
- `firebase_uid` দিয়ে existing user পাওয়া গেলে সেটি use করে।
- existing user না থাকলে Firebase phone number দিয়ে নতুন minimal user row create করে।
- নতুন user default `CUSTOMER` role এবং `ACTIVE` status পায়।
- Backend JWT এখন hardcoded temporary role থেকে নয়, persisted user record-এর role থেকে তৈরি হয়।
- Firebase token-এ phone number না থাকলে login reject করা হয়।
- একই mobile number অন্য Firebase UID-এর সাথে linked থাকলে login reject করা হয়।

এই step-এ wallet, PIN, ledger, transaction, admin management, profile editing, বা money-changing API implement করা হয়নি।

## 3. কেন এই step দরকার

Step 06-এ backend Firebase token verify করে JWT issue করত, কিন্তু user database record তৈরি করত না। Step 07-এ `users` table তৈরি হয়েছে। এখন auth flow-কে database-এর সাথে connect করা দরকার, যাতে SmartKash backend জানে কোন Firebase user কোন persisted SmartKash user account।

এই connection ছাড়া পরে wallet, profile, role, status, merchant, admin access safely implement করা যাবে না।

## 4. Firebase ID token আর persisted user record-এর পার্থক্য

- Firebase ID token প্রমাণ করে user phone auth pass করেছে।
- Persisted `users` row SmartKash app-এর business identity।
- Firebase UID auth identity হিসেবে থাকে।
- `users.role` এবং `users.status` app authorization/business state হিসেবে থাকে।

## 5. কোন files change হয়েছে

- `services/backend/src/main/java/com/smartkash/auth/service/impl/AuthServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/common/exception/AuthException.java`
- `services/backend/src/main/java/com/smartkash/user/repository/UserRepository.java`
- `docs/backend-api-plan.md`
- `docs/security-plan.md`
- `docs/codex-progress.md`
- `learning/step-08-firebase-login-user-persistence.md`

## 6. Important code snippets

### AuthServiceImpl dependency update

```java
private final FirebaseTokenVerifier firebaseTokenVerifier;
private final JwtService jwtService;
private final UserRepository userRepository;
```

Block-by-block Bangla ব্যাখ্যা:

- `FirebaseTokenVerifier` Firebase ID token valid কি না check করে।
- `JwtService` SmartKash backend JWT generate করে।
- `UserRepository` PostgreSQL `users` table থেকে user খুঁজে বা save করে।

```java
public AuthServiceImpl(
        FirebaseTokenVerifier firebaseTokenVerifier,
        JwtService jwtService,
        UserRepository userRepository
) {
    this.firebaseTokenVerifier = firebaseTokenVerifier;
    this.jwtService = jwtService;
    this.userRepository = userRepository;
}
```

ব্যাখ্যা:

- Constructor injection ব্যবহার করা হয়েছে।
- Spring Boot নিজে dependency inject করবে।
- Auth service এখন Firebase, JWT, এবং persisted user table - তিনটি জিনিস coordinate করে।

### Login method

```java
@Override
@Transactional
public AuthTokenResponse loginWithFirebase(FirebaseLoginRequest request) {
    FirebaseToken firebaseToken = verifyFirebaseToken(request.firebaseIdToken());
    String phoneNumber = phoneNumber(firebaseToken);
    User user = findOrCreateUser(firebaseToken.getUid(), phoneNumber);
    String role = user.getRole().name();
    JwtToken jwtToken = jwtService.generateToken(user.getFirebaseUid(), user.getMobileNumber(), role);
}
```

Line-by-line Bangla ব্যাখ্যা:

- `@Override` বোঝায় method টি `AuthService` interface থেকে implement করা হয়েছে।
- `@Transactional` database read/create operation এক transaction-এর মধ্যে রাখে।
- `verifyFirebaseToken(...)` Firebase ID token verify করে।
- `phoneNumber(firebaseToken)` verified Firebase token থেকে phone number নেয়।
- `findOrCreateUser(...)` database-এ user খুঁজে, না থাকলে create করে।
- `user.getRole().name()` persisted role string করে নেয়, যেমন `CUSTOMER`।
- `jwtService.generateToken(...)` persisted user data দিয়ে backend JWT বানায়।

### Find or create user

```java
private User findOrCreateUser(String firebaseUid, String phoneNumber) {
    return userRepository.findByFirebaseUid(firebaseUid)
            .orElseGet(() -> createUser(firebaseUid, phoneNumber));
}
```

ব্যাখ্যা:

- প্রথমে Firebase UID দিয়ে user খোঁজা হয়।
- user থাকলে সেটিই return হয়।
- user না থাকলে `createUser` call করে নতুন minimal user তৈরি হয়।

### Create user

```java
private User createUser(String firebaseUid, String phoneNumber) {
    userRepository.findByMobileNumber(phoneNumber)
            .ifPresent(existingUser -> {
                throw new AuthException("Mobile number is already linked to another account.");
            });

    User user = new User(firebaseUid, phoneNumber, UserRole.CUSTOMER, UserStatus.ACTIVE);
    return userRepository.save(user);
}
```

Block-by-block Bangla ব্যাখ্যা:

- `findByMobileNumber(phoneNumber)` দেখে একই phone number আগে কোনো user-এর সাথে linked কি না।
- থাকলে `AuthException` throw করা হয়, কারণ একই mobile number দিয়ে দুই account safe নয়।
- নতুন `User` তৈরি হয় Firebase UID, phone number, `CUSTOMER`, `ACTIVE` দিয়ে।
- `userRepository.save(user)` user row PostgreSQL database-এ insert করে।

### Phone number validation

```java
private String phoneNumber(FirebaseToken firebaseToken) {
    Object phoneNumber = firebaseToken.getClaims().get(PHONE_NUMBER_CLAIM);
    if (phoneNumber == null || phoneNumber.toString().isBlank()) {
        throw new AuthException("Firebase phone number is required.");
    }

    return phoneNumber.toString();
}
```

ব্যাখ্যা:

- Firebase token claim থেকে phone number নেওয়া হয়।
- phone number না থাকলে login reject করা হয়।
- SmartKash MVP phone-auth based, তাই phone number ছাড়া user তৈরি করা ঠিক নয়।

### Repository update

```java
Optional<User> findByFirebaseUid(String firebaseUid);
Optional<User> findByMobileNumber(String mobileNumber);
```

ব্যাখ্যা:

- `findByFirebaseUid` login user link করার main lookup।
- `findByMobileNumber` duplicate mobile number prevent করে।
- `Optional<User>` ব্যবহার করা হয়েছে কারণ user থাকতে পারে, নাও থাকতে পারে।

### AuthException update

```java
public AuthException(String message) {
    super(message);
}
```

ব্যাখ্যা:

- আগে `AuthException` cause সহ message নিত।
- এখন simple validation/auth error-এর জন্য শুধু message দিয়েও exception throw করা যায়।

## 7. JWT role এখন কোথা থেকে আসে

আগে role ছিল temporary hardcoded `CUSTOMER`। এখন:

```java
String role = user.getRole().name();
```

ব্যাখ্যা:

- role database-এর persisted `users.role` থেকে আসে।
- পরে admin/merchant role update করা হলে JWT সেই persisted role reflect করতে পারবে।
- MVP Phase 1-এ complex permission system যোগ করা হয়নি।

## 8. কেন wallet/PIN/business feature implement করা হয়নি

এই step শুধু auth-to-user persistence link। Wallet create করলে ledger, idempotency, transaction, locking, audit log লাগবে। PIN setup করলে hashing/rate-limit/temporary block লাগবে। তাই সেগুলো dedicated future step-এ করা হবে।

## 9. SmartKash flow-তে এটি কীভাবে কাজ করে

1. Flutter Firebase test OTP দিয়ে user authenticate করে।
2. Flutter Firebase ID token backend-এ পাঠায়।
3. Backend Firebase token verify করে।
4. Backend Firebase UID দিয়ে `users` table-এ user খোঁজে।
5. user না থাকলে phone number দিয়ে new `CUSTOMER ACTIVE` user তৈরি করে।
6. Backend persisted user data দিয়ে JWT issue করে।
7. Flutter future API call-এ এই JWT ব্যবহার করবে।

## 10. Common mistakes and cautions

- Firebase token verify না করে user create করা যাবে না।
- Phone number missing থাকলে user create করা উচিত নয়।
- একই mobile number অন্য Firebase UID-এর সাথে link করা যাবে না।
- JWT role hardcoded রাখলে future admin/merchant role কাজ করবে না।
- এই step-এ wallet auto-create করা যাবে না, কারণ wallet needs separate ledger-safe design।
- `application-local.yml`-এর local password fallback commit করা যাবে না।
- Firebase Admin service account JSON repo-তে commit করা যাবে না।

## 11. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Database check:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
SELECT id, firebase_uid, mobile_number, role, status, created_at FROM users;
```

Optional API run check:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

এই API manually test করতে real Firebase Admin environment values এবং valid Firebase ID token লাগবে।

General:

```cmd
cd /d D:\github\my-kash
git status
git remote -v
```

## 12. Git commands used

```cmd
git status --short --branch
git remote -v
git remote set-url origin https://github.com/masud-rana-pro/mobile-banking-app.git
git add <step-08-files>
git commit -m "step-08: link Firebase login to users"
git push
```

## 13. এই step থেকে কী শিখলাম

এই step-এ শিখলাম Firebase authentication আর application database identity আলাদা জিনিস। Firebase user verify করে, কিন্তু SmartKash backend-এর business role/status PostgreSQL `users` table থেকে আসা উচিত। Auth service-এর কাজ হলো verified Firebase identity-কে persisted SmartKash user record-এর সাথে safely link করা, তারপর backend JWT issue করা।
