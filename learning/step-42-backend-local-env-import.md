# Step 42: Backend Local Env Import

## 1. Step title

এই ধাপে Spring Boot backend-এ local `.env` file import support যোগ করা হয়েছে।

## 2. কী implement করা হয়েছে

- `services/backend/src/main/resources/application.yml` update করা হয়েছে।
- Spring Boot এখন backend working directory থেকে optional `.env` file read করতে পারে।
- `services/backend/.env` Git ignore থাকে, তাই secret commit হয় না।
- Firebase Admin env values backend runtime-এ পাওয়া যাবে।

## 3. কেন এই step দরকার

Spring Boot defaultভাবে `.env` file নিজে read করে না। User `services/backend/.env` file তৈরি করলেও backend যদি সেটা import না করে, তাহলে `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` application properties-এ যাবে না। এর ফলে Firebase Admin SDK initialize হবে না এবং real Firebase ID token verify করা যাবে না।

## 4. Files changed

- `services/backend/src/main/resources/application.yml`
- `docs/codex-progress.md`
- `docs/test-checklist.md`
- `learning/step-42-backend-local-env-import.md`

## 5. Important config snippet

```yaml
spring:
  config:
    import: optional:file:.env[.properties]
  application:
    name: smartkash-backend
```

## 6. Block-by-block Bangla explanation

- `spring.config.import`: Spring Boot-কে extra config source load করতে বলে।
- `optional:`: `.env` না থাকলেও app crash করবে না।
- `file:.env`: backend run করার current working directory থেকে `.env` file খুঁজবে।
- `[.properties]`: `.env` extension না থাকলেও Spring এটাকে properties format হিসেবে parse করবে।
- `application.name`: আগের app name config unchanged আছে।

## 7. কীভাবে SmartKash flow-তে connect করে

1. User Firebase Phone Auth test OTP দিয়ে Firebase ID token নেয়।
2. Flutter token backend `/api/auth/firebase-login` API-তে পাঠায়।
3. Backend Firebase Admin SDK দিয়ে token verify করে।
4. Firebase Admin credentials `.env` থেকে আসে।
5. Token valid হলে backend user/wallet create or find করে JWT দেয়।

## 8. Security cautions

- `.env` commit করা যাবে না।
- Firebase service account JSON commit করা যাবে না।
- Backend log-এ private key print করা যাবে না।
- `.env.example` শুধু placeholder রাখবে।
- Real production secret later proper secret manager/environment variables দিয়ে দিতে হবে।

## 9. Manual verification commands

Backend:

```bat
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd spring-boot:run
```

Health:

```bat
Invoke-WebRequest -UseBasicParsing http://localhost:8080/actuator/health
```

Expected backend log:

```text
Firebase Admin SDK initialized for project <project-id>.
```

Git check:

```bat
cd /d D:\github\my-kash
git status
```

## 10. Expected output

- Backend starts successfully.
- PostgreSQL/Flyway still works.
- Firebase Admin SDK initializes if `.env` values are valid.
- `.env` remains ignored and unstaged.

## 11. Git commands used

```bat
git status --short --branch
git add services/backend/src/main/resources/application.yml docs/codex-progress.md docs/test-checklist.md learning/step-42-backend-local-env-import.md
git commit -m "step-42: load backend env file"
git push
```

## 12. কী শিখলাম

এই step-এ শিখলাম local development secret `.env` file থেকে app config load করা যায়, কিন্তু file নিজে Git-এ commit করা যাবে না। এতে Firebase Admin setup local machine-এ কাজ করবে কিন্তু secret repository-তে যাবে না।

## 13. Step 42 verification update

এই step-এ Firebase Admin initialize করার সময় দুইটি practical issue পাওয়া গেছে এবং fix করা হয়েছে:

1. Google service account JSON parser `private_key_id` এবং `client_id` field expect করে।
2. `.env` থেকে আসা `FIREBASE_PRIVATE_KEY` value quote/newline format-এর কারণে `Invalid PKCS#8 data` error দিতে পারে।

Fix হিসেবে:

- `FirebaseAdminProperties` এখন optional `privateKeyId` এবং `clientId` bind করতে পারে।
- `FirebaseAdminInitializer` generated service account JSON-এ `private_key_id`, `client_id`, এবং `auth_uri` রাখে।
- `normalizedPrivateKey()` surrounding quote remove করে এবং escaped `\n` real newline-এ convert করে।
- `.env.example`-এ optional `FIREBASE_PRIVATE_KEY_ID` এবং `FIREBASE_CLIENT_ID` placeholder যোগ করা হয়েছে।

Important snippet:

```java
public String normalizedPrivateKey() {
    if (privateKey == null) {
        return "";
    }

    String normalized = privateKey.trim();
    if (normalized.length() >= 2 && normalized.startsWith("\"") && normalized.endsWith("\"")) {
        normalized = normalized.substring(1, normalized.length() - 1);
    }

    return normalized.replace("\\n", "\n").trim();
}
```

Manual verification result:

```text
Firebase Admin SDK initialized for project <project-id>.
Tomcat started on port 8080.
Actuator health returned {"status":"UP"}.
Fake Firebase token returned 401 Invalid Firebase ID token.
```

এর মানে backend Firebase Admin এখন configure হয়েছে এবং fake token reject করছে, তাই real Firebase token verification active আছে।
