# Step 09: User Profile Completion Foundation

## 1. Step title

Step 09 - Authenticated user profile completion/update foundation.

## 2. কী implement করা হয়েছে

এই step-এ SmartKash backend-এ minimal profile update foundation যোগ করা হয়েছে:

- `PUT /api/users/me/profile` endpoint যোগ করা হয়েছে।
- authenticated backend JWT principal থেকে current user resolve করা হয়েছে।
- `user_profiles` table-এ profile না থাকলে create করা হয়।
- profile থাকলে update করা হয়।
- request DTO-তে validation যোগ করা হয়েছে।
- response entity নয়, DTO হিসেবে return করা হয়েছে।
- service layer-এ transaction ব্যবহার করা হয়েছে।

এই step-এ wallet, PIN, ledger, transaction, add money, send money, payment, savings, loan, recharge, admin profile management, KYC/NID, বা money-changing feature যোগ করা হয়নি।

## 3. কেন profile completion দরকার

Firebase login user-এর phone authentication করে এবং Step 08 backend `users` table-এ minimal account তৈরি করে। কিন্তু app-এর profile screen-এর জন্য `fullName`, `email`, `avatarUrl` দরকার হতে পারে। তাই separate `user_profiles` row create/update করার foundation দরকার।

Profile data `users` table-এ না রেখে `user_profiles` table-এ রাখলে identity আর optional profile details আলাদা থাকে।

## 4. কেন authenticated Firebase UID/JWT principal ব্যবহার করা হয়েছে

Profile update করার সময় backend request body থেকে user ID নেয় না। Instead:

1. User backend JWT পাঠায়।
2. Spring Security JWT parse করে `JwtPrincipal` বানায়।
3. `JwtPrincipal.firebaseUid()` দিয়ে database user খুঁজে।
4. সেই user-এর profile create/update হয়।

এতে এক user অন্য user-এর profile update করতে পারে না।

## 5. কেন request body থেকে user ID নেওয়া হয়নি

যদি request body-তে `userId` নেওয়া হতো, malicious user অন্য user ID পাঠিয়ে অন্য account update করার চেষ্টা করতে পারত। তাই request DTO-তে শুধু profile fields রাখা হয়েছে:

- `fullName`
- `email`
- `avatarUrl`

Ownership backend JWT থেকে resolve হয়।

## 6. কোন files/folders create বা change হয়েছে

- `services/backend/src/main/java/com/smartkash/user/dto/request/UpdateUserProfileRequest.java`
- `services/backend/src/main/java/com/smartkash/user/controller/UserController.java`
- `services/backend/src/main/java/com/smartkash/user/service/UserService.java`
- `services/backend/src/main/java/com/smartkash/user/service/impl/UserServiceImpl.java`
- `services/backend/src/main/java/com/smartkash/user/entity/UserProfile.java`
- `services/backend/src/main/java/com/smartkash/user/mapper/UserMapper.java`
- `docs/backend-api-plan.md`
- `docs/security-plan.md`
- `docs/codex-progress.md`
- `learning/step-09-user-profile-completion-foundation.md`

## 7. Important code/config snippets

### Request DTO

```java
public record UpdateUserProfileRequest(
        @Size(max = 120, message = "Full name must be at most 120 characters.")
        String fullName,

        @Email(message = "Email must be valid.")
        @Size(max = 160, message = "Email must be at most 160 characters.")
        String email,

        @Size(max = 500, message = "Avatar URL must be at most 500 characters.")
        String avatarUrl
) {
}
```

Line-by-line Bangla ব্যাখ্যা:

- `record` immutable request DTO বানায়।
- `fullName` optional, কিন্তু দিলে 120 character-এর বেশি হতে পারবে না।
- `@Email` email থাকলে valid email format enforce করে।
- `email` optional, কিন্তু দিলে 160 character-এর বেশি হতে পারবে না।
- `avatarUrl` optional, কিন্তু দিলে 500 character-এর বেশি হতে পারবে না।
- এখানে `userId` নেই, কারণ user identity JWT থেকে আসে।

### Controller endpoint

```java
@PutMapping("/me/profile")
public ResponseEntity<UserResponse> updateCurrentUserProfile(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody UpdateUserProfileRequest request
) {
    return ResponseEntity.ok(userService.updateCurrentUserProfile(principal, request));
}
```

Block-by-block Bangla ব্যাখ্যা:

- `@PutMapping("/me/profile")` endpoint path হলো `PUT /api/users/me/profile`।
- `@AuthenticationPrincipal JwtPrincipal principal` authenticated JWT user নেয়।
- `@Valid` request DTO validation চালায়।
- `@RequestBody` JSON body থেকে DTO বানায়।
- Controller নিজে business logic করে না; service method call করে।
- Response হিসেবে `UserResponse` DTO return হয়।

### Service interface

```java
UserResponse updateCurrentUserProfile(JwtPrincipal principal, UpdateUserProfileRequest request);
```

ব্যাখ্যা:

- Service interface-এ profile update contract রাখা হয়েছে।
- Controller concrete implementation জানে না; interface call করে।
- Layered architecture clean থাকে।

### Service create/update logic

