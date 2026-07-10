# Step 61: Backend Profile Image Storage

## 1. Step title

এই step-এর নাম: **Step 61: Backend Profile Image Storage**।

## 2. কী implement করা হয়েছে

এই step-এ profile image URL input বাদ দিয়ে backend-controlled image upload flow করা হয়েছে।

- Flutter profile screen থেকে gallery image select করা যায়।
- Flutter image bytes multipart form-data হিসেবে backend-এ পাঠায়।
- Spring Boot image validate করে backend-এর configured profile image folder-এ save করে।
- Default folder: `services/backend/src/main/resources/profile-images/`
- PostgreSQL `user_profiles.avatar_image_id` column-এ generated unique image id save হয়।
- Flutter backend URL থেকে image display করে।

## 3. কেন এই step দরকার

আগে profile image হিসেবে external URL রাখা হচ্ছিল। এতে user যেকোনো external link দিতে পারত এবং image app-এর control-এর বাইরে থাকত।

এখন SmartKash MVP-তে image backend-এর control-এ থাকবে:

- image কোথায় আছে backend জানে,
- database-এ শুধু unique reference থাকে,
- external random URL দরকার হয় না,
- future-এ object storage বা CDN এ move করলেও DB reference model একই রাখা যাবে।

## 4. কোন files/folders/classes/config change হয়েছে

- `.env.example`
- `.gitignore`
- `services/backend/src/main/resources/db/migration/V14__add_profile_image_reference.sql`
- `services/backend/src/main/resources/profile-images/.gitkeep`
- `services/backend/src/main/resources/application.yml`
- `services/backend/src/main/java/com/smartkash/security/SecurityConfig.java`
- `services/backend/src/main/java/com/smartkash/security/JwtAuthenticationFilter.java`
- `services/backend/src/main/java/com/smartkash/user/controller/UserController.java`
- `services/backend/src/main/java/com/smartkash/user/entity/UserProfile.java`
- `services/backend/src/main/java/com/smartkash/user/dto/request/UpdateUserProfileRequest.java`
- `services/backend/src/main/java/com/smartkash/user/dto/response/UserProfileResponse.java`
- `services/backend/src/main/java/com/smartkash/user/mapper/UserMapper.java`
- `services/backend/src/main/java/com/smartkash/user/service/UserService.java`
- `services/backend/src/main/java/com/smartkash/user/service/impl/UserServiceImpl.java`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/pubspec.lock`
- `apps/mobile/lib/features/auth/data/backend_auth_repository.dart`
- `apps/mobile/lib/features/auth/domain/auth_session_state.dart`
- `apps/mobile/lib/features/auth/domain/current_user_summary.dart`
- `apps/mobile/lib/features/auth/providers/auth_controller.dart`
- `apps/mobile/lib/features/profile/presentation/profile_completion_screen.dart`
- `docs/backend-api-plan.md`
- `docs/database-plan.md`
- `docs/security-plan.md`
- `docs/test-checklist.md`
- `docs/codex-progress.md`

## 5. Important code snippets

### Flyway migration

```sql
ALTER TABLE user_profiles
    ADD COLUMN avatar_image_id VARCHAR(120);

CREATE UNIQUE INDEX uk_user_profiles_avatar_image_id
    ON user_profiles (avatar_image_id)
    WHERE avatar_image_id IS NOT NULL;
```

### Backend storage config

```yaml
spring:
  servlet:
    multipart:
      max-file-size: 2MB
      max-request-size: 2MB

smartkash:
  profile-images:
    storage-directory: ${PROFILE_IMAGE_STORAGE_DIR:src/main/resources/profile-images}
