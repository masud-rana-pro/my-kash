# Step 46: Backend Env Import Path Hardening

## 1. Step title

এই step-এ backend `.env` import path harden করা হয়েছে, যাতে CLI এবং IDE দুইভাবেই backend Firebase env load করতে পারে।

## 2. What was implemented

- `application.yml`-এ Spring config import list করা হয়েছে।
- `services/backend/.env` root workspace থেকে run করলেও load হওয়ার path যোগ করা হয়েছে।
- Progress doc ও test checklist update করা হয়েছে।

## 3. কেন এই step দরকার ছিল

Spring Boot আগে শুধু এই path import করছিল:

```yaml
optional:file:.env[.properties]
```

এটা তখনই কাজ করে যখন backend run command-এর working directory হয়:

```text
D:\github\my-kash\services\backend
```

কিন্তু IDE অনেক সময় project root থেকে run করে:

```text
D:\github\my-kash
```

তখন `.env` খোঁজা হয় root folder-এ, কিন্তু actual file আছে:

```text
D:\github\my-kash\services\backend\.env
```

তাই root/IDE run mode-এ Firebase Admin env missing হতে পারে।

## 4. Important config snippet

```yaml
spring:
  config:
    import:
      - optional:file:.env[.properties]
      - optional:file:services/backend/.env[.properties]
```

Block-by-block ব্যাখ্যা:

- `spring.config.import`: Spring Boot startup-এর সময় extra config/env file load করে।
- `optional:file:.env[.properties]`: backend folder থেকে run করলে `services/backend/.env` load হবে।
- `optional:file:services/backend/.env[.properties]`: repo root বা IDE থেকে run করলে backend `.env` load হবে।
- `optional`: file না থাকলে app crash করবে না; local setup না থাকলে graceful fallback থাকবে।
- `[.properties]`: `.env` file properties-style key-value হিসেবে parse হবে।

## 5. `.env`-এ কী থাকা দরকার

Backend Firebase Admin-এর জন্য local `.env`-এ এগুলো থাকা দরকার:

```properties
FIREBASE_PROJECT_ID=...
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_PRIVATE_KEY_ID=...
FIREBASE_CLIENT_ID=...
```

Security caution:

- `.env` কখনো GitHub-এ commit করা যাবে না।
- Firebase Admin JSON কখনো GitHub-এ commit করা যাবে না।
- Private key output/log/screenshot-এ share করা উচিত না।

## 6. Backend verification result expected

Backend run করলে log-এ এমন message থাকা ভালো:

```text
Firebase Admin SDK initialized for project ...
Tomcat started on port 8080
```

Health check:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/actuator/health
```

Expected:

```json
{"status":"UP"}
```

Fake token check:

```powershell
$body = @{ firebaseIdToken = 'fake-test-token' } | ConvertTo-Json
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/auth/firebase-login -Method POST -ContentType 'application/json' -Body $body
```

Expected:

```text
401 Invalid Firebase ID token
```

এর মানে backend Firebase Admin configured আছে, কিন্তু fake token accept করছে না। এটা security-wise ঠিক।

## 7. SmartKash flow-এ এটা কীভাবে কাজ করবে

1. Flutter Firebase OTP success হলে Firebase ID token পাবে।
2. Flutter token backend `/api/auth/firebase-login`-এ পাঠাবে।
3. Backend Firebase Admin env load করবে।
4. Backend Firebase Admin SDK দিয়ে token verify করবে।
5. Token valid হলে backend JWT issue করবে।
6. এরপর user/profile/wallet/PIN flow চলবে।

## 8. কী implement করা হয়নি

- Firebase verification bypass করা হয়নি।
- mock login add করা হয়নি।
- `.env` বা service account JSON commit করা হয়নি।
- Flutter UI বা wallet feature change করা হয়নি।

## 9. Common mistakes

- IDE root থেকে run করলে relative `.env` path miss হতে পারে।
- Private key actual multiline দিলে `.env` parse issue হতে পারে; escaped `\n` সহ quoted value ব্যবহার করা safer।
- Backend restart না করলে config change apply হবে না।
- Firebase Console SHA/update করার পর নতুন `google-services.json` app path-এ replace করতে হবে।

## 10. Manual verification commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Health:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/actuator/health
```

Android app:

```powershell
cd /d D:\github\my-kash\apps\mobile
flutter run --dart-define=FIREBASE_ENABLED=true --dart-define=SMARTKASH_API_BASE_URL=http://10.0.2.2:8080
```

## 11. Git commands used

```powershell
git status --short --branch
git add ...
git commit -m "step-46: harden backend env import path"
git push
```

## 12. What I learned

এই step থেকে শিখলাম Spring Boot `.env` import relative path working directory-এর উপর depend করে। তাই CLI এবং IDE run mode দুটো support করতে multiple optional import path রাখা safer।