```java
@Transactional
public UserResponse updateCurrentUserProfile(JwtPrincipal principal, UpdateUserProfileRequest request) {
    User user = findCurrentUser(principal);
    UserProfile profile = userProfileRepository.findByUserId(user.getId())
            .orElseGet(() -> new UserProfile(user, null, null, null));

    profile.update(request.fullName(), request.email(), request.avatarUrl());
    UserProfile savedProfile = userProfileRepository.save(profile);

    return userMapper.toResponse(user, savedProfile);
}
```

Line-by-line Bangla ব্যাখ্যা:

- `@Transactional` পুরো create/update operation একই database transaction-এ রাখে।
- `findCurrentUser(principal)` JWT Firebase UID দিয়ে current user খুঁজে।
- `findByUserId(user.getId())` existing profile খুঁজে।
- profile না থাকলে `new UserProfile(...)` দিয়ে নতুন profile object বানায়।
- `profile.update(...)` request data entity-তে set করে।
- `userProfileRepository.save(profile)` new হলে insert, existing হলে update করে।
- `userMapper.toResponse(user, savedProfile)` entity সরাসরি return না করে DTO বানায়।

### Current user lookup

```java
private User findCurrentUser(JwtPrincipal principal) {
    return userRepository.findByFirebaseUid(principal.firebaseUid())
            .orElseThrow(() -> new ResourceNotFoundException("User profile is not created yet."));
}
```

ব্যাখ্যা:

- request body থেকে user ID নেওয়া হয়নি।
- JWT principal-এর Firebase UID দিয়ে database user খোঁজা হয়েছে।
- user না থাকলে 404-style `ResourceNotFoundException` throw হয়।

### UserProfile update method

```java
public void update(String fullName, String email, String avatarUrl) {
    this.fullName = fullName;
    this.email = email;
    this.avatarUrl = avatarUrl;
}
```

ব্যাখ্যা:

- Entity update করার logic এক জায়গায় রাখা হয়েছে।
- Future-এ profile rules বাড়লে এই method-এ রাখা যাবে।
- Controller বা mapper entity field manually set করে না।

### Mapper change

```java
public UserResponse toResponse(User user, UserProfile profile) {
    return new UserResponse(
            user.getId(),
            user.getFirebaseUid(),
            user.getMobileNumber(),
            user.getRole(),
            user.getStatus(),
            toProfileResponse(profile),
            user.getCreatedAt(),
            user.getUpdatedAt()
    );
}
```

Block-by-block Bangla ব্যাখ্যা:

- `User` entity থেকে user identity fields নেওয়া হয়।
- `UserProfile` entity থেকে profile response বানানো হয়।
- Entity directly API response হিসেবে return করা হয়নি।
- update-এর পর newly saved profile response-এ আসবে, even if `user.getProfile()` lazy relation এখনো refresh না হয়।

## 8. Repository usage

এই step-এ existing repositories use করা হয়েছে:

```java
userRepository.findByFirebaseUid(principal.firebaseUid())
userProfileRepository.findByUserId(user.getId())
userProfileRepository.save(profile)
```

ব্যাখ্যা:

- `UserRepository` current authenticated user খুঁজে।
- `UserProfileRepository` profile row খুঁজে।
- `save` profile create/update করে।
- Repository শুধু database access করে; business logic service layer-এ থাকে।

## 9. কেন wallet/PIN/business features implement করা হয়নি

Profile update money-changing feature নয়। Wallet/PIN/ledger আলাদা security-sensitive step:

- PIN needs hashing and rate limit.
- Wallet needs ledger and transaction safety.
- Money APIs need idempotency and audit logs.

তাই এই step ছোট রাখা হয়েছে।

## 10. SmartKash auth/user flow-তে এটি কীভাবে fit করে

1. User Firebase test OTP দিয়ে login করে।
2. Backend Firebase token verify করে।
3. Backend `users` table-এ user create/find করে।
4. Backend JWT issue করে।
5. User JWT দিয়ে `PUT /api/users/me/profile` call করে।
6. Backend JWT Firebase UID দিয়ে user খুঁজে।
7. Backend user-এর নিজের profile create/update করে।

## 11. Common mistakes and cautions

- Request body-তে `userId` নেওয়া যাবে না।
- Entity directly response করা যাবে না।
- Validation ছাড়া email/avatar/fullName নেওয়া উচিত নয়।
- Profile update-এ wallet/PIN/role/status change করা যাবে না।
- Local `application-local.yml` commit করা যাবে না।
- Profile table already আছে, তাই নতুন Flyway migration দরকার হয়নি।
- Admin profile management এই step-এর scope না।

## 12. Manual verification commands

Backend:

```cmd
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
```

Optional runtime check:

```cmd
.\mvnw.cmd spring-boot:run
```

Database check:

```cmd
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
SELECT * FROM users;
SELECT * FROM user_profiles;
```

General:

```cmd
cd /d D:\github\my-kash
git status
```

## 13. Git commands used

```cmd
git status --short --branch
git diff --check
git add <step-09-files>
git commit -m "step-09: add user profile completion foundation"
git push
```

## 14. এই step থেকে কী শিখলাম

এই step-এ শিখলাম authenticated user profile update করার সময় request body থেকে user ID নেওয়া নিরাপদ নয়। Backend JWT/Firebase UID দিয়ে current user resolve করলে profile ownership safe থাকে। DTO validation, service transaction, repository access, mapper response - এগুলো আলাদা রাখলে backend clean এবং maintainable হয়।