```

### Backend upload endpoint

```java
@PostMapping("/me/profile-image")
public ResponseEntity<UserResponse> uploadCurrentUserProfileImage(
        @AuthenticationPrincipal JwtPrincipal principal,
        @RequestParam("image") MultipartFile image
) {
    return ResponseEntity.ok(userService.uploadCurrentUserProfileImage(principal, image));
}
```

### Backend image read endpoint

```java
@GetMapping("/profile-images/{imageId}")
public ResponseEntity<Resource> readProfileImage(@PathVariable String imageId) {
    return userService.readProfileImage(imageId);
}
```

### Flutter image picker

```dart
final pickedImage = await _imagePicker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 900,
  imageQuality: 85,
);
```

### Flutter multipart upload

```dart
final response = await _apiClient.post<Map<String, dynamic>>(
  '/api/users/me/profile-image',
  data: FormData.fromMap({
    'image': MultipartFile.fromBytes(
      imageBytes,
      filename: fileName,
    ),
  }),
);
```

## 6. Code/config explanation

### Migration block

`ALTER TABLE user_profiles` existing profile table change করে।

`ADD COLUMN avatar_image_id VARCHAR(120)` profile image file-এর generated id রাখে।

`CREATE UNIQUE INDEX` নিশ্চিত করে একই image id দুই profile-এ accidentally assign না হয়।

`WHERE avatar_image_id IS NOT NULL` মানে image না থাকলে multiple null value allowed থাকবে।

### Storage config

`spring.servlet.multipart.max-file-size` Spring Boot level-এ single uploaded file-এর maximum size 2MB করে।

`spring.servlet.multipart.max-request-size` পুরো multipart request-এর maximum size 2MB করে।

`PROFILE_IMAGE_STORAGE_DIR` দিয়ে local/dev machine-এ folder override করা যায়।

Default value `src/main/resources/profile-images` রাখা হয়েছে কারণ তুমি বলেছ backend resources folder-এর ভিতরে image রাখতে।

Production-level app হলে এই folder external storage/object storage দিয়ে replace করা ভালো।

### Upload endpoint

`@PostMapping("/me/profile-image")` authenticated current user-এর image upload route।

`@AuthenticationPrincipal JwtPrincipal principal` JWT থেকে current user চিনে।

`@RequestParam("image") MultipartFile image` multipart request-এর `image` field থেকে file নেয়।

Controller business logic করে না; service layer-এ পাঠায়।

### Image read endpoint

`/api/users/profile-images/{imageId}` image id দিয়ে file serve করে।

Flutter `NetworkImage` এই URL load করতে পারে, কারণ read endpoint public করা হয়েছে। MVP-তে এটা সহজ display flow; production-এ privacy rule আলাদা করে ভাবতে হবে।

### Flutter picker

`ImagePicker()` gallery থেকে file select করে।

`maxWidth: 900` image dimension কম রাখে।

`imageQuality: 85` quality রাখে কিন্তু file size কমায়।

### Multipart upload

`FormData.fromMap` HTTP multipart body বানায়।

`MultipartFile.fromBytes` selected image bytes backend-এ পাঠায়।

Backend response থেকে updated user profile পাওয়া যায়।

## 7. কেন external URL বাদ দেওয়া হলো

External URL দিলে:

- image unavailable হতে পারে,
- random unsafe link save হতে পারে,
- app image lifecycle control করতে পারে না।

Backend image storage দিলে:

- app নিজেই image control করে,
- DB শুধু reference রাখে,
- Flutter backend URL থেকে image দেখায়।

## 8. SmartKash flow-তে কীভাবে কাজ করে

1. User OTP login করে।
2. PIN setup করে।
3. Profile completion screen-এ full name, email, image select করে।
4. Flutter first profile info save করে।
5. Image selected থাকলে Flutter backend-এ multipart upload করে।
6. Backend image save করে `avatar_image_id` DB-তে রাখে।
7. Flutter Home/Account screen-এ backend-served image দেখায়।

## 9. Common mistakes and cautions

- `services/backend/src/main/resources/application-local.yml` commit করা যাবে না।
- Uploaded actual profile images Git-এ commit করা যাবে না।
- `google-services.json` বা Firebase Admin JSON commit করা যাবে না।
- 2 MB-এর বেশি image দিলে backend reject করবে।
- JPG, PNG, WEBP ছাড়া অন্য file দিলে backend reject করবে।
- Windows-এ `image_picker` plugin dependency use করতে Developer Mode দরকার হতে পারে।
- Production app-এ runtime upload `src/main/resources` folder-এ রাখা ideal নয়; future-এ external storage use করা ভালো।

## 10. Manual verification commands

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

Database:

```sql
\d user_profiles
SELECT id, user_id, full_name, email, avatar_image_id FROM user_profiles ORDER BY id DESC LIMIT 10;
```

File check:

```powershell
dir D:\github\my-kash\services\backend\src\main\resources\profile-images
```

## 11. Expected output

- `user_profiles` table-এ `avatar_image_id` column দেখা যাবে।
- Profile save করার পর `avatar_image_id` null থাকবে না, যদি image choose করা হয়।
- `profile-images` folder-এ generated `.jpg`, `.png`, বা `.webp` file দেখা যাবে।
- Account screen-এ uploaded profile image দেখা যাবে।

## 12. Git commands used

```powershell
git status
git add <step-61-files>
git commit -m "step-61: store profile images in backend resources"
git push
```

## 13. কী শিখলাম

এই step থেকে শিখলাম কীভাবে Flutter image picker দিয়ে image select করে multipart request হিসেবে Spring Boot backend-এ পাঠানো যায়, backend কীভাবে image validate/save করে, এবং PostgreSQL-এ full file path না রেখে generated reference id রাখা যায়।
